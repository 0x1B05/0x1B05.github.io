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

    我是上海科技大学电子信息硕士生，目前在一生一芯课题组。完成一生一芯 B 线之后，我还在继续把 CPU 和数字系统这部分基础往体系结构、系统和性能分析上延伸，这个站点主要就是用来记录这个过程。

    最近我一边继续做 `NEMU` 和 `NPC` 上的 Linux bring-up，一边在跟香山昆明湖 `v2` 相关的 review 和验证工作。这里的 `NEMU` 是一生一芯里常用的教学型全系统模拟器，`NPC` 是我自己实现和维护的 `RISC-V64` 核项目。我也还在继续学 `gem5`，希望把这些零散的实践慢慢整理成更稳定的观察和分析方法。
  ]
  #html.div(class: "home-hero__profile")[
    #profile-image()
  ]
]

== 当前关注

我现在主要沿着几条相互关联的线继续推进：

- 在 CPU 与数字系统基础之上，继续补微结构性能分析这部分的方法和直觉
- 把 Linux bring-up、调试过程和模拟器使用连成一条更完整的工作线
- 通过香山昆明湖 `v2` 的 review 和验证工作继续熟悉真实项目里的问题
- 长期再逐步从传统 CPU perf 问题过渡到 AI workload 与 accelerator performance

#html.div(class: "home-links")[
  #home-link(
    locale-url("zh", route: "docs/"),
    "学习笔记与参考",
    "整理体系结构笔记、bring-up 记录，以及之后还会反复翻看的参考页面。",
  )
  #home-link(
    locale-url("zh", route: "blog/"),
    "实验记录与文章",
    "放一些短文、阅读笔记和阶段性记录。",
  )
  #home-link(
    locale-url("zh", route: "cv/"),
    "背景与发展方向",
    "用一页简短的介绍说明我的背景、当前工作和之后的方向。",
  )
]

== 这个站点想做什么

这个站点就是一个简单的个人主页，加上一套会持续补充的技术笔记。主要用来记录我现在在做什么、最近在学什么，以及接下来想往哪里走。
