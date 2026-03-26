#import "../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": series-registry
#show: template.with(locale: "zh", route: "docs/01-quick-start/", title: "快速开始")

#let series = series-registry.at(0)
#let nav = series-context(series, "docs/01-quick-start/")

= 快速开始

#series-navbar("zh", nav)

== 安装

要从模板初始化一个新项目，请运行以下命令：

```sh
typst init @preview/tufted:0.1.1 my-website
cd my-website
```

== 构建

模板内置了一个 `Makefile`，会把双语内容树中的每个 `index.typ` 页面编译成 HTML：

```sh
make html
```

构建结果会写入 `_site/`，其中既包含根路径 `/` 的语言入口页，也包含镜像的 `/en/` 与 `/zh/` 分区。

== 本地预览

日常编辑时，建议直接使用内置预览目标：

```sh
make preview
```

默认端口是 `8000`。如果你要改端口，可以运行 `make preview PORT=9000`。

== 发布构建

当你准备为 GitHub Pages 生成发布产物时，运行：

```sh
make pages
```

这个命令会重新生成 HTML，并写入 `_site/.nojekyll`，让输出目录可以直接用于上传或部署。

#series-navbar("zh", nav)
