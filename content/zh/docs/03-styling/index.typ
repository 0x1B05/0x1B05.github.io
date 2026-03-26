#import "../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": series-registry
#show: template.with(locale: "zh", route: "docs/03-styling/", title: "样式设计")

#let series = series-registry.at(0)
#let nav = series-context(series, "docs/03-styling/")

= 样式设计

#series-navbar("zh", nav)

这个双语站点的视觉表现主要由 CSS 控制，另外 `config.typ` 中还包含少量共享壳层标记。

== 默认样式表

模板接受一个 `css` 参数，用来传入样式表 URL 或路径的数组。默认情况下会加载三份样式表：

```typst
#let page = site-web.with(
  css: (
    "https://cdnjs.cloudflare.com/ajax/libs/tufte-css/1.8.0/tufte.min.css",
    site-url("assets/tufted.css"),
    site-url("assets/custom.css"),
  ),
)
```

更新后的共享壳层保留了这个顺序，并通过 `site-url(...)` 处理本地资源路径，方便 GitHub Pages 项目站点附加仓库前缀。

== `assets/tufted.css` 负责什么

基础主题主要写在 `assets/tufted.css` 中，包括：

- light / dark / system 主题颜色
- `logo-light.svg` 与 `logo-dark.svg` 的品牌标识切换
- 语言切换器与主题切换器的布局
- 本地化首页的头像排版
- 博客与文档卡片样式
- 页脚与链接样式

== 主题与语言脚本

共享壳层的交互行为拆分为三个小脚本：

- `assets/theme-bootstrap.js` 在首屏渲染前应用保存的 light/dark 选择，减少闪烁。
- `assets/theme-switcher.js` 驱动可见的主题切换控件并保存偏好。
- `assets/language-switcher.js` 根据当前 `/en/` 或 `/zh/` 路径记录活跃语言。

根入口页还会额外加载 `assets/language-redirect.js`，用于把 `/` 自动跳转到偏好的语言前缀。

== 如何自定义样式

如果你想调整网站外观，直接修改 `assets/custom.css` 即可。由于它默认最后加载，你写的规则会覆盖共享壳层样式。

例如，修改链接颜色：

```css
a {
  color: #ff0000;
}
```

== 覆盖默认样式表

如果你希望完全替换默认样式表堆栈，也可以在 `config.typ` 中传入自己的列表：

```typst
#let template(body) = {
  let page = site-web.with(
    css: (site-url("assets/style.css"),),
  )

  page[#body]
}
```

#series-navbar("zh", nav)
