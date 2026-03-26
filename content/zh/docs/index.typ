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

这一部分放更结构化的内容：体系结构学习路径、软件栈参考，以及我在做 Linux bring-up 时反复回看的检查清单。我希望它更像一组可以复查的笔记，而不是把每个话题都写成一篇很长的 blog。

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
