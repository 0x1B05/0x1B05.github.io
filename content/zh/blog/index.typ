#import "../index.typ": template, tufted, content-card, locale-url
#show: template.with(locale: "zh", route: "blog/", title: "博客")

= 博客

这里放的是短篇随笔、示例说明和探索性笔记。卡片文案会先解释每篇文章“为什么值得点开”，这在双语归档里尤其重要。

== 推荐阅读

#html.div(class: "content-grid")[
  #content-card(
    locale-url("zh", route: "blog/2025-10-30-normal-distribution/"),
    "research-log.svg",
    "正态分布",
    "用简洁的方式说明高斯分布为什么重要、常见在哪里，以及两个核心参数在实践中的含义。",
    label: "统计",
  )
  #content-card(
    locale-url("zh", route: "blog/2024-10-04-iterators-generators/"),
    "workflow-guide.svg",
    "Python 中的迭代器与生成器",
    "一篇面向日常 Python 开发的实践笔记，对比显式迭代器对象与基于生成器的控制流。",
    label: "编程",
  )
  #content-card(
    locale-url("zh", route: "blog/2025-04-16-monkeys-apes/"),
    "reading-notes.svg",
    "猴子和猿有什么区别",
    "一个轻量的参考型示例，展示友好的文章归档同样可以保持结构清楚、说明充分。",
    label: "参考文章",
  )
]

== 如何阅读这一部分

- 先看卡片上方的标签，判断这篇内容更接近教程、笔记还是轻量参考。
- 把这个页面当成文章归档的入口，每张卡片都应在读者点开前说明文章用途。
- 随着内容增多，请保持中英文摘要彼此对应，让语言切换总能落到等价页面。
