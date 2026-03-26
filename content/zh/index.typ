#import "../../config.typ": template, tufted, content-card as shared-content-card, profile-image, locale-url
#show: template.with(locale: "zh", route: "")

#let content-card = shared-content-card

#let home-link(href, title, description) = html.a(href: href, class: "home-link")[
  #html.span(class: "home-link__title")[#title]
  #html.span(class: "home-link__description")[#description]
]

= 0x1B05

#html.div(class: "home-hero")[
  #html.div(class: "home-hero__copy")[
    #html.span(class: "home-kicker")[体系结构笔记与进行中的工作]

    == 从 CPU 基础走向性能导向的系统工作

    我是上海科技大学电子信息专业硕士研究生，目前在一生一芯课题组。完成一生一芯 B 线之后，我现在的基础主要仍集中在 CPU 与数字系统入门，这个站点更像是我把这些基础逐步延伸到体系结构、系统工作与性能分析过程中的公开笔记。

    最近我在尝试让 `NEMU` 和 `NPC` 的核心启动 Linux。这里的 `NEMU` 是一生一芯体系里常用的教学型全系统模拟器，`NPC` 则是我自己实现和维护的 `RISC-V64` 核项目。同时我也在继续学习 `gem5`，希望逐步形成更稳定的微结构行为观察与性能分析方法。
  ]
  #html.div(class: "home-hero__profile")[
    #profile-image()
  ]
]

== 当前关注

我现在主要沿着几条相互关联的线继续推进：

- 在 CPU 与数字系统基础之上，继续补齐微结构性能分析的直觉和方法
- 通过 `NEMU` / `NPC` 上的 Linux bring-up，把体系结构、调试过程和系统行为连接起来
- 为即将到来的香山暑期实习做准备
- 长期再逐步从传统 CPU perf 问题过渡到 AI workload 与 accelerator performance

#html.div(class: "home-links")[
  #home-link(
    locale-url("zh", route: "docs/"),
    "学习笔记与参考",
    "整理体系结构学习记录、bring-up 过程说明，以及后续还会反复查看的方法论页面。",
  )
  #home-link(
    locale-url("zh", route: "blog/"),
    "实验记录与文章",
    "放置阅读笔记、阶段性总结，以及围绕系统和性能问题展开的技术写作。",
  )
  #home-link(
    locale-url("zh", route: "cv/"),
    "背景与发展方向",
    "用一页更紧凑的简介说明我的训练背景、当前工作、技术兴趣和接下来的方向。",
  )
]

== 这个站点想做什么

我希望这个站点保持简洁、可读，同时既能作为个人主页，也能承载持续积累的技术笔记。它更强调正在做什么、准备走向哪里，而不是把还没有形成的能力包装成已经完成的结论。
