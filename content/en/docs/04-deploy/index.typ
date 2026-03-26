#import "../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": series-registry
#show: template.with(locale: "en", route: "docs/04-deploy/", title: "Deployment")

#let series = series-registry.at(0)
#let nav = series-context(series, "docs/04-deploy/")

= Deployment

#series-navbar("en", nav)

You can deploy the generated bilingual site to GitHub Pages with a small workflow and the built-in Make targets.

== Local Preview

Before you publish, use:

```sh
make preview
```

That rebuilds the HTML output and serves `_site/` through Python's HTTP server so you can inspect `/`, `/en/`, and `/zh/` locally.

== Publishing Build

When you need a GitHub Pages artifact, run:

```sh
make pages
```

This rebuilds the static site into `_site/` and writes `_site/.nojekyll`, so the directory is ready for Pages publishing.

Before you deploy:

1. If the repository itself is your Pages domain, leave `site-root = ""` in `config.typ`.
2. If you are publishing a project site, set `site-root` in `config.typ` to `"/your-repository-name"` before running `make pages`.

== GitHub Actions

Create `.github/workflows/deploy.yml` with the following workflow:

```yaml
name: Deploy

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: typst-community/setup-typst@v4
      - run: make pages
      - uses: actions/configure-pages@v4
      - uses: actions/upload-pages-artifact@v4
        with:
          path: _site

  deploy:
    runs-on: ubuntu-latest
    needs: build
    permissions:
      pages: write
      id-token: write
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/deploy-pages@v4
        id: deployment
```

== Enable GitHub Pages

1. Open your repository on GitHub.
2. Go to _Settings_ → _Pages_.
3. Under _Build and deployment_, choose _GitHub Actions_ as the source.

After that, every push to `main` can rebuild and publish the `_site/` directory.

#series-navbar("en", nav)
