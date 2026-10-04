#import "../../config.typ": *
#show: template.with(locale: "zh", route: "")

#let home-link(href, title, description) = html.a(
  href: href,
  class: "home-link",
)[
  #html.span(class: "home-link__title")[#title]
  #html.span(class: "home-link__description")[#description]
]

#html.div(class: "home-hero")[
  #html.div(class: "home-hero__copy")[

    // TODO: 一两句话介绍这个站点。

    == 关于我

    // TODO: 简短的个人简介。
  ]
  #html.div(class: "home-hero__profile")[
    #profile-image()
  ]
]

#html.div(class: "home-links")[
  #home-link(
    locale-url("zh", route: "docs/"),
    "文档",
    "成体系的笔记和系列文章。",
  )
  #home-link(
    locale-url("zh", route: "blog/"),
    "博客",
    "短一些的文章和笔记。",
  )
  #home-link(
    locale-url("zh", route: "cv/"),
    "简历",
    "背景和最近在做的事。",
  )
]
