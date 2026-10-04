#import "../../config.typ": *
#show: template.with(locale: "en", route: "")

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
