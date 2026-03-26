# 0x1B05.github.io

Personal bilingual blog and notes site for `0x1B05`, built with Typst and exported as static HTML.

## Site

- Production: `https://0x1B05.github.io/`
- Repository name: `0x1B05.github.io`

## Local Preview

Build and serve the generated site locally:

```sh
make preview
```

The preview server listens on `http://localhost:8000` by default. To change the port:

```sh
make preview PORT=9000
```

## Build

Generate the static HTML output:

```sh
make html
```

The build output is written to `_site/`.

## Deploy To GitHub Pages

Prepare the Pages artifact locally:

```sh
make pages
```

This rebuilds the site and writes `_site/.nojekyll`.

The repository also includes a GitHub Actions workflow at `.github/workflows/deploy.yml` that publishes the site automatically on every push to `main`.

## Project Structure

- `content/`: bilingual site content
- `assets/`: shared images, scripts, and styles
- `config.typ`: shared site shell, routing, and localized labels
- `Makefile`: build, preview, and Pages deployment commands
- `tests/`: regression checks for generated HTML and shell behavior

## Notes

- This site is configured for the root Pages URL `https://0x1B05.github.io/`, so `site-root` stays empty in `config.typ`.
- If you ever move the site into a project repository instead of the root user site, update `site-root` before deploying.
