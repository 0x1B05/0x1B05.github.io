#import "../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": series-registry
#show: template.with(locale: "en", route: "docs/01-quick-start/", title: "Quick Start")

#let series = series-registry.at(0)
#let nav = series-context(series, "docs/01-quick-start/")

= Quick Start

#series-navbar("en", nav)

== Installation

To initialize a new project from the template, run the following commands:

```sh
typst init @preview/tufted:0.1.1 my-website
cd my-website
```

== Building

The template includes a `Makefile` that compiles every `index.typ` page in the bilingual content tree:

```sh
make html
```

This writes the generated pages to `_site/`, including the language gateway at `/` and the mirrored `/en/` and `/zh/` sections.

== Previewing Locally

For day-to-day editing, use the built-in preview target:

```sh
make preview
```

By default the preview server listens on port `8000`. If you need a different port, run `make preview PORT=9000`.

== Publishing Build

When you are preparing a GitHub Pages artifact, run:

```sh
make pages
```

That command rebuilds the HTML output and writes `_site/.nojekyll` so the generated folder is ready to upload.

#series-navbar("en", nav)
