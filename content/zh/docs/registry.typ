#import "./linux-bringup/series.typ": linux-bringup-series

#let series-registry = (
  linux-bringup-series,
)

#let note-registry = (
  (
    id: "bring-up-checklist",
    title: "Bring-up 检查清单参考",
    summary: "一页更扁平的参考清单，用来快速回看特权级假设、firmware handoff、memory map 和调试提示。",
    route: "docs/bring-up-checklist/",
    thumbnail: "sandbox-project.svg",
    label: "清单",
  ),
)
