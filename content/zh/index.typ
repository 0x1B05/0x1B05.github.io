#import "../../config.typ": (
  content-card, doc-toc, locale-url, profile-image, series-begin,
  series-context, series-navbar, template, tufted,
  note as shared-note, tip as shared-tip, example as shared-example,
  definition as shared-definition, warning as shared-warning,
)
#show: template.with(locale: "zh", route: "")

// 绑定中文标题的 callout,重新导出给整个中文内容树使用。
#let note(body, title: auto) = shared-note(body, title: title, locale: "zh")
#let tip(body, title: auto) = shared-tip(body, title: title, locale: "zh")
#let example(body, title: auto) = shared-example(body, title: title, locale: "zh")
#let definition(body, title: auto) = shared-definition(body, title: title, locale: "zh")
#let warning(body, title: auto) = shared-warning(body, title: title, locale: "zh")

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
    "简介",
    "背景和最近在做的事。",
  )
]
