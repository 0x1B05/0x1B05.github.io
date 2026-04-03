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

This section keeps the more structured side of my notes: longer reading paths, shorter working notes, and the bring-up checklists I expect to revisit. I want it to stay useful as a place to revisit the privilege model, firmware handoff, and simulator roles without turning every topic into a long blog post.

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
