#import "../../../config.typ": series-context as shared-series-context, series-navbar as shared-series-navbar, series-begin as shared-series-begin, doc-toc as shared-doc-toc, note as shared-note, tip as shared-tip, example as shared-example, definition as shared-definition, warning as shared-warning
#import "../index.typ": template, tufted, content-card, locale-url
#import "./registry.typ": series-registry, note-registry
#show: template.with(locale: "zh", route: "docs/", title: "文档")

#let series-context = shared-series-context
#let series-navbar = shared-series-navbar
#let series-begin = shared-series-begin
#let doc-toc = shared-doc-toc
#let note(body, title: auto) = shared-note(body, title: title, locale: "zh")
#let tip(body, title: auto) = shared-tip(body, title: title, locale: "zh")
#let example(body, title: auto) = shared-example(body, title: title, locale: "zh")
#let definition(body, title: auto) = shared-definition(body, title: title, locale: "zh")
#let warning(body, title: auto) = shared-warning(body, title: title, locale: "zh")

#let docs-card(entry, label: none) = content-card(
  locale-url("zh", route: entry.route),
  entry.thumbnail,
  entry.title,
  entry.summary,
  label: label,
)

= 文档

// TODO: 一句话介绍这个栏目。下面的系列和短文由 docs/registry.typ 渲染。

== 系列

#html.div(class: "content-grid")[
  #for entry in series-registry [
    #docs-card(entry, label: "系列")
  ]
]

== 短文

#html.div(class: "content-grid")[
  #for entry in note-registry [
    #docs-card(entry, label: entry.label)
  ]
]
