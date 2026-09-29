#import "../index.typ": (
  content-card, doc-toc, locale-url, series-begin, template,
)
#import "./series.typ": arch-notes-series
#show: template.with(locale: "en", route: "docs/arch-notes/", title: "Computer Architecture Notes")

#let series = arch-notes-series

= Computer Architecture Notes

#doc-toc("en")

Thematic notes on computer architecture, migrated from my DDCA / FoCA Spring 2025 material. The topics lean toward architecture rather than the course itself: simulation methodology, out-of-order and speculative execution, branch prediction, specialized execution models, multiprocessors and coherence, interconnects, the memory system, prefetching, and virtual memory.

== Chapters

#html.div(class: "content-grid")[
  #for chapter in series.chapters [
    #content-card(
      locale-url("en", route: chapter.route),
      "arch-notes.svg",
      chapter.title,
      chapter.summary,
      label: "Chapter " + str(chapter.order),
    )
  ]
]

#series-begin("en", series.begin-route)
