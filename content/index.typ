#import "../config.typ": site-web, site-home-url, site-url, brand-logo, locale-url

#let locale-entry(href, eyebrow, title, description) = html.a(href: href, class: "home-link locale-entry")[
  #html.span(class: "locale-entry__eyebrow")[#eyebrow]
  #html.span(class: "home-link__title")[#title]
  #html.span(class: "home-link__description")[#description]
]

#show: site-web.with(
  title: "Choose a language",
  lang: "en",
  header-links: (
    (site-home-url(), brand-logo(), "brand"),
  ),
  footer-locale: "en",
  body-scripts: (site-url("assets/language-redirect.js"),),
)

= Choose Your Language

#html.div(class: "locale-gateway")[
  #html.p(class: "locale-gateway__intro")[
    Pick the language you want to browse in. This entry page will redirect automatically when JavaScript is available, while both localized versions remain directly linkable and work without scripting.
  ]

  #html.div(class: "locale-gateway__links")[
    #locale-entry(
      locale-url("en"),
      "English",
      "Open the English site",
      "Browse the home page, docs, blog, and profile pages under /en/.",
    )
    #locale-entry(
      locale-url("zh"),
      "中文",
      "进入中文站点",
      "查看首页、文档、博客与简介页面，路径位于 /zh/。",
    )
  ]
]

== Why There Are Two Prefixes

- `/en/` and `/zh/` keep every page shareable in a stable language-specific URL.
- The header switcher on localized pages sends readers to the matching route in the other language.
- This root page stays intentionally small so GitHub Pages has a clean default entry point.
