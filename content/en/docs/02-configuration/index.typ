#import "../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": series-registry
#show: template.with(locale: "en", route: "docs/02-configuration/", title: "Configuration")

#let series = series-registry.at(0)
#let nav = series-context(series, "docs/02-configuration/")

= Website Structure

#series-navbar("en", nav)

The bilingual template is built from four primary layers:

- `config.typ` — the shared shell, routing helpers, localized labels, and global controls.
- `content/en/` — the English content tree.
- `content/zh/` — the Chinese content tree.
- `assets/` — shared static assets and scripts used by both locales.

== Default Asset Roles

The refreshed template uses a few shared assets with fixed default roles:

- `assets/logo-light.svg` — top-left brand mark in light theme.
- `assets/logo-dark.svg` — top-left brand mark in dark theme.
- `assets/profile.png` — profile portrait for both localized home pages.
- `assets/content-thumbnails/` — thumbnails used by the blog and docs entry cards.

== Main Configuration

In `config.typ`, you wrap the upstream Tufted primitives in a local `site-web()` shell and a locale-aware `template()` helper. That wrapper is responsible for the shared shell around every page: the branded navigation, stylesheet wiring, prepaint theme bootstrap, language switcher, theme switcher, and footer.

```typst
#let locale-root(locale) = site-url(locale + "/")

#let locale-url(locale, route: "") = {
  let normalized = normalize-route(route)
  if normalized == "" {
    locale-root(locale)
  } else {
    locale-root(locale) + normalized
  }
}

#let template(
  body,
  title: site-name,
  locale: "en",
  route: "",
) = {
  let copy = locale-copy(locale)
  let nav-links = (
    (locale-url(locale), brand-logo(), "brand"),
    (locale-url(locale, route: "docs/"), copy.nav_docs, "default"),
    (locale-url(locale, route: "blog/"), copy.nav_blog, "default"),
    (locale-url(locale, route: "cv/"), copy.nav_cv, "default"),
  )

  let page = site-web.with(
    header-links: nav-links,
    locale: locale,
    lang: locale,
    route: route,
    footer-locale: locale,
  )

  page[#body]
}
```

== Hierarchy And Inheritance

The site still uses a hierarchical Typst structure. Each localized subtree has its own root `index.typ`, and child pages import from their nearest localized parent instead of reaching back to `config.typ` directly.

- `content/en/docs/index.typ` imports from `content/en/index.typ`
- `content/en/docs/01-quick-start/index.typ` imports from `content/en/docs/index.typ`
- the Chinese tree mirrors the same pattern under `content/zh/`

That keeps shared shell behavior centralized while allowing each locale to own its copy and page text.

== Localization Responsibilities

- Shared UI strings such as navigation labels and theme menu labels live in `config.typ`.
- Page-specific prose lives inside the localized content files under `content/en/` and `content/zh/`.
- Matching slugs are required across both trees so the language switcher can compute sibling links safely.

== GitHub Pages Paths

- Leave `site-root` as `""` if you publish from a user or organization site such as `username.github.io`.
- Set `site-root` to `"/your-repository-name"` if you publish from a project site, and do not add a trailing slash.

With that in place, `/en/` and `/zh/` will resolve correctly on Pages as well.

#series-navbar("en", nav)
