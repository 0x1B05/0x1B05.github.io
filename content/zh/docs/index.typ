#import "../index.typ": (
  content-card, doc-toc, definition, example, locale-url, margin-note, note,
  series-begin, series-context, series-navbar, sidenote, table-title, template,
  tip, warning,
)
#import "./registry.typ": series-registry, note-registry
#show: template.with(locale: "zh", route: "docs/", title: "文档")

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
