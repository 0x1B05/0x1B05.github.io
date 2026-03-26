#import "../index.typ": (
  content-card, definition, example, locale-url, margin-note, note, sidenote,
  table-title, template, tip, warning,
)
#show: template.with(locale: "zh", route: "blog/", title: "博客")

= 博客

// TODO: 一句话介绍这个栏目。

#html.div(class: "content-grid")[
  // 每篇文章加一张 content-card,新的放前面:
  //
  // #content-card(
  //   locale-url("zh", route: "blog/<slug>/"),
  //   "<thumbnail.svg>",
  //   "<文章标题>",
  //   "<一句话摘要>",
  //   label: "<卡片标签>",
  // )
]
