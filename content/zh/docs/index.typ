#import "../../../config.typ": series-context as shared-series-context, series-navbar as shared-series-navbar, series-begin as shared-series-begin, doc-toc as shared-doc-toc
#import "../index.typ": template, tufted, content-card, locale-url
#import "./registry.typ": series-registry, note-registry
#show: template.with(locale: "zh", route: "docs/", title: "文档")

#let series-context = shared-series-context
#let series-navbar = shared-series-navbar
#let series-begin = shared-series-begin
#let doc-toc = shared-doc-toc

#let docs-card(entry, label: none) = content-card(
  locale-url("zh", route: entry.route),
  entry.thumbnail,
  entry.title,
  entry.summary,
  label: label,
)

= 文档

这一部分放更成体系的内容：系列文章、短一点的工作笔记，以及以后调试时还会回来翻的清单。现在主要是 Linux bring-up、香山 MemBlock 读码，以及一些体系结构论文阅读。

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
