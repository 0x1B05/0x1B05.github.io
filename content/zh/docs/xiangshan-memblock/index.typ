#import "../index.typ": template, tufted, content-card, locale-url, series-begin, doc-toc
#import "./series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/", title: "香山 MemBlock")

#let series = xiangshan-memblock-series

#let chapter-thumbnail(chapter) = if chapter.order == 1 {
  "research-log.svg"
} else if chapter.order == 2 {
  "reading-notes.svg"
} else if chapter.order == 3 {
  "prototype-notebook.svg"
} else if chapter.order == 4 {
  "workflow-guide.svg"
} else if chapter.order == 5 {
  "deployment-notes.svg"
} else if chapter.order == 6 {
  "sandbox-project.svg"
} else {
  "starter-series.svg"
}

= 香山 MemBlock 解读：从访存总图到高风险路径

#doc-toc("zh")

这是我读香山 MemBlock 时整理的笔记。不逐行翻 `MemBlock.scala`，先把几个容易迷路的点摆清楚：MemBlock 在协调什么、先看哪些接口、哪些控制交互容易出问题。

每章会带一点 review 视角，但主线是读懂结构。先把地图立住再看实现，不然很容易在端口和控制信号里散掉。

== 建议阅读方式

第一次读建议按顺序来：访存总图、后端接口、Load/Store/LSQ、MMU 与权限检查、cacheable 与 uncacheable 路径、向量访存，最后是 review checklist。

== 包含章节

#html.div(class: "content-grid")[
  #for chapter in series.chapters [
    #content-card(
      locale-url("zh", route: chapter.route),
      chapter-thumbnail(chapter),
      chapter.title,
      chapter.summary,
      label: "第 " + str(chapter.order) + " 章",
    )
  ]
]

#series-begin("zh", series.begin-route)
