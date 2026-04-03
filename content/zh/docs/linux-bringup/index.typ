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

这个系列更像是我当前用来连接“读规格”和“做 bring-up”的那条学习路径。它不再讲如何定制站点，而是顺着我现在真正绕不开的层次往下走：特权级、machine-mode firmware、工具分工，以及在 Linux bring-up 里反复使用的检查框架。

它也不是把自己写成已经把整条链路都吃透了。更准确地说，这是一条“当前需要理解什么、为什么这一层会变重要、它和后面的问题怎么接起来”的显式路径。

== 建议阅读方式

第一次读建议按顺序来。顺序会从特权模型进入，再到 OpenSBI、工具角色，最后落到一份更偏实践的 bring-up 检查框架。每一章都故意写得比较短，目的是先把路径理顺，而不是一次把所有细节讲满。

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
