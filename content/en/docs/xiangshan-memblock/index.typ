#import "../index.typ": template, tufted, content-card, locale-url, series-begin
#import "./series.typ": xiangshan-memblock-series
#show: template.with(locale: "en", route: "docs/xiangshan-memblock/", title: "XiangShan MemBlock")

#let series = xiangshan-memblock-series

#let chapter-thumbnail(chapter) = if chapter.order == 1 {
  "research-log.svg"
} else if chapter.order == 2 {
  "reading-notes.svg"
} else if chapter.order == 3 {
  "prototype-notebook.svg"
} else if chapter.order == 4 {
  "workflow-guide.svg"
} else if chapter.order == 5 {
  "deployment-notes.svg"
} else if chapter.order == 6 {
  "sandbox-project.svg"
} else {
  "starter-series.svg"
}

= Reading XiangShan MemBlock: From the Memory Subsystem Map to Review Hotspots

This series reorganizes my XiangShan MemBlock reading notes into a path I can revisit while doing code review. The goal is not to paraphrase `MemBlock.scala` line by line. The goal is to keep one usable map in mind: what MemBlock coordinates, which boundaries matter first, and where the highest-risk control interactions keep showing up.

That means the series sits between two styles of writing. It is not a beginner-only introduction, because it keeps asking review questions. It is also not a raw notebook dump, because each chapter tries to turn one pile of observations into a stable reading handle.

== Recommended reading

Read the chapters in order the first time through. The sequence starts with the subsystem map, then moves through backend interfaces, load/store and LSQ structure, MMU and permission checks, cacheable versus uncacheable traffic, vector memory, and finally a review checklist that compresses the whole path into something actionable.

== Included Chapters

#html.div(class: "content-grid")[
  #for chapter in series.chapters [
    #content-card(
      locale-url("en", route: chapter.route),
      chapter-thumbnail(chapter),
      chapter.title,
      chapter.summary,
      label: "Chapter " + str(chapter.order),
    )
  ]
]

#series-begin("en", series.begin-route)
