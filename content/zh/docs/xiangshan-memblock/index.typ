#import "../index.typ": template, tufted, content-card, locale-url, series-begin
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

这个系列是把我读香山 MemBlock 的笔记重新整理成一条可复查的路径。它的目标不是对着 `MemBlock.scala` 逐行做中文注释，而是先保留一张真正有用的地图：MemBlock 在协调什么、哪些边界应该先看、哪些高风险控制交互会反复出现。

所以它会站在两种写法中间。它不是纯入门导读，因为每一章都会带着 review 问题往下读；它也不是未经整理的读码摘抄，因为每一章都试图把一堆观察收束成一个稳定的阅读抓手。

== 建议阅读方式

第一次读建议按顺序来。顺序会先建立访存总图，再进入后端接口、Load/Store/LSQ、MMU 与权限检查、cacheable 与 uncacheable 路径、向量访存，最后落到一份可以直接拿来做 review 的检查框架。

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
