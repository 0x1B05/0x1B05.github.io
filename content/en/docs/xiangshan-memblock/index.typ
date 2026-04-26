#import "../index.typ": template, tufted, content-card, locale-url, series-begin, doc-toc
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

#doc-toc("en")

This series is the path I use when revisiting XiangShan MemBlock. It does not paraphrase `MemBlock.scala` line by line. It starts with the places where I am most likely to get lost: what MemBlock coordinates, which interfaces to read first, and which control interactions deserve extra attention.

Each chapter keeps a review angle, but the first goal is still to understand the structure. The map and the paths need to be in place before the individual ports and control signals make sense.

== Recommended reading

Read the chapters in order the first time through: subsystem map, backend interfaces, load/store and LSQ structure, MMU and permission checks, cacheable versus uncacheable traffic, vector memory, then the review checklist.

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
