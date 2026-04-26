#import "../../config.typ": template, tufted, content-card as shared-content-card, profile-image, locale-url
#show: template.with(locale: "zh", route: "")

#let content-card = shared-content-card

#let home-link(href, title, description) = html.a(href: href, class: "home-link")[
  #html.span(class: "home-link__title")[#title]
  #html.span(class: "home-link__description")[#description]
]

#html.div(class: "home-hero")[
  #html.div(class: "home-hero__copy")[

    这里是 `0x1B05` 的个人站点。这里主要放我正在做的项目、体系结构笔记，以及一些持续补充的教程和阅读记录。现在的内容大多围绕 `RISC-V`、Linux bring-up、模拟器与调试工具、香山及其相关基础设施展开；如果你想快速浏览站点内容，直接从 #link(locale-url("zh", route: "docs/"))[`Docs`] 和 #link(locale-url("zh", route: "blog/"))[`Blog`] 两个入口开始会更合适。

    == 关于我

    我是上海科技大学电子信息硕士生，目前在一生一芯课题组。做完一生一芯 B 线之后，我还在继续补 CPU、数字系统、体系结构和系统软件之间的那条线。这个站点主要用来放我现在读到、做到、调到的一些东西。

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
    "整理体系结构笔记、Linux bring-up 记录、paper reading 系列，以及之后还会反复翻看的参考页面。",
  )
  #home-link(
    locale-url("zh", route: "blog/"),
    "实验记录与文章",
    "放一些更短的工具笔记、bring-up 过程里的具体问题，以及围绕 OpenSBI、checkpoint、调试工具的阅读记录。",
  )
  #home-link(
    locale-url("zh", route: "cv/"),
    "背景与近况",
    "用一页简短介绍说明我的背景、最近在做的事和技术兴趣。",
  )
]

== 这个站点

这里不会太像正式博客，更多是一个方便自己回看的地方。遇到需要整理的启动链路、工具文档、读码笔记，先放下来；等之后理解变了，再回来改。
