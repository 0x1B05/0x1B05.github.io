#import "../index.typ": content-card, locale-url, template, tufted
#show: template.with(locale: "zh", route: "blog/", title: "博客")

= 博客

这里放一些没有整理成 docs 的东西，先堆在这里。

== 推荐阅读

#html.div(class: "content-grid")[
  #content-card(
    locale-url("zh", route: "blog/opensbi/"),
    "research-log.svg",
    "为什么一做 Linux Bring-up 就绕不开 OpenSBI",
    "从特权级一路读到 M 模式固件和 SBI 边界，记录为什么绕不开它。",
    label: "Bring-up 笔记",
  )
  #content-card(
    locale-url("zh", route: "blog/lightsss/"),
    "workflow-guide.svg",
    "LightSSS 在解决什么问题",
    "读 LightSSS 的笔记：轻量级仿真快照为什么能加快长时间 RTL 调试里的回放和定位。",
    label: "工具笔记",
  )
  #content-card(
    locale-url("zh", route: "blog/libcheckpoint-alpha/"),
    "reading-notes.svg",
    "把 LibCheckpointAlpha 当作基础设施来读",
    "围绕 checkpoint 恢复和 bootloader 链接的读码笔记，看完对整条软件栈的理解会变。",
    label: "阅读笔记",
  )
]
