#import "../../config.typ": (
  content-card as shared-content-card, locale-url, profile-image, template,
  tufted,
)
#show: template.with(locale: "zh", route: "")

#let content-card = shared-content-card

#let home-link(href, title, description) = html.a(
  href: href,
  class: "home-link",
)[
  #html.span(class: "home-link__title")[#title]
  #html.span(class: "home-link__description")[#description]
]

#html.div(class: "home-hero")[
  #html.div(class: "home-hero__copy")[

    这是 `0x1B05` 的个人站点，放着我在做的项目、笔记，以及一些持续补充的教程和阅读记录。内容大多围绕体系结构、NPU、模拟器、香山及其相关基础设施。想快速浏览的话，从 #link(locale-url("zh", route: "docs/"))[`Docs`] 和 #link(locale-url("zh", route: "blog/"))[`Blog`] 两个入口进去就行。

    == 关于我

    我是上海科技大学电子信息的专业硕士，目前在一生一芯课题组。做完一生一芯 B 线后，参与过香山昆明湖 v2 的验证，现在在做一款和雁栖湖 CPU 配套的 NPU，用来加速 LLM 推理。更多背景见 cv 页面。
  ]
  #html.div(class: "home-hero__profile")[
    #profile-image()
  ]
]

== 当前关注

最近在做的几件事：

- 在 CPU 和数字系统的基础上，补微结构性能分析的方法和直觉
- 借香山昆明湖 `v2` 的 review 和验证，熟悉真实项目里会遇到的问题
- 长期方向是从传统 CPU perf 问题逐步转向 AI workload 和 accelerator performance

#html.div(class: "home-links")[
  #home-link(
    locale-url("zh", route: "docs/"),
    "学习笔记与参考",
    "体系结构笔记、Linux bring-up 记录、paper reading 系列，加上一些会反复翻的参考页面。",
  )
  #home-link(
    locale-url("zh", route: "blog/"),
    "实验记录与文章",
    "短一些的工具笔记、bring-up 中碰到的具体问题，还有 OpenSBI、checkpoint、调试工具相关的阅读记录。",
  )
  #home-link(
    locale-url("zh", route: "cv/"),
    "背景与近况",
    "一页介绍：背景、最近在做什么、技术兴趣。",
  )
]
