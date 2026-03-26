#import "../index.typ": template, tufted, content-card, locale-url
#show: template.with(locale: "zh", route: "blog/", title: "博客")

= 博客

这里放更短一些的东西：阅读笔记、工具反思，以及做 bring-up 过程中冒出来的零散观察。和 docs 相比，这一部分会保留更多个人视角，而不是把每个话题都写成已经定稿的说明书。

== 推荐阅读

#html.div(class: "content-grid")[
  #content-card(
    locale-url("zh", route: "blog/2025-10-30-normal-distribution/"),
    "research-log.svg",
    "为什么一做 Linux Bring-up 就绕不开 OpenSBI",
    "一篇短笔记，记录我为什么会从抽象的特权级阅读，走到不得不认真看待 M 模式固件和 SBI 边界。",
    label: "Bring-up 笔记",
  )
  #content-card(
    locale-url("zh", route: "blog/2024-10-04-iterators-generators/"),
    "workflow-guide.svg",
    "我理解的 LightSSS 在优化什么",
    "一篇阅读笔记，记录轻量级仿真快照为什么能在长时间 RTL 调试里明显改善回放与定位效率。",
    label: "工具笔记",
  )
  #content-card(
    locale-url("zh", route: "blog/2025-04-16-monkeys-apes/"),
    "reading-notes.svg",
    "把 LibCheckpointAlpha 当作基础设施来读",
    "一篇围绕 checkpoint 恢复和 bootloader 链接的小文章，解释为什么这种基础设施会改变我对整条软件栈的理解。",
    label: "阅读笔记",
  )
]

== 如何阅读这一部分

- 先看卡片上方的标签，判断这篇内容更接近教程、笔记还是轻量参考。
- 把这个页面当成文章归档的入口，每张卡片都应在读者点开前说明文章用途。
- 随着内容增多，请保持中英文摘要彼此对应，让语言切换总能落到等价页面。
