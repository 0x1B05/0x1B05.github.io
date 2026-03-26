#let series-registry = (
  (
    id: "getting-started",
    title: "快速上手",
    summary: "从初始化双语模板开始，理解目录结构与共享壳层，最后完成可发布到 GitHub Pages 的构建。",
    route: "docs/getting-started/",
    thumbnail: "starter-series.svg",
    begin-route: "docs/01-quick-start/",
    chapters: (
      (
        id: "quick-start",
        title: "快速开始",
        summary: "从模板创建站点、本地构建，并学会预览生成出来的双语页面。",
        route: "docs/01-quick-start/",
        order: 1,
      ),
      (
        id: "configuration",
        title: "配置结构",
        summary: "替换共享资源，理解本地化内容树，以及共享壳层如何映射到你自己的内容。",
        route: "docs/02-configuration/",
        order: 2,
      ),
      (
        id: "styling",
        title: "样式设计",
        summary: "调整主题颜色、链接样式、间距节奏，以及控制站点外观的 CSS 覆写入口。",
        route: "docs/03-styling/",
        order: 3,
      ),
      (
        id: "deploy",
        title: "部署发布",
        summary: "准备 GitHub Pages 所需的静态产物，并理解完整的发布路径。",
        route: "docs/04-deploy/",
        order: 4,
      ),
    ),
  ),
)

#let reference-registry = (
  (
    id: "embedding-markdown",
    title: "嵌入 Markdown",
    summary: "当你想保留 Typst 模板控制力，同时又希望获得 Markdown 编写便利时，可以把两者混合使用。",
    route: "docs/embedding-markdown/",
    thumbnail: "sandbox-project.svg",
    label: "扩展",
  ),
)
