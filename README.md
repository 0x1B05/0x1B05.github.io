# 0x1B05.github.io

Personal bilingual site for notes, blog posts, and profile pages, built with Typst and exported as static HTML.

Production URL: `https://0x1B05.github.io/`

## Requirements

- `typst`
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
- `tests/`
  Regression checks for generated shell behavior, build rules, and theme scripts

## Maintenance Notes

- Add or edit pages under `content/en/` and `content/zh/`.
- Shared shell behavior usually belongs in `config.typ` or `assets/tufted.css`.
- `assets/custom.css` is an intentional override hook for future site-specific tweaks that should layer on top of `assets/tufted.css`.
- This site intentionally targets the root user-site domain, so paths and search assets are written against `/`.
