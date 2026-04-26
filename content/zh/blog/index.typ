#import "../index.typ": template, tufted, content-card, locale-url
#show: template.with(locale: "zh", route: "blog/", title: "博客")

= 博客

这里放一些还没有必要整理成完整 docs 的东西：读工具文档时抓到的点、bring-up 里踩到的问题、还有当时觉得值得记下来的判断。

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

== 归档说明

这些文章不会都写成教程。有些只是当时读完一份文档后的理解，有些是调试过程中顺手留下来的记录。标题和标签会尽量说明它是在讲工具、bring-up，还是某个具体项目的阅读笔记。
