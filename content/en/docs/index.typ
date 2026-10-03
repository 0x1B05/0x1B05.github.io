#import "../index.typ": (
  content-card, doc-toc, definition, example, locale-url, margin-note, note,
  series-begin, series-context, series-navbar, sidenote, table-pair, template,
  tip, warning,
)
#import "./registry.typ": series-registry, note-registry
#show: template.with(locale: "en", route: "docs/", title: "Docs")

#let docs-card(entry, label: none) = content-card(
  locale-url("en", route: entry.route),
  entry.thumbnail,
  entry.title,
  entry.summary,
  label: label,
)

= Docs

// TODO: one-sentence intro for this section. Series and short notes below are
// rendered from docs/registry.typ.

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
