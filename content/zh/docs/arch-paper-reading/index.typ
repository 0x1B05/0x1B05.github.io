#import "../index.typ": template, tufted, content-card, locale-url, series-begin, doc-toc
#import "./series.typ": arch-paper-reading-series
#show: template.with(locale: "zh", route: "docs/arch-paper-reading/", title: "体系结构论文精读")

#let series = arch-paper-reading-series

#let chapter-thumbnail(chapter) = if chapter.order == 1 {
  "prototype-notebook.svg"
} else if chapter.order == 2 {
  "workflow-guide.svg"
} else if chapter.order == 3 {
  "research-log.svg"
} else if chapter.order == 4 {
  "deployment-notes.svg"
} else {
  "starter-series.svg"
}

= 体系结构论文阅读与方法整理

#doc-toc("zh")

这个系列由我之前的 paper notes 整理而来。不按原文目录复述，每篇围绕论文的方法本身：依赖什么硬件状态、更新规则是什么、权衡在哪。

目前这几篇集中在三类问题上：

- latency hiding 与 prefetching
- translation reach 与 TLB 组织
- memory dependence prediction

顺序也按问题类型排：前三篇是几种 latency-hiding 方法，后两篇转到地址翻译和乱序执行里的内存相关性问题。

== 建议阅读方式

第一次看的话，顺着编号往下读就行。

- 第 1、2 篇可以一起看：一个用未来 instruction stream 做 look-ahead，一个给预取器加反馈控制。
- 第 3 篇切到 region 级 spatial pattern，思路和传统 stride 预取差别很大。
- 第 4、5 篇分别落在 MMU 和 OOO memory ordering 上，对应 TLB reach 和 memory dependence prediction。

== 包含文章

#html.div(class: "content-grid")[
  #for chapter in series.chapters [
    #content-card(
      locale-url("zh", route: chapter.route),
      chapter-thumbnail(chapter),
      chapter.title,
      chapter.summary,
      label: "第 " + str(chapter.order) + " 篇",
    )
  ]
]

#series-begin("zh", series.begin-route)
