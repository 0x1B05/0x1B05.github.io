# AGENTS.md

## Project Overview

This repository is the personal website `0x1B05.github.io` — a bilingual (English / Chinese) static site with notes, docs, blog posts, and a CV, published at `https://0x1B05.github.io/`.

The site is written in **Typst** and compiled to static HTML with `typst compile --features html --format html`. There is no traditional application runtime: the "source code" is Typst markup plus a small set of hand-written CSS/JS assets, and the build output (`_site/`) is deployed directly to GitHub Pages. Because this is a GitHub *user-site* repository, the site lives at the domain root — all internal URLs are written absolute against `/`, never against a project subpath.

### Requirements

- `typst >= 0.15.0` (CI pins `0.15.0`)
- `make`
- `node` + `npm` (only for Pagefind search indexing; the single npm dependency is `pagefind` in `package.json`)
- `python3` (only for the local preview server)

## Repository Layout

- `config.typ` — the shared site shell. Exports `site-web`/`template` (the page template that emits `<html>`, header/nav, search box, language switcher, theme switcher, footer), URL helpers (`site-url`, `locale-url`, `normalize-route`), localized copy tables (`locale-copy`), and reusable components (callouts like `note`/`tip`/`warning`, `doc-toc`, `content-card`, series navigation helpers `series-context`/`series-navbar`/`series-begin`). Shared shell changes usually belong here or in `assets/tufted.css`.
- `content/` — all pages, mirrored per locale: `content/en/…` and `content/zh/…` are parallel trees, plus the language-gateway landing page `content/index.typ`. Every page is an `index.typ` inside a directory; page-local images live in an `imgs/` subdirectory next to it.
- `assets/` — CSS and JS copied verbatim to `_site/assets/`:
  - `tufted.css` — the main stylesheet (theme tokens, layout, component styles).
  - `custom.css` — an intentionally (near-)empty override hook layered after `tufted.css`; put site-specific tweaks here rather than editing generated output.
  - `theme-bootstrap.js` — runs in `<head>` before first paint to apply the stored/system theme.
  - `theme-switcher.js`, `language-switcher.js`, `language-redirect.js` — header controls and root-gateway redirect; preferences are persisted in `localStorage` under keys like `tufted-theme`.
  - `search.js` — client-side search UI backed by the Pagefind index at `/pagefind/`.
  - Logos (`logo-light.svg`, `logo-dark.svg`), `profile.png`, `content-thumbnails/`.
- `Makefile` — the entire build pipeline (see below).
- `tests/` — plain Node test scripts (no test framework) plus `tests/helpers/` fixtures.
- `.github/workflows/deploy.yml` — CI/CD to GitHub Pages.
- `_site/` — generated build output; never edit by hand. `.deps/` (typst-generated Make depfiles), `node_modules/`, `.reference/`, and `plans/` are also local-only and gitignored.

### Content model

- Pages apply the shell with `#show: template.with(locale: "en" | "zh", route: "<path>/", title: "…")`. Routes are directory-style and must end with a trailing slash.
- Doc **series** are declared in a `series.typ` inside the series directory (id, title, summary, route, thumbnail, ordered `chapters` list). `content/<locale>/docs/registry.typ` aggregates all `series.typ` files plus standalone reference notes into `series-registry`/`note-registry` for the docs landing page.
- Files the Makefile excludes from page compilation (they are imports/metadata, not pages): `series.typ`, `registry.typ`, and any file under a path component starting with `_` (`content/**/_*.typ` are shared Typst includes whose changes trigger rebuilds of dependent pages).
- English and Chinese trees must stay structurally mirrored; the header language switcher navigates to the *same route* in the opposite locale.

## Build and Test Commands

Install JS dependencies once (provides `./node_modules/.bin/pagefind`):

```sh
npm install
```

Build the full site into `_site/` (compiles every page, copies `assets/`, builds the Pagefind search index):

```sh
make html
```

Preview locally at `http://localhost:8000` (override with `make preview PORT=9000`):

```sh
make preview
```

Clean build for GitHub Pages (also creates `_site/.nojekyll`):

```sh
make pages        # alias: make github-pages
```

Clean generated output:

```sh
make clean
```

### How the Makefile works

- `TYP_FILES` are found with `find content -name '*.typ'` minus the metadata files above; each `content/<path>.typ` maps to `_site/<path>.html` via `typst compile --root .. --features html --format html`.
- Rebuild dependencies are exact, not convention-based: each page compiles with `typst compile --deps .deps/<path>.d --deps-format make`, which records every file the compilation actually reads (`config.typ`, imports, `series.typ`, images, bibliographies, package files) as a Make rule; the Makefile then `-include`s those `.d` files. Missing `.d` files on a fresh build are expected (compiling generates them); if a stale `.d` ever references a deleted file, run `make clean`.
- The `search-index` target runs Pagefind with `--force-language en` into `_site/pagefind/` and fails with a clear message if `node_modules/.bin/pagefind` is missing.

## Code Style and Conventions

- Typst: use the `html.*` element API (`html.div`, `html.elem("svg", attrs: …)`, etc.) for markup; keep localized strings out of content files — extend the `locale-copy` table in `config.typ` instead. Helper names use kebab-case (`series-navbar`, `content-card`); CSS classes use BEM-ish names (`theme-switcher__option--dark`).
- JavaScript: plain ES5-compatible IIFEs, no imports/build step, `const`-heavy, defensive `try/catch` around `localStorage` and `matchMedia`. `theme-bootstrap.js` must stay dependency-free and synchronous because it runs before first paint.
- Content directories and file slugs are kebab-case; blog post directories are named by topic slug (no date prefix).
- Keep prose and comments in the same bilingual spirit as the rest of the repo: shell/config code and docs are English; page content exists in both `en` and `zh`.

## Deployment

`.github/workflows/deploy.yml` runs on every push to `main` (and manually): checkout → Node 24 → `npm ci` → Typst `0.15.0` via `typst-community/setup-typst` → `make pages` → upload `_site/` as a Pages artifact → deploy to GitHub Pages. There is no separate deploy command to run locally; `make pages` reproduces exactly what CI builds.

## Security Considerations

- No secrets or credentials are stored in the repo; the only npm dependency is Pagefind, pinned via `package-lock.json` and installed with `npm ci` in CI.
- Generated HTML embeds no third-party runtime JS; the only external reference is the Tufte CSS stylesheet loaded from cdnjs in the default `css` list of `site-web` (config.typ).
- Never edit `_site/` directly and never commit it (gitignored); treat `node_modules/`, `.reference/`, and `plans/` as local-only.
