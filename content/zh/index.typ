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
    #html.span(class: "home-kicker")[双语个人站点]

    == 用 Typst 打造一个克制而明确的个人网站

    这个站点围绕 `/en/` 与 `/zh/` 两套镜像路由组织内容，导航栏提供显式语言切换，整体结构适合放置长文、文档、个人简介与持续积累的笔记。

    现在它已经按 `0x1B05.github.io` 的根路径部署方式整理好，本地预览、GitHub Pages 发布和后续扩展都可以在这套结构上继续推进。
  ]
  #html.div(class: "home-hero__profile")[
    #profile-image()
  ]
]

== 这个版本包含什么

这个站点目前围绕三类内容组织：

- 用于长文和随笔的 #link(locale-url("zh", route: "blog/"))[博客]
- 用于入门说明与操作指南的 #link(locale-url("zh", route: "docs/"))[文档]
- 用于展示个人简介与经历的 #link(locale-url("zh", route: "cv/"))[简历]

#html.div(class: "home-links")[
  #home-link(
    locale-url("zh", route: "docs/"),
    "先看文档部分",
    "先了解目录结构、本地化钩子、样式控制以及部署路径，再开始替换内容。",
  )
  #home-link(
    locale-url("zh", route: "blog/"),
    "查看博客索引",
    "通过带摘要和缩略图的文章卡片浏览内容，逐步扩展成真正的双语写作归档。",
  )
  #home-link(
    locale-url("zh", route: "cv/"),
    "浏览个人简介页",
    "保留一页简洁的个人资料和经历展示，同时维持统一的站点外观。",
  )
]

== 维护说明

- 替换 `assets/logo-light.svg` 和 `assets/logo-dark.svg`，更新左上角品牌标识。
- 替换 `assets/profile.png`，修改中英文首页共用的头像。
- 如果你要维护双语内容，请同步编辑 `content/en/` 和 `content/zh/`。
- 只要站点继续部署在 `0x1B05.github.io`，就保持 `config.typ` 里的 `site-root = ""`。
