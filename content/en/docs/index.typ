#import "../../../config.typ": series-context as shared-series-context, series-navbar as shared-series-navbar, series-begin as shared-series-begin
#import "../index.typ": template, tufted, content-card, locale-url
#import "./series.typ": series-registry, reference-registry
#show: template.with(locale: "en", route: "docs/", title: "Docs")

#let series-context = shared-series-context
#let series-navbar = shared-series-navbar
#let series-begin = shared-series-begin

#let docs-card(entry, label: none) = content-card(
  locale-url("en", route: entry.route),
  entry.thumbnail,
  entry.title,
  entry.summary,
  label: label,
)

= Docs

This section explains how the bilingual template is put together and which files you are most likely to edit first. Treat it as the operating manual for your site rather than a bare list of links.

== Series

#html.div(class: "content-grid")[
  #for entry in series-registry [
    #docs-card(entry, label: "Tutorial")
  ]
]

== Reference

#html.div(class: "content-grid")[
  #for entry in reference-registry [
    #docs-card(entry, label: entry.label)
  ]
]
