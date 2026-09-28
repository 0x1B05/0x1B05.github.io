#import "../../config.typ": (
  content-card, doc-toc, locale-url, profile-image, series-begin,
  series-context, series-navbar, template, tufted,
  note as shared-note, tip as shared-tip, example as shared-example,
  definition as shared-definition, warning as shared-warning,
)
#show: template.with(locale: "en", route: "")

// Locale-bound callouts, re-exported for every page in this locale tree.
#let note(body, title: auto) = shared-note(body, title: title, locale: "en")
#let tip(body, title: auto) = shared-tip(body, title: title, locale: "en")
#let example(body, title: auto) = shared-example(body, title: title, locale: "en")
#let definition(body, title: auto) = shared-definition(body, title: title, locale: "en")
#let warning(body, title: auto) = shared-warning(body, title: title, locale: "en")

#let home-link(href, title, description) = html.a(href: href, class: "home-link")[
  #html.span(class: "home-link__title")[#title]
  #html.span(class: "home-link__description")[#description]
]

#html.div(class: "home-hero")[
  #html.div(class: "home-hero__copy")[

    // TODO: one or two sentences about what this site is.

    == About Me

    // TODO: short bio.
  ]
  #html.div(class: "home-hero__profile")[
    #profile-image()
  ]
]

#html.div(class: "home-links")[
  #home-link(
    locale-url("en", route: "docs/"),
    "Docs",
    "Structured notes and series.",
  )
  #home-link(
    locale-url("en", route: "blog/"),
    "Blog",
    "Shorter posts and notes.",
  )
  #home-link(
    locale-url("en", route: "cv/"),
    "CV",
    "Background and recent work.",
  )
]
