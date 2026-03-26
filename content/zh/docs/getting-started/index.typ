#import "../index.typ": template, tufted, content-card, locale-url, series-begin
#import "../series.typ": series-registry
#show: template.with(locale: "zh", route: "docs/getting-started/", title: "快速上手")

#let series = series-registry.at(0)

#let chapter-thumbnail(chapter) = if chapter.order == 1 {
  "starter-series.svg"
} else if chapter.order == 2 {
  "prototype-notebook.svg"
} else if chapter.order == 3 {
  "workflow-guide.svg"
} else {
  "deployment-notes.svg"
}

= 快速上手

这个系列会带你从一个刚初始化好的 Tufted 模板出发，走完本地预览、理解双语目录结构，以及整理出可发布站点所需的最小路径。

它适合那些想把演示内容替换成自己的网站内容，同时又希望从一开始就把共享壳层、镜像路由和部署流程理清楚的人。

== 建议阅读方式

第一次阅读时建议按顺序完成。每一章都会默认前一步已经准备好，所以顺序会从初始化开始，依次进入结构、样式，最后收束到部署发布。

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
