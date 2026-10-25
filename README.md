# 0x1B05.github.io

Personal bilingual site for notes, blog posts, and profile pages, built with Typst and exported as static HTML.

Production URL: `https://0x1B05.github.io/`

## Requirements

- `typst >= 0.15.0`
- `make`
- `node`
- `npm`
- `python3` for local preview

## Local Development

Install JavaScript dependencies first:

```sh
npm install
```

Build the site:

```sh
make html
```

Preview the generated output locally:

```sh
make preview
```

The preview server listens on `http://localhost:8000` by default. To use a different port:

```sh
make preview PORT=9000
```

For an incremental preview of one page, with live reload while you edit:

```sh
make watch PAGE=zh/blog/qwen3-0.6b-execution-flow
```

`PAGE` is a route relative to `content/`, without the trailing `/index.typ`.
With no `PAGE`, `make watch` opens an `fzf` picker; if fzf is unavailable or
cancelled, it reuses the last page, which is remembered in the gitignored
`.preview-page`.

`make watch` runs `typst watch` for that page only and serves the result together
with the existing `_site` build. `/assets/` is read from the repository, so CSS
and JavaScript changes appear on the next reload. Run `make html` once first if
you need the other routes and the Pagefind index to exist. The watch preview does
not rebuild the search index.

## Deployment

Build the GitHub Pages artifact locally:

```sh
make pages
```

This writes the final output to `_site/` and creates `_site/.nojekyll`.

Deployment is automated by [`.github/workflows/deploy.yml`](./.github/workflows/deploy.yml). Every push to `main` rebuilds the site and publishes `_site/` to GitHub Pages.

Because this repository is the user-site repository `0x1B05.github.io`, the site is deployed at the root domain and paths are written against `/`, not a project subpath.

## Repository Layout

- `content/`
  Bilingual site content under `content/en/` and `content/zh/`
- `assets/`
  Shared CSS, JavaScript, logos, profile image, and thumbnail assets
- `config.typ`
  Shared site shell, routing helpers, localized copy, and reusable content helpers
- `Makefile`
  Build, preview, and Pages-oriented targets
- `scripts/preview.py`
  Single-page incremental preview server (`make watch`) with live reload

## Maintenance Notes

- Add or edit pages under `content/en/` and `content/zh/`.
- Shared shell behavior usually belongs in `config.typ` or `assets/site.css`.
- This site intentionally targets the root user-site domain, so paths and search assets are written against `/`.
