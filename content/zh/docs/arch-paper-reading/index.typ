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

这个系列是把我之前的 paper notes 重新整理成一组方法导向的文章。重点不是复述原文目录，而是把每篇论文真正提出了什么方法、它依赖哪些硬件状态和更新规则、设计权衡落在哪里，重新梳理清楚。

目前这一批文章主要集中在几类比较典型的问题上：

- latency hiding 与 prefetching
- translation reach 与 TLB 组织
- memory dependence prediction

所以阅读顺序也不是随机排的。前面三篇先把几种不同的 latency-hiding 方法放在一起看，后面两篇再转到地址翻译和乱序执行里的内存相关性问题。

== 建议阅读方式

如果是第一次看，建议顺着编号往下读。

- 第 1 篇和第 2 篇可以一起看：一个偏未来 instruction stream look-ahead，一个偏给预取器加反馈控制。
- 第 3 篇把视角切到 region 级 spatial pattern，是和传统 stride 预取差异非常大的一篇。
- 第 4 篇和第 5 篇分别落在 MMU 和 OOO memory ordering 上，都是现代核里非常核心的问题。

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
