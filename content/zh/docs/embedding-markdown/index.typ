#import "../index.typ": template, tufted
#import "@preview/cmarker:0.1.8"
#import "@preview/mitex:0.2.6": mitex
#show: template.with(locale: "zh", route: "docs/embedding-markdown/", title: "嵌入 Markdown")

= 嵌入 Markdown

你可以借助 `cmarker` 把 Markdown 内容嵌入到 Typst 文档中。当你已经有一篇 Markdown 文章，但仍然想把它放进双语 Typst 站点中统一渲染时，这种方式会非常方便。

```typst
#import "@preview/cmarker:0.1.8"
#import "@preview/mitex:0.2.6": mitex

#let md-content = read("tufted-titmouse.md")

#let def-dict = (
  image: (source, alt: none, format: auto) => figure(image(
    source,
    alt: alt,
    format: format,
  )),
)

#cmarker.render(md-content, math: mitex, scope: def-dict)
```

下面的内容就是从当前目录中的 Markdown 文件渲染出来的：

#let md-content = read("tufted-titmouse.md")

#let def-dict = (
  image: (source, alt: none, format: auto) => figure(image(
    source,
    alt: alt,
    format: format,
  )),
)

#cmarker.render(md-content, math: mitex, scope: def-dict)
