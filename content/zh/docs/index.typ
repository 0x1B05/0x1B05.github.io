#import "../index.typ": *
#import "./registry.typ": series-registry, note-registry
#show: template.with(locale: "zh", route: "docs/", title: "文档")

= 文档

// TODO: 一句话介绍这个栏目。下面的系列和短文由 docs/registry.typ 渲染。

#docs-landing("zh", series-registry, note-registry)
