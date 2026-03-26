#import "../index.typ": template, tufted, content-card, locale-url, series-begin
#import "../series.typ": series-registry
#show: template.with(locale: "en", route: "docs/getting-started/", title: "Getting Started")

#let series = series-registry.at(0)

#let chapter-thumbnail(chapter) = if chapter.order == 1 {
  "starter-series.svg"
} else if chapter.order == 2 {
  "prototype-notebook.svg"
} else if chapter.order == 3 {
  "workflow-guide.svg"
} else {
  "deployment-notes.svg"
}

= Getting Started

This series walks through the smallest path from a fresh Tufted checkout to a bilingual site you can preview locally and publish without reshaping the template.

It is for people who want to replace the demo content with their own material while keeping the shared shell, mirrored routes, and deployment workflow understandable from the start.

== Recommended reading

Read the chapters in order the first time through. Each one assumes the previous step is already in place, so the sequence moves from setup to structure, then styling, and finally deployment.

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
