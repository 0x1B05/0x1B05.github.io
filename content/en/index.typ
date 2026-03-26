#import "../../config.typ": template, tufted, content-card as shared-content-card, profile-image, locale-url
#show: template.with(locale: "en", route: "")

#let content-card = shared-content-card

#let home-link(href, title, description) = html.a(href: href, class: "home-link")[
  #html.span(class: "home-link__title")[#title]
  #html.span(class: "home-link__description")[#description]
]

= 0x1B05

#html.div(class: "home-hero")[
  #html.div(class: "home-hero__copy")[
    #html.span(class: "home-kicker")[Bilingual personal site]

    == Build a deliberate personal site in Typst

    This site is a bilingual writing hub with mirrored `/en/` and `/zh/` routes, a visible language switcher, and a restrained shell for long-form writing, documentation, and profile pages.

    It is set up for `0x1B05.github.io`, with GitHub Pages deployment, local preview targets, and a structure that stays easy to extend as the archive grows.
  ]
  #html.div(class: "home-hero__profile")[
    #profile-image()
  ]
]

== What This Version Includes

This site is organized around three practical sections:

- essays and posts for the #link(locale-url("en", route: "blog/"))[Blog]
- onboarding and how-to guides for the #link(locale-url("en", route: "docs/"))[Docs]
- a lightweight long-form profile page in the #link(locale-url("en", route: "cv/"))[CV]

#html.div(class: "home-links")[
  #home-link(
    locale-url("en", route: "docs/"),
    "Start with the docs",
    "Learn the folder layout, localization hooks, styling controls, and deployment path before you customize the content.",
  )
  #home-link(
    locale-url("en", route: "blog/"),
    "See the blog index",
    "Browse article-style entries with summaries and thumbnails that can grow into a real bilingual writing archive.",
  )
  #home-link(
    locale-url("en", route: "cv/"),
    "Review the profile page",
    "Keep a concise professional page alongside the rest of the site without breaking the overall shell.",
  )
]

== Maintenance Notes

- Replace `assets/logo-light.svg` and `assets/logo-dark.svg` to update the top-left brand mark.
- Replace `assets/profile.png` to change the home portrait shown in both locales.
- Edit both `content/en/` and `content/zh/` when you want mirrored bilingual pages.
- Keep `site-root = ""` in `config.typ` while the site is deployed from `0x1B05.github.io`.
