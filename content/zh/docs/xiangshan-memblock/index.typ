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

这个系列是我读香山 MemBlock 时整理出来的一条复查路径。它不会对着 `MemBlock.scala` 逐行翻译，而是先把几个最容易迷路的点摆出来：MemBlock 在协调什么、哪些接口先看、哪些控制交互值得多留意。

每一章都会带一点 review 视角，但还是以读懂结构为主。先把图和路径抓住，再去看具体实现，不然很容易在端口和控制信号里散掉。

== 建议阅读方式

第一次读建议按顺序来：先看访存总图，再看后端接口、Load/Store/LSQ、MMU 与权限检查、cacheable 与 uncacheable 路径、向量访存，最后看 review checklist。

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
