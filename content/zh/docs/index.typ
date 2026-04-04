#import "../../../config.typ": series-context as shared-series-context, series-navbar as shared-series-navbar, series-begin as shared-series-begin
#import "../index.typ": template, tufted, content-card, locale-url
#import "./registry.typ": series-registry, note-registry
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

这一部分放更结构化的内容：更完整的系列、较短的工作短文，以及我会反复回看的检查清单。我希望它既能承载 Linux bring-up 这类系统问题，也能承载像香山 MemBlock 这样的读码路径，而不是把每个话题都写成一篇很长的 blog。

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
