// docs 落地页展示的系列和独立笔记注册表。
// 添加系列:新建 docs/<slug>/series.typ,在这里 import 并加进 series-registry。
// 添加独立笔记:往 note-registry 里追加一条 entry。
// 卡片缩略图放在 assets/content-thumbnails/。

#let series-registry = (
  // my-series,
)

#let note-registry = (
  // (
  //   id: "<note-id>",
  //   title: "<笔记标题>",
  //   summary: "<一句话摘要>",
  //   route: "docs/<slug>/",
  //   thumbnail: "<thumbnail.svg>",
  //   label: "<卡片标签>",
  // ),
)
