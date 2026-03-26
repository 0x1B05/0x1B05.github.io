#import "../../../config.typ": series-context as shared-series-context, series-navbar as shared-series-navbar, series-begin as shared-series-begin
#import "../index.typ": template, tufted, content-card, locale-url
#import "./series.typ": series-registry, reference-registry
#show: template.with(locale: "zh", route: "docs/", title: "文档")

#let series-context = shared-series-context
#let series-navbar = shared-series-navbar
#let series-begin = shared-series-begin

#let docs-card(entry, label: none) = content-card(
  locale-url("zh", route: entry.route),
  entry.thumbnail,
  entry.title,
  entry.summary,
  label: label,
)

= 文档

这一部分解释双语模板是如何组织起来的，以及你最可能最先修改哪些文件。它更像站点操作手册，而不是简单的链接列表。

== 系列

#html.div(class: "content-grid")[
  #for entry in series-registry [
    #docs-card(entry, label: "教程")
  ]
]

== 参考

#html.div(class: "content-grid")[
  #for entry in reference-registry [
    #docs-card(entry, label: entry.label)
  ]
]
