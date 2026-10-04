#let site-name = "0x1B05"
#let footer-year = str(datetime.today().year())

// --- URL helpers ---

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

// --- Localized copy ---

#let locale-copy-table = (
  zh: (
    nav_docs: "文档",
    nav_blog: "博客",
    nav_cv: "简历",
    docs_toc: "目录",
    callout_note: "备注",
    callout_tip: "提示",
    callout_example: "例子",
    callout_definition: "定义",
    callout_warning: "注意",
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
    docs_series: "系列",
    docs_notes: "短文",
    docs_empty: "这里还没有内容。",
    home_docs_desc: "成体系的笔记和系列文章。",
    home_blog_desc: "短一些的文章和笔记。",
    home_cv_desc: "背景和最近在做的事。",
    footer_label: "个人博客",
    footer_tagline: "一个用于发布个人文章、笔记与文档的网站。",
  ),
  en: (
    nav_docs: "Docs",
    nav_blog: "Blog",
    nav_cv: "CV",
    docs_toc: "Contents",
    callout_note: "Note",
    callout_tip: "Tip",
    callout_example: "Example",
    callout_definition: "Definition",
    callout_warning: "Warning",
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
    docs_series: "Series",
    docs_notes: "Short Notes",
    docs_empty: "Nothing here yet.",
    home_docs_desc: "Structured notes and series.",
    home_blog_desc: "Shorter posts and notes.",
    home_cv_desc: "Background and recent work.",
    footer_label: "Personal site",
    footer_tagline: "Personal essays, notes, and documentation.",
  ),
)

#let locale-copy(locale) = locale-copy-table.at(locale, default: locale-copy-table.en)

// --- Icons ---

#let theme-icon-paths = (
  sun: "M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z",
  moon: "M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z",
  search: "M21 21l-4.35-4.35m1.35-5.15a6.5 6.5 0 11-13 0 6.5 6.5 0 0113 0z",
  system: "M9 17.25v1.007a3 3 0 01-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0115 18.257V17.25m6-12V15a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 15V5.25m18 0A2.25 2.25 0 0018.75 3H5.25A2.25 2.25 0 003 5.25m18 0V12a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 12V5.25",
  globe: "M12 21a9 9 0 100-18 9 9 0 000 18zM12 3c-2 0-3.6 4-3.6 9s1.6 9 3.6 9 3.6-4 3.6-9-1.6-9-3.6-9zM3 12h18",
)

#let theme-icon(kind, class: "") = {
  let svg-attrs = (
    xmlns: "http://www.w3.org/2000/svg",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    "stroke-width": if kind == "system" { "1.6" } else { "2.0" },
    "aria-hidden": "true",
  ) + if class == "" { (:) } else { (class: class) }

  html.elem("svg", attrs: svg-attrs)[
    #html.elem(
      "path",
      attrs: (
        d: theme-icon-paths.at(kind, default: theme-icon-paths.system),
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
      ),
    )[]
  ]
}

// --- Header ---

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

#let language-switcher-option(locale, target-locale, route, label, badge) = {
  let body = [
    #html.elem("span", attrs: (class: "language-switcher__option-icon", "aria-hidden": "true"))[#badge]
    #html.span(class: "language-switcher__option-label")[#label]
  ]

  if locale == target-locale {
    html.elem("span", attrs: (class: "language-switcher__option is-active", role: "menuitem", "aria-current": "page"))[#body]
  } else {
    html.a(href: locale-url(target-locale, route: route), class: "language-switcher__option", role: "menuitem")[#body]
  }
}

#let language-switcher(locale, route) = {
  let copy = locale-copy(locale)

  html.elem("div", attrs: (class: "language-switcher", "data-dropdown": ""))[
    #html.elem(
      "button",
      attrs: (
        type: "button",
        class: "language-switcher__button",
        "aria-label": copy.language_label,
        "aria-expanded": "false",
        "aria-haspopup": "menu",
        "aria-controls": "language-switcher-menu",
        "data-dropdown-button": "",
      ),
    )[
      #html.elem("span", attrs: (class: "language-switcher__button-icon", "aria-hidden": "true"))[#theme-icon("globe")]
    ]
    #html.elem("div", attrs: (id: "language-switcher-menu", class: "language-switcher__menu", role: "menu", "data-dropdown-menu": ""))[
      #language-switcher-option(locale, "en", route, "English", "EN")
      #language-switcher-option(locale, "zh", route, "中文", "中")
    ]
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
    #html.elem("span", attrs: (class: "theme-switcher__option-icon", "aria-hidden": "true"))[#theme-icon(icon)]#html.span(class: "theme-switcher__option-label")[#label]
  ]
}

#let theme-switcher(locale) = {
  let copy = locale-copy(locale)

  html.elem("div", attrs: (class: "theme-switcher", "data-dropdown": ""))[
    #html.elem(
      "button",
      attrs: (
        type: "button",
        class: "theme-switcher__button",
        "aria-label": copy.theme_label,
        "aria-expanded": "false",
        "aria-haspopup": "menu",
        "aria-controls": "theme-switcher-menu",
        "data-dropdown-button": "",
      ),
    )[
      #html.elem("span", attrs: (class: "theme-switcher__button-icon theme-switcher__button-icon--sun", "aria-hidden": "true"))[#theme-icon("sun")]#html.elem("span", attrs: (class: "theme-switcher__button-icon theme-switcher__button-icon--moon", "aria-hidden": "true"))[#theme-icon("moon")]
    ]
    #html.elem("div", attrs: (id: "theme-switcher-menu", class: "theme-switcher__menu", role: "menu", "data-dropdown-menu": ""))[
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
      "data-dropdown": "",
    ),
  )[
    #html.elem(
      "button",
      attrs: (
        type: "button",
        class: "site-search__toggle",
        "aria-label": copy.search_label,
        "aria-expanded": "false",
        "aria-haspopup": "dialog",
        "aria-controls": "site-search-panel",
        "data-dropdown-button": "",
      ),
    )[
      #html.elem("span", attrs: (class: "site-search__toggle-icon", "aria-hidden": "true"))[#theme-icon("search")]
    ]
    #html.elem("div", attrs: (id: "site-search-panel", class: "site-search__panel", "data-dropdown-menu": ""))[
      #html.elem("form", attrs: (class: "site-search__form", role: "search", action: action, method: "get"))[
        #html.elem("label", attrs: ("for": "site-search-input", class: "site-search__label"))[
          #html.elem("span", attrs: (class: "site-search__icon", "aria-hidden": "true"))[#theme-icon("search", class: "site-search__icon-svg")]#html.span(class: "site-search__label-text")[#copy.search_label]
        ]
        #html.elem(
          "input",
          attrs: (
            id: "site-search-input",
            class: "site-search__input",
            type: "search",
            name: "q",
            placeholder: copy.search_placeholder,
            "data-dropdown-focus": "",
          ),
        )
        #html.button(type: "submit", class: "site-search__button")[#copy.search_button]
      ]
      #html.elem("div", attrs: (class: "site-search__dropdown", hidden: "hidden"))[
        #html.elem("div", attrs: (class: "site-search__status"))[]
        #html.elem("div", attrs: (class: "site-search__results"))[]
      ]
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
        #html.div(class: "site-nav__controls")[
          #site-search(locale)
          #language-switcher(locale, route)
          #theme-switcher(locale)
        ]
      ]
    ]
  },
)

// --- Page components ---

#let site-footer(locale) = {
  let copy = locale-copy(locale)

  html.elem("footer", attrs: (class: "site-footer"))[
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

// Home-page link card. With `eyebrow:` it doubles as the locale-gateway entry
// (class locale-entry), so the gateway page and the home pages share one card.
#let home-link(href, title, description, eyebrow: none) = html.a(
  href: href,
  class: if eyebrow == none { "home-link" } else { "home-link locale-entry" },
)[
  #if eyebrow != none [
    #html.span(class: "locale-entry__eyebrow")[#eyebrow]
  ]
  #html.span(class: "home-link__title")[#title]
  #html.span(class: "home-link__description")[#description]
]

// The three home-page cards, labeled from locale-copy so they cannot drift
// from the header navigation.
#let home-links(locale) = {
  let copy = locale-copy(locale)
  html.div(class: "home-links")[
    #home-link(locale-url(locale, route: "docs/"), copy.nav_docs, copy.home_docs_desc)
    #home-link(locale-url(locale, route: "blog/"), copy.nav_blog, copy.home_blog_desc)
    #home-link(locale-url(locale, route: "cv/"), copy.nav_cv, copy.home_cv_desc)
  ]
}

// Docs landing body: renders the series and note registries as card grids.
// Empty sections are omitted; when both are empty a muted fallback line shows.
#let docs-landing(locale, series-registry, note-registry) = {
  let copy = locale-copy(locale)
  let docs-card(entry, label: none) = content-card(
    locale-url(locale, route: entry.route),
    entry.thumbnail,
    entry.title,
    entry.summary,
    label: label,
  )

  if series-registry.len() == 0 and note-registry.len() == 0 {
    html.p(class: "docs-landing__empty")[#copy.docs_empty]
  } else {
    if series-registry.len() > 0 [
      == #copy.docs_series

      #html.div(class: "content-grid")[
        #for entry in series-registry [
          #docs-card(entry, label: copy.docs_series)
        ]
      ]
    ]
    if note-registry.len() > 0 [
      == #copy.docs_notes

      #html.div(class: "content-grid")[
        #for entry in note-registry [
          #docs-card(entry, label: entry.label)
        ]
      ]
    ]
  }
}

#let doc-toc(locale: none) = {
  html.elem("nav", attrs: (class: "doc-toc"))[
    #html.div(class: "doc-toc__title")[
      #context {
        let l = if locale != none { locale } else { text.lang }
        locale-copy(l).docs_toc
      }
    ]
    #outline(
      title: none,
      target: heading.where(level: 2).or(heading.where(level: 3)),
      depth: 3,
    )
  ]
}

// --- Callouts ---

#let callout(kind, title, body) = html.elem("aside", attrs: (class: "callout callout--" + kind))[
  #if title != none [
    #html.div(class: "callout__title")[#title]
  ]
  #html.div(class: "callout__body")[#body]
]

// The default title follows the page locale: the whole lookup lives in one
// `context` block so it is realized at layout time, where text.lang (set by
// site-web) is available. Pass `locale:` only to override it explicitly.
#let callout-kind(kind, body, title: auto, locale: none) = {
  let resolved-title = if title != auto { title } else {
    context {
      let l = if locale != none { locale } else { text.lang }
      locale-copy(l).at("callout_" + kind)
    }
  }
  callout(kind, resolved-title, body)
}

#let note(body, title: auto, locale: none) = callout-kind("note", body, title: title, locale: locale)

#let tip(body, title: auto, locale: none) = callout-kind("tip", body, title: title, locale: locale)

#let example(body, title: auto, locale: none) = callout-kind("example", body, title: title, locale: locale)

#let definition(body, title: auto, locale: none) = callout-kind("definition", body, title: title, locale: locale)

#let warning(body, title: auto, locale: none) = callout-kind("warning", body, title: title, locale: locale)

// --- Notes and figures ---

// Sidenotes: numbered notes render as superscript markers whose body pops up
// on hover/focus (styled via .sidenote in site.css); nothing is placed in the
// page margin. Write them as #sidenote[..] (#footnote[..] also works).
#let sidenote(body) = footnote[#body]

#let template-sidenotes(content) = {
  show footnote: it => if target() == "html" {
    let number = counter(footnote).display(it.numbering)
    html.elem("span", attrs: (class: "sidenote"))[
      #html.elem("sup", attrs: (class: "sidenote__marker", tabindex: "0"))[#number]#html.elem("span", attrs: (class: "sidenote__body"))[#it.body]
    ]
  }
  content
}

// Unnumbered in-flow aside (styled via .margin-note in site.css).
#let margin-note(content) = html.span(class: "margin-note", content)

// Reference rendering (adapted from the tufted package, MIT): equation refs
// become linked numbers, heading refs become the quoted heading title,
// linking to the target section.
#let template-refs(content) = {
  show ref: it => {
    let el = it.element
    if el != none and el.func() == math.equation {
      return link(el.location(), numbering(
        el.numbering,
        ..counter(math.equation).at(el.location()),
      ))
    }
    if el != none and el.func() == heading {
      return link(el.location(), smartquote() + el.body + smartquote())
    }
    it
  }
  content
}

// Figure captions render like a paper (styled via .figure__caption in
// site.css): above tables, below images and diagrams. Figures with
// numbering: none show the caption body alone, without supplement/number.
#let template-figures(content) = {
  show figure.caption: it => (
    it.supplement + sym.space.nobreak + it.counter.display() + it.separator + it.body
  )
  show figure: it => if target() == "html" {
    let caption = if it.caption != none {
      html.elem("figcaption", attrs: (class: "figure__caption"))[
        #if it.numbering == none { it.caption.body } else { it.caption }
      ]
    }
    if it.kind == table {
      html.figure[#caption #it.body]
    } else {
      html.figure[#it.body #caption]
    }
  }
  content
}

// Two side-by-side tables (styled via .table-pair in site.css), each usually
// wrapped in its own unnumbered figure; stacks vertically on narrow screens.
#let table-pair(left, right) = html.div(class: "table-pair")[#left #right]

// Block quotes keep the attribution inside the blockquote (styled via
// .quote__attribution in site.css) instead of a detached following paragraph.
#let template-quotes(content) = {
  show quote.where(block: true): it => if target() == "html" {
    html.elem("blockquote")[
      #it.body
      #if it.attribution != none {
        html.elem("footer", attrs: (class: "quote__attribution"))[— #it.attribution]
      }
    ]
  }
  content
}

// --- Series navigation ---

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

// --- Page shell ---

#let site-web(
  header-links: none,
  title: site-name,
  lang: "en",
  locale: none,
  route: "",
  footer-locale: none,
  head-scripts: (),
  body-scripts: (),
  css: (site-url("assets/site.css"),),
  content,
) = {
  show: template-refs
  show: template-sidenotes
  show: template-figures
  show: template-quotes
  // Center tables in the text column via a wrapper (see .table-wrap). Inside
  // html.frame the target is paged, so diagram tables stay untouched.
  show table: it => context {
    if target() == "paged" { it } else { html.div(class: "table-wrap")[#it] }
  }

  let resolved-footer-locale = if footer-locale == none { lang } else { footer-locale }

  set text(lang: lang)

  html.html(
    lang: lang,
    {
      html.head({
        html.meta(charset: "utf-8")
        html.meta(name: "viewport", content: "width=device-width, initial-scale=1")
        html.title(title)
        html.script(src: site-url("assets/theme-bootstrap.js"))
        for (script-link) in head-scripts {
          html.script(src: script-link)
        }
        for (css-link) in css {
          html.link(rel: "stylesheet", href: css-link)
        }
      })

      html.body({
        make-header(header-links, locale: locale, route: route)
        html.article(
          html.section({
            content
            site-footer(resolved-footer-locale)
          }),
        )
        // Deferred by placement: these attach via DOMContentLoaded, so loading
        // them after the content keeps the first paint unblocked.
        html.script(src: site-url("assets/dropdown.js"))
        html.script(src: site-url("assets/theme-switcher.js"))
        html.script(src: site-url("assets/language-switcher.js"))
        html.script(src: site-url("assets/search.js"))
        for (script-link) in body-scripts {
          html.script(src: script-link)
        }
      })
    },
  )
}

#let template(
  body,
  title: site-name,
  locale: "en",
  route: "",
  header-links: auto,
  ..options,
) = {
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

  site-web.with(
    header-links: nav-links,
    title: title,
    locale: locale,
    lang: locale,
    route: route,
    footer-locale: locale,
    ..options,
  )(body)
}

// A docs series chapter page: applies the page template, then renders the
// chapter title, series navbar, and on-page TOC around the body (navbar again
// at the bottom). The route must match the chapter's `route` in series.typ.
// Defined after `template` because Typst closures capture the module scope at
// their definition point.
#let series-chapter(series, route: none, title: none, locale: "en", body) = {
  assert(route != none and title != none, message: "series-chapter needs route: and title:")
  show: template.with(locale: locale, route: route, title: title)
  let nav = series-context(series, route)
  heading(level: 1, title)
  series-navbar(locale, nav)
  doc-toc()
  body
  series-navbar(locale, nav)
}
