#!/usr/bin/env python3
"""Incremental single-page preview with live reload.

Runs `typst watch --no-serve` for one page, serves `_site`, and injects a tiny
SSE client into HTML responses. `/assets/` is read straight from the repository,
so CSS/JS edits are visible on the next reload.

PAGE is a route relative to content/, without /index.typ:

  scripts/preview.py zh/blog/qwen3-0.6b-execution-flow

Without PAGE, fzf picks a page, and the choice is remembered in `.preview-page`.
Other routes come from the last `make html`; Pagefind is not rebuilt.
"""

import argparse
import http.server
import mimetypes
import queue
import shutil
import subprocess
import threading
import time
import urllib.parse
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
SITE = ROOT / "_site"
ASSETS = ROOT / "assets"
DEPS = ROOT / ".deps"
LAST_PAGE = ROOT / ".preview-page"

RELOAD_SCRIPT = b"""<script data-preview-reload>
(function () {
  var source = new EventSource("/__events");
  source.addEventListener("reload", function () { location.reload(); });
})();
</script>"""

mimetypes.add_type("font/woff2", ".woff2")
mimetypes.add_type("font/woff", ".woff")
mimetypes.add_type("text/javascript", ".js")
mimetypes.add_type("image/svg+xml", ".svg")


class ReloadHub:
    def __init__(self):
        self._clients = set()
        self._lock = threading.Lock()
        self._version = 0

    def subscribe(self):
        client = queue.Queue()
        with self._lock:
            self._clients.add(client)
        return client

    def unsubscribe(self, client):
        with self._lock:
            self._clients.discard(client)

    def broadcast(self):
        with self._lock:
            self._version += 1
            clients = list(self._clients)
        for client in clients:
            client.put_nowait(self._version)


class PreviewServer(http.server.ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True


class PreviewHandler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):
        pass

    def do_GET(self):
        self.respond(head=False)

    def do_HEAD(self):
        self.respond(head=True)

    def respond(self, head):
        path = urllib.parse.urlsplit(self.path).path
        if path == "/__events":
            self.events(head)
            return

        target = self.lookup(path)
        if target is None:
            self.text(
                404, f"Not found: {path}\nRun `make html` for other routes.\n", head
            )
        else:
            self.file(target, head)

    def lookup(self, path):
        path = urllib.parse.unquote(path)
        base = ASSETS if path.startswith("/assets/") else SITE
        relative = path[len("/assets/") :] if base is ASSETS else path.lstrip("/")

        target = (base / relative).resolve()
        if not target.is_relative_to(base.resolve()):
            return None
        if target.is_dir():
            target /= "index.html"
        return target if target.is_file() else None

    def file(self, path, head):
        data = path.read_bytes()
        if path.suffix == ".html":
            data = data.replace(b"</body>", RELOAD_SCRIPT + b"</body>", 1)

        content_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        if content_type.startswith("text/") or content_type in (
            "application/javascript",
            "application/json",
            "image/svg+xml",
        ):
            content_type += "; charset=utf-8"

        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if not head:
            self.wfile.write(data)

    def text(self, code, message, head):
        data = message.encode()
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if not head:
            self.wfile.write(data)

    def events(self, head):
        if head:
            self.text(405, "GET only\n", head)
            return

        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "keep-alive")
        self.send_header("Transfer-Encoding", "chunked")
        self.end_headers()

        client = self.server.hub.subscribe()
        try:
            self.chunk(b"retry: 500\n\n")
            while True:
                try:
                    version = client.get(timeout=15)
                except queue.Empty:
                    self.chunk(b": keepalive\n\n")
                else:
                    self.chunk(f"event: reload\ndata: {version}\n\n".encode())
        except OSError:
            pass
        finally:
            self.server.hub.unsubscribe(client)
            self.close_connection = True

    def chunk(self, data):
        self.wfile.write(f"{len(data):X}\r\n".encode() + data + b"\r\n")
        self.wfile.flush()


def all_pages():
    return sorted(CONTENT.rglob("index.typ"))


def resolve_route(route):
    route = route.strip("/")
    page = (CONTENT / route / "index.typ").resolve()
    if not page.is_relative_to(CONTENT.resolve()) or not page.is_file():
        raise ValueError(f"no page at {route!r}")
    return page


def load_last_page():
    if LAST_PAGE.exists():
        return LAST_PAGE.read_text().strip() or None
    return None


def save_last_page(page):
    LAST_PAGE.write_text(f"{page.relative_to(ROOT)}\n")


def pick_page(query=None):
    if not shutil.which("fzf"):
        return None

    lines = "\n".join(str(page.relative_to(ROOT)) for page in all_pages())
    command = [
        "fzf",
        "--prompt=preview> ",
        "--height=40%",
        "--preview=head -n 40 {}",
        "--preview-window=right,60%,border-left",
    ]
    if query:
        command.append(f"--query={query}")

    result = subprocess.run(
        command, input=lines, text=True, capture_output=True, cwd=ROOT
    )
    if result.returncode != 0 or not result.stdout.strip():
        return None
    return ROOT / result.stdout.strip()


def choose_page(args):
    if args.page:
        return resolve_route(args.page)

    last = load_last_page()
    if not args.no_pick:
        picked = pick_page(last)
        if picked:
            return picked

    if last:
        path = ROOT / last
        if path.is_file():
            return path
    print_usage()
    raise SystemExit(1)


def print_usage():
    print("usage: make watch [PAGE=<route>] [PORT=8000]")
    print()
    print(
        "PAGE is a route relative to content/, e.g. zh/blog/qwen3-0.6b-execution-flow."
    )
    print("With no PAGE, fzf picks a page; otherwise the last page is reused.")


def page_paths(page):
    relative = page.relative_to(CONTENT)
    if relative.name != "index.typ":
        raise ValueError
    if relative.parent == Path("."):
        return "", SITE / "index.html", DEPS / "index.d"
    return (
        f"{relative.parent.as_posix()}/",
        SITE / relative.parent / "index.html",
        DEPS / relative.parent / "index.d",
    )


def start_typst(page, output, deps):
    if not shutil.which("typst"):
        raise SystemExit("typst not found on PATH")

    output.parent.mkdir(parents=True, exist_ok=True)
    deps.parent.mkdir(parents=True, exist_ok=True)
    output.unlink(missing_ok=True)

    process = subprocess.Popen(
        [
            "typst",
            "watch",
            "--no-serve",
            "--root",
            "..",
            "--features",
            "html",
            "--format",
            "html",
            "--deps",
            str(deps),
            "--deps-format",
            "make",
            str(page),
            str(output),
        ],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    def pump():
        for line in process.stdout:
            print(f"[typst] {line.rstrip()}", flush=True)

    threading.Thread(target=pump, daemon=True).start()
    return process


def wait_for_output(process, output, timeout=20):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if output.exists() and output.stat().st_size:
            time.sleep(0.2)
            return True
        if process.poll() is not None:
            return False
        time.sleep(0.1)
    return False


def snapshot(output):
    assets = tuple(
        (str(path.relative_to(ASSETS)), path.stat().st_mtime_ns)
        for path in ASSETS.rglob("*")
        if path.is_file()
    )
    return output.stat().st_mtime_ns, assets


def watch_loop(hub, output):
    last = None
    while True:
        try:
            current = snapshot(output)
        except OSError:
            time.sleep(0.2)
            continue
        if last is not None and current != last:
            hub.broadcast()
            print("[preview] change detected, reloading", flush=True)
        last = current
        time.sleep(0.2)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Incremental Typst HTML preview with live reload."
    )
    parser.add_argument("page", nargs="?", help="route relative to content/")
    parser.add_argument(
        "--port", type=int, default=8000, help="HTTP port (default: 8000)"
    )
    parser.add_argument(
        "--host", default="127.0.0.1", help="bind address (default: 127.0.0.1)"
    )
    parser.add_argument(
        "--no-pick",
        action="store_true",
        help="do not open fzf when PAGE is omitted",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    try:
        page = choose_page(args)
    except ValueError as exc:
        raise SystemExit(f"error: {exc}") from None

    try:
        route, output, deps = page_paths(page)
    except ValueError:
        raise SystemExit(f"not a content page: {page}") from None

    save_last_page(page)
    print(f"[preview] page:   {page.relative_to(ROOT)}")
    print(f"[preview] output: {output.relative_to(ROOT)}")
    print("[preview] starting typst watch...", flush=True)

    process = start_typst(page, output, deps)
    if not wait_for_output(process, output):
        print("[preview] no output yet; waiting for a successful compile", flush=True)

    try:
        server = PreviewServer((args.host, args.port), PreviewHandler)
    except OSError as exc:
        process.terminate()
        raise SystemExit(f"cannot listen on {args.host}:{args.port}: {exc}") from None
    server.hub = ReloadHub()
    server.route = route
    threading.Thread(target=watch_loop, args=(server.hub, output), daemon=True).start()

    print(f"[preview] serving http://{args.host}:{args.port}/{route}")
    print(
        "[preview] watching assets/ and the compiled page; Ctrl+C to stop", flush=True
    )

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        process.terminate()
        process.wait()
    print("\n[preview] stopped")


if __name__ == "__main__":
    main()
