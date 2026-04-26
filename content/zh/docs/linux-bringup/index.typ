#import "../index.typ": template, tufted, content-card, locale-url, series-begin
#import "./series.typ": linux-bringup-series
#show: template.with(locale: "zh", route: "docs/linux-bringup/", title: "Linux Bring-up")

#let series = linux-bringup-series

#let chapter-thumbnail(chapter) = if chapter.order == 1 {
  "starter-series.svg"
} else if chapter.order == 2 {
  "prototype-notebook.svg"
} else if chapter.order == 3 {
  "workflow-guide.svg"
} else {
  "deployment-notes.svg"
}

= 从 RISC-V 特权级到 Linux Bring-up

这个系列是我把“读规格”和“做 bring-up”接起来时整理出的路径。现在绕不开的几层基本都在这里：特权级、machine-mode firmware、工具分工，以及 Linux bring-up 时反复要确认的检查项。

我还没有把整条链路都吃透，所以这里保留的是当前最需要先抓住的部分：每一层为什么会冒出来，它和后面的失败点怎么接上。

== 建议阅读方式

第一次读建议按顺序来：先看特权模型，再看 OpenSBI 和工具角色，最后看 bring-up 检查清单。每章都不长，先把路径理顺比一次塞满细节更重要。

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
