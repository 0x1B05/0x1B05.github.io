#import "../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": series-registry
#show: template.with(locale: "en", route: "docs/03-styling/", title: "Styling")

#let series = series-registry.at(0)
#let nav = series-context(series, "docs/03-styling/")

= Styling

#series-navbar("en", nav)

The visual appearance of the bilingual site is controlled by CSS plus a small amount of shell markup in `config.typ`.

== Default Stylesheets

The template accepts a `css` argument containing an array of stylesheet URLs or paths. By default, it loads three stylesheets:

```typst
#let page = site-web.with(
  css: (
    "https://cdnjs.cloudflare.com/ajax/libs/tufte-css/1.8.0/tufte.min.css",
    site-url("assets/tufted.css"),
    site-url("assets/custom.css"),
  ),
)
```

The refreshed shell keeps this order and routes local asset paths through `site-url(...)` so GitHub Pages project sites can add a repository prefix safely.

== What Lives In `assets/tufted.css`

The base theme now lives primarily in `assets/tufted.css`, including:

- light / dark / system theme colors
- top-left brand mark behavior for `logo-light.svg` and `logo-dark.svg`
- the language-switcher and theme-switcher layout
- localized home page profile layout
- blog and docs entry-card styling
- footer and link styling

== Theme And Language Scripts

The shell behavior is split across three small scripts:

- `assets/theme-bootstrap.js` applies the saved light/dark choice in the head before the first paint.
- `assets/theme-switcher.js` powers the visible theme controls and updates the saved preference.
- `assets/language-switcher.js` remembers the active locale from the current `/en/` or `/zh/` route.

The root gateway additionally loads `assets/language-redirect.js` so `/` can forward readers toward the preferred locale.

== Customizing Styles

To customize the look of your site, modify `assets/custom.css`. Because it loads last by default, your rules will override the shared shell styles.

For example, to adjust link colors:

```css
a {
  color: #ff0000;
}
```

== Overriding Stylesheets

If you want to replace the default stylesheet stack entirely, provide your own list in `config.typ`:

```typst
#let template(body) = {
  let page = site-web.with(
    css: (site-url("assets/style.css"),),
  )

  page[#body]
}
```

#series-navbar("en", nav)
