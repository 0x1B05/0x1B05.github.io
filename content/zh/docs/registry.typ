#import "./linux-bringup/series.typ": linux-bringup-series
#import "./xiangshan-memblock/series.typ": xiangshan-memblock-series
#import "./arch-paper-reading/series.typ": arch-paper-reading-series

#let series-registry = (
  linux-bringup-series,
  xiangshan-memblock-series,
  arch-paper-reading-series,
)

#let note-registry = (
  (
    id: "bring-up-checklist",
    title: "Bring-up 检查清单",
    summary: "卡住时快速回看的清单：特权级假设、firmware handoff、memory map 和调试提示。",
    route: "docs/bring-up-checklist/",
    thumbnail: "sandbox-project.svg",
    label: "清单",
  ),
)
