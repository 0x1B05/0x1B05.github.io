#import "../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": series-registry
#show: template.with(locale: "zh", route: "docs/04-deploy/", title: "部署发布")

#let series = series-registry.at(0)
#let nav = series-context(series, "docs/04-deploy/")

= 部署发布

#series-navbar("zh", nav)

你可以借助内置的 Make 目标和一个很小的工作流，把生成后的双语站点部署到 GitHub Pages。

== 本地预览

发布前先运行：

```sh
make preview
```

这个命令会重新生成 HTML，并通过 Python 的 HTTP server 提供 `_site/`，方便你在本地检查 `/`、`/en/` 和 `/zh/` 的实际效果。

== 发布构建

当你需要生成 GitHub Pages 产物时，运行：

```sh
make pages
```

它会把静态站点重新构建到 `_site/` 中，并写入 `_site/.nojekyll`，让这个目录可以直接用于 Pages 发布。

部署前请确认：

1. 如果仓库本身就是你的 Pages 域名，请保持 `config.typ` 中的 `site-root = ""`。
2. 如果你发布的是项目站点，请在执行 `make pages` 之前把 `site-root` 设为 `"/your-repository-name"`。

== GitHub Actions

在仓库中创建 `.github/workflows/deploy.yml`，内容如下：

```yaml
name: Deploy

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: typst-community/setup-typst@v4
      - run: make pages
      - uses: actions/configure-pages@v4
      - uses: actions/upload-pages-artifact@v4
        with:
          path: _site

  deploy:
    runs-on: ubuntu-latest
    needs: build
    permissions:
      pages: write
      id-token: write
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/deploy-pages@v4
        id: deployment
```

== 启用 GitHub Pages

1. 打开你的 GitHub 仓库。
2. 进入 _Settings_ → _Pages_。
3. 在 _Build and deployment_ 中把来源设置为 _GitHub Actions_。

之后，每次 push 到 `main` 时，都可以自动重建并发布 `_site/` 目录。

#series-navbar("zh", nav)
