#import "@preview/tufted:0.1.1"

#let site-name = "0x1B05"
#let site-tagline-en = "Personal essays, notes, and documentation."
#let site-tagline-zh = "一个用于发布个人文章、笔记与文档的网站。"
#let footer-year = "2026"
#let footer-label-en = "Personal site"
#let footer-label-zh = "个人博客"

#let site-home-url() = "/"
#let site-url(path) = "/" + path

#let normalize-route(route) = if route == "" {
  ""
} else if route.ends-with("/") {
  route
} else {
  route + "/"
}

#let locale-root(locale) = site-url(locale + "/")

#let locale-url(locale, route: "") = {
  let normalized = normalize-route(route)
  if normalized == "" {
    locale-root(locale)
  } else {
    locale-root(locale) + normalized
  }
}

#let opposite-locale(locale) = if locale == "zh" { "en" } else { "zh" }
#let locale-badge(locale) = if locale == "zh" { "中" } else { "EN" }

#let locale-copy(locale) = if locale == "zh" {
  (
    nav_docs: "文档",
    nav_blog: "博客",
    nav_cv: "简历",
    docs_series: "系列",
    docs_reference: "参考",
    series_begin: "开始阅读这个系列",
    series_home: "系列首页",
    series_previous: "上一章",
    series_next: "下一章",
    theme_label: "主题",
    theme_light: "亮色",
    theme_dark: "暗色",
    theme_system: "跟随系统",
    language_label: "语言",
    search_label: "搜索",
    search_placeholder: "搜索全站内容",
    search_button: "搜索",
    search_results: "搜索结果",
    search_hint: "输入关键词，查看全站匹配结果。",
    search_loading: "正在搜索……",
    search_empty: "没有找到结果。",
    search_error: "搜索暂时不可用。",
    search_section_home: "首页",
    search_section_docs: "文档",
    search_section_blog: "博客",
    search_section_cv: "简历",
    footer_label: footer-label-zh,
    footer_tagline: site-tagline-zh,
  )
} else {
  (
    nav_docs: "Docs",
    nav_blog: "Blog",
    nav_cv: "CV",
    docs_series: "Series",
    docs_reference: "Reference",
    series_begin: "Begin the series!",
    series_home: "Series homepage",
    series_previous: "Previous",
    series_next: "Next",
    theme_label: "Theme",
    theme_light: "Light",
    theme_dark: "Dark",
    theme_system: "System",
    language_label: "Language",
    search_label: "Search",
    search_placeholder: "Search the site",
    search_button: "Search",
    search_results: "Search Results",
    search_hint: "Enter keywords to search across the whole site.",
    search_loading: "Searching...",
    search_empty: "No results found.",
    search_error: "Search is temporarily unavailable.",
    search_section_home: "Home",
    search_section_docs: "Docs",
    search_section_blog: "Blog",
    search_section_cv: "CV",
    footer_label: footer-label-en,
    footer_tagline: site-tagline-en,
  )
}

#let theme-icon(kind, class: "") = {
  let stroke-width = if kind == "system" { "1.6" } else { "2.0" }
  let svg-attrs = (
    xmlns: "http://www.w3.org/2000/svg",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    "stroke-width": stroke-width,
    "aria-hidden": "true",
  ) + if class == "" { (:) } else { (class: class) }

  if kind == "sun" {
    html.elem("svg", attrs: svg-attrs)[
      #html.elem(
        "path",
        attrs: (
          d: "M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z",
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
        ),
      )[]
    ]
  } else if kind == "moon" {
    html.elem("svg", attrs: svg-attrs)[
      #html.elem(
        "path",
        attrs: (
          d: "M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z",
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
        ),
      )[]
    ]
  } else if kind == "search" {
    html.elem("svg", attrs: svg-attrs)[
      #html.elem(
        "path",
        attrs: (
          d: "M21 21l-4.35-4.35m1.35-5.15a6.5 6.5 0 11-13 0 6.5 6.5 0 0113 0z",
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
        ),
      )[]
    ]
  } else {
    html.elem("svg", attrs: svg-attrs)[
      #html.elem(
        "path",
        attrs: (
          d: "M9 17.25v1.007a3 3 0 01-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0115 18.257V17.25m6-12V15a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 15V5.25m18 0A2.25 2.25 0 0018.75 3H5.25A2.25 2.25 0 003 5.25m18 0V12a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 12V5.25",
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
        ),
      )[]
    ]
  }
}

#let brand-logo() = html.span(class: "site-brand")[
  #html.span(class: "site-brand__light")[#image("assets/logo-light.svg", alt: site-name)]#html.span(class: "site-brand__dark")[#image("assets/logo-dark.svg", alt: site-name)]
]

#let nav-link(href, title, kind: "default") = {
  let link-class = if kind == "brand" {
    "site-nav__link site-nav__link--brand"
  } else {
    "site-nav__link"
  }

  html.a(href: href, class: link-class, title)
}

#let language-switcher-entry(locale, target-locale, route, label) = {
  if locale == target-locale {
    html.elem("span", attrs: (class: "language-switcher__link is-active", "aria-current": "page"))[#label]
  } else {
    html.a(href: locale-url(target-locale, route: route), class: "language-switcher__link")[#label]
  }
}

#let language-switcher(locale, route) = {
  let copy = locale-copy(locale)

  html.elem("div", attrs: (class: "language-switcher", role: "group", "aria-label": copy.language_label))[
    #language-switcher-entry(locale, "en", route, "EN")#html.elem("span", attrs: (class: "language-switcher__divider", "aria-hidden": "true"))[/]#language-switcher-entry(locale, "zh", route, "中")
  ]
}

#let theme-switcher-option(kind, label) = {
  let icon = if kind == "light" {
    "sun"
  } else if kind == "dark" {
    "moon"
  } else {
    "system"
  }

  html.button(
    type: "button",
    class: "theme-switcher__option theme-switcher__option--" + kind,
    role: "menuitem",
  )[
    #html.elem("span", attrs: (class: "theme-switcher__option-icon", "aria-hidden": "true"))[#theme-icon(icon, class: "theme-switcher__option-svg")]#html.span(class: "theme-switcher__option-label")[#label]
  ]
}

#let theme-switcher(locale) = {
  let copy = locale-copy(locale)

  html.elem("div", attrs: (class: "theme-switcher"))[
    #html.elem(
      "button",
      attrs: (
        type: "button",
        class: "theme-switcher__button",
        "aria-label": copy.theme_label,
        "aria-expanded": "false",
        "aria-haspopup": "menu",
        "aria-controls": "theme-switcher-menu",
      ),
    )[
      #html.elem("span", attrs: (class: "theme-switcher__button-icon theme-switcher__button-icon--sun", "aria-hidden": "true"))[#theme-icon("sun")]#html.elem("span", attrs: (class: "theme-switcher__button-icon theme-switcher__button-icon--moon", "aria-hidden": "true"))[#theme-icon("moon")]
    ]
    #html.elem("div", attrs: (id: "theme-switcher-menu", class: "theme-switcher__menu", role: "menu"))[
      #theme-switcher-option("light", copy.theme_light)
      #theme-switcher-option("dark", copy.theme_dark)
      #theme-switcher-option("system", copy.theme_system)
    ]
  ]
}

#let site-search(locale) = {
  let copy = locale-copy(locale)
  let action = locale-url(locale, route: "search/")

  html.elem(
    "div",
    attrs: (
      class: "site-search",
      "data-search-locale": locale,
      "data-search-results-label": copy.search_results,
      "data-search-hint-label": copy.search_hint,
      "data-search-loading-label": copy.search_loading,
      "data-search-empty-label": copy.search_empty,
      "data-search-error-label": copy.search_error,
      "data-search-section-home": copy.search_section_home,
      "data-search-section-docs": copy.search_section_docs,
      "data-search-section-blog": copy.search_section_blog,
      "data-search-section-cv": copy.search_section_cv,
    ),
  )[
    #html.elem("form", attrs: (class: "site-search__form", role: "search", action: action, method: "get"))[
      #html.elem("label", attrs: ("for": "site-search-input", class: "site-search__label"))[
        #html.elem("span", attrs: (class: "site-search__icon", "aria-hidden": "true"))[#theme-icon("search", class: "site-search__icon-svg")]#html.span(class: "site-search__label-text")[#copy.search_label]
      ]
      #html.input(
        id: "site-search-input",
        class: "site-search__input",
        type: "search",
        name: "q",
        placeholder: copy.search_placeholder,
      )
      #html.button(type: "submit", class: "site-search__button")[#copy.search_button]
    ]
    #html.elem("div", attrs: (class: "site-search__dropdown", hidden: "hidden"))[
      #html.elem("div", attrs: (class: "site-search__status"))[]
      #html.elem("div", attrs: (class: "site-search__results"))[]
    ]
    #html.elem("template", attrs: (id: "site-search-result-template"))[
      #html.a(href: "#", class: "site-search-result")[
        #html.span(class: "site-search-result__header")[
          #html.span(class: "site-search-result__title")[]
          #html.span(class: "site-search-result__meta")[
            #html.span(class: "site-search-result__section")[]
            #html.span(class: "site-search-result__locale")[]
          ]
        ]
        #html.span(class: "site-search-result__excerpt")[]
      ]
    ]
  ]
}

#let make-header(links, locale: none, route: "") = html.header(
  if links != none {
    html.nav[
      #html.elem("div", attrs: (class: "site-nav__primary"))[
        #for entry in links {
          let href = entry.at(0)
          let title = entry.at(1)
          let kind = if entry.len() > 2 { entry.at(2) } else { "default" }
          nav-link(href, title, kind: kind)
        }
      ]
      #if locale != none [
        #html.elem("div", attrs: (class: "site-nav__controls"))[
          #site-search(locale)
          #language-switcher(locale, route)
          #theme-switcher(locale)
        ]
      ]
    ]
  },
)

#let site-footer(locale) = {
  let copy = locale-copy(locale)

  html.div(class: "site-footer")[
    #html.span(class: "site-footer__copy")[#("© " + footer-year)]
    #html.a(href: site-home-url())[#site-name]
    #html.span(class: "site-footer__meta")[#(copy.footer_label + " · " + copy.footer_tagline)]
  ]
}

#let profile-image(alt: "Profile portrait for the site owner") = html.img(
  src: site-url("assets/profile.png"),
  alt: alt,
)

#let content-card(href, thumbnail, title, description, label: none) = html.a(
  href: href,
  class: "content-card",
)[
  #html.span(class: "content-card__thumb")[#image(
    "assets/content-thumbnails/" + thumbnail,
    alt: title,
  )]#html.span(class: "content-card__body")[
    #if label != none [
      #html.span(class: "content-card__label")[#label]
    ]
    #html.span(class: "content-card__title")[#title]
    #html.span(class: "content-card__description")[#description]
  ]
]

#let series-context(series, route) = {
  let normalized = normalize-route(route)
  let chapter-index = series.chapters.position(chapter => chapter.route == normalized)
  let previous = if chapter-index != none and chapter-index > 0 {
    series.chapters.at(chapter-index - 1)
  } else {
    none
  }
  let next = if chapter-index != none and chapter-index + 1 < series.chapters.len() {
    series.chapters.at(chapter-index + 1)
  } else {
    none
  }

  (
    series: series,
    chapter-index: chapter-index,
    previous: previous,
    next: next,
    home_route: series.route,
  )
}

#let series-begin(locale, route) = {
  let copy = locale-copy(locale)

  html.p(class: "series-begin")[
    #html.a(
      href: locale-url(locale, route: route),
      class: "series-begin__link",
    )[#copy.series_begin]
  ]
}

#let series-navbar(locale, context_) = {
  let copy = locale-copy(locale)

  html.nav(class: "series-nav")[
    #if context_.previous != none [
      #html.a(
        href: locale-url(locale, route: context_.previous.route),
        class: "series-nav__link series-nav__link--previous",
      )[#("« " + copy.series_previous)]
    ]
    #html.a(
      href: locale-url(locale, route: context_.home_route),
      class: "series-nav__link series-nav__link--home",
    )[#copy.series_home]
    #if context_.next != none [
      #html.a(
        href: locale-url(locale, route: context_.next.route),
        class: "series-nav__link series-nav__link--next",
      )[#(copy.series_next + " »")]
    ]
  ]
}

#let site-web(
  header-links: none,
  title: site-name,
  lang: "en",
  locale: none,
  route: "",
  footer-locale: none,
  head-scripts: (),
  body-scripts: (),
  css: (
    "https://cdnjs.cloudflare.com/ajax/libs/tufte-css/1.8.0/tufte.min.css",
    site-url("assets/tufted.css"),
    site-url("assets/custom.css"),
  ),
  content,
) = {
  show: tufted.template-math
  show: tufted.template-refs
  show: tufted.template-notes
  show: tufted.template-figures

  let resolved-footer-locale = if footer-locale == none { lang } else { footer-locale }

  set text(lang: lang)

  html.html(
    lang: lang,
    {
      html.head({
        html.meta(charset: "utf-8")
        html.meta(name: "viewport", content: "width=device-width, initial-scale=1")
        html.title(title)
        html.script(src: site-url("assets/theme-bootstrap.js"))[]
        for (script-link) in head-scripts {
          html.script(src: script-link)[]
        }
        for (css-link) in css {
          html.link(rel: "stylesheet", href: css-link)
        }
      })

      html.body({
        make-header(header-links, locale: locale, route: route)
        html.article(
          html.section({
            html.script(src: site-url("assets/theme-switcher.js"))[]
            html.script(src: site-url("assets/language-switcher.js"))[]
            html.script(src: site-url("assets/search.js"))[]
            for (script-link) in body-scripts {
              html.script(src: script-link)[]
            }
            content
            site-footer(resolved-footer-locale)
          }),
        )
      })
    },
  )
}

#let template(body, title: site-name, header-links: auto, ..options) = {
  // Legacy passthrough remains supported; localized keys are peeled off before the old ..options, handoff to site-web.
  let named-options = options.named()
  let locale = named-options.at("locale", default: "en")
  let route = named-options.at("route", default: "")
  let lang = named-options.at("lang", default: locale)
  let footer-locale = named-options.at("footer-locale", default: locale)
  let forwarded-options = named-options
  if "locale" in forwarded-options {
    let _ = forwarded-options.remove("locale")
  }
  if "route" in forwarded-options {
    let _ = forwarded-options.remove("route")
  }
  if "lang" in forwarded-options {
    let _ = forwarded-options.remove("lang")
  }
  if "footer-locale" in forwarded-options {
    let _ = forwarded-options.remove("footer-locale")
  }
  let copy = locale-copy(locale)
  let nav-links = if header-links == auto {
    (
      (locale-url(locale), brand-logo(), "brand"),
      (locale-url(locale, route: "docs/"), copy.nav_docs, "default"),
      (locale-url(locale, route: "blog/"), copy.nav_blog, "default"),
      (locale-url(locale, route: "cv/"), copy.nav_cv, "default"),
    )
  } else {
    header-links
  }

  let page = site-web.with(
    header-links: nav-links,
    title: title,
    locale: locale,
    lang: lang,
    route: route,
    footer-locale: footer-locale,
    ..forwarded-options,
  )

  page[
    #body
  ]
}
