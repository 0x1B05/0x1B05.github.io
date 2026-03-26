#import "../index.typ": template, tufted
#import "@preview/cmarker:0.1.8"
#import "@preview/mitex:0.2.6": mitex
#show: template.with(locale: "en", route: "docs/embedding-markdown/", title: "Embedding Markdown")

= Embedding Markdown

You can embed Markdown content within your Typst documents using `cmarker`. This is useful when you want to preserve an existing Markdown article while still rendering it inside your bilingual Typst site.

```typst
#import "@preview/cmarker:0.1.8"
#import "@preview/mitex:0.2.6": mitex

#let md-content = read("tufted-titmouse.md")

#let def-dict = (
  image: (source, alt: none, format: auto) => figure(image(
    source,
    alt: alt,
    format: format,
  )),
)

#cmarker.render(md-content, math: mitex, scope: def-dict)
```

The content below is rendered from a Markdown file stored beside this page:

#let md-content = read("tufted-titmouse.md")

#let def-dict = (
  image: (source, alt: none, format: auto) => figure(image(
    source,
    alt: alt,
    format: format,
  )),
)

#cmarker.render(md-content, math: mitex, scope: def-dict)
