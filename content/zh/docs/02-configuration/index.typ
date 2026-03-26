#import "../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": series-registry
#show: template.with(locale: "zh", route: "docs/02-configuration/", title: "配置结构")

#let series = series-registry.at(0)
#let nav = series-context(series, "docs/02-configuration/")

= 网站结构

#series-navbar("zh", nav)

这个双语模板主要由四层组成：

- `config.typ`：共享壳层、路由辅助函数、本地化标签以及全局控件。
- `content/en/`：英文内容树。
- `content/zh/`：中文内容树。
- `assets/`：中英文页面共用的静态资源与脚本。

== 默认资源角色

更新后的模板约定了几个共享资源的默认用途：

- `assets/logo-light.svg`：浅色主题下左上角品牌标识。
- `assets/logo-dark.svg`：深色主题下左上角品牌标识。
- `assets/profile.png`：中英文首页共用的头像。
- `assets/content-thumbnails/`：博客和文档卡片共用的缩略图。

== 核心配置

在 `config.typ` 中，你会把上游 Tufted 提供的原语封装成一个本地 `site-web()` 壳层，以及一个带 locale 的 `template()` 辅助函数。这个包装层负责每个页面共享的结构：品牌导航、样式表注入、预绘制主题引导、语言切换器、主题切换器以及页脚。

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

== 层级与继承

站点仍然沿用 Typst 的层级结构。每个语言树都有自己的根 `index.typ`，子页面只从最近的本地化父级导入，而不直接回到 `config.typ`。

- `content/en/docs/index.typ` 从 `content/en/index.typ` 导入
- `content/en/docs/01-quick-start/index.typ` 再从 `content/en/docs/index.typ` 导入
- 中文树在 `content/zh/` 下完全镜像这一结构

这样共享壳层可以集中维护，而每个语言树仍然拥有自己的文案和页面内容。

== 本地化分工

- 导航标签、主题菜单标签等共享 UI 文案放在 `config.typ` 中。
- 每个页面正文则放在 `content/en/` 和 `content/zh/` 各自的内容文件里。
- 两边必须保持相同 slug，这样语言切换器才能可靠地跳到对侧页面。

== GitHub Pages 路径

- 如果你发布到 `username.github.io` 这类用户或组织站点，请保持 `site-root = ""`。
- 如果你发布到项目站点，请把 `site-root` 设成 `"/your-repository-name"`，并且不要加结尾斜杠。

这样 `/en/` 与 `/zh/` 在 GitHub Pages 上也会保持正确解析。

#series-navbar("zh", nav)
