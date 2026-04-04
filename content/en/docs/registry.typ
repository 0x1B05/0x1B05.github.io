#import "./linux-bringup/series.typ": linux-bringup-series
#import "./xiangshan-memblock/series.typ": xiangshan-memblock-series

#let series-registry = (
  linux-bringup-series,
  xiangshan-memblock-series,
)

#let note-registry = (
  (
    id: "bring-up-checklist",
    title: "Bring-up Checklist Reference",
    summary: "A flat reference sheet for privilege assumptions, firmware handoff, memory map checks, and first-response debugging prompts.",
    route: "docs/bring-up-checklist/",
    thumbnail: "sandbox-project.svg",
    label: "Checklist",
  ),
)
