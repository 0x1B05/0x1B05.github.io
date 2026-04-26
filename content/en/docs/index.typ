#import "../../../config.typ": series-context as shared-series-context, series-navbar as shared-series-navbar, series-begin as shared-series-begin
#import "../index.typ": template, tufted, content-card, locale-url
#import "./registry.typ": series-registry, note-registry
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

This section keeps the more structured side of my notes: series, shorter working notes, and checklists I expect to revisit while debugging. Right now it is mostly Linux bring-up, XiangShan MemBlock code reading, and architecture paper notes.

== Series

#html.div(class: "content-grid")[
  #for entry in series-registry [
    #docs-card(entry, label: "Series")
  ]
]

== Short Notes

#html.div(class: "content-grid")[
  #for entry in note-registry [
    #docs-card(entry, label: entry.label)
  ]
]
