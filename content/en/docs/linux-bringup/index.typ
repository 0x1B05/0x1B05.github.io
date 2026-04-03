#import "../index.typ": template, tufted, content-card, locale-url, series-begin
#import "./series.typ": linux-bringup-series
#show: template.with(locale: "en", route: "docs/linux-bringup/", title: "Linux Bring-up")

#let series = linux-bringup-series

#let chapter-thumbnail(chapter) = if chapter.order == 1 {
  "starter-series.svg"
} else if chapter.order == 2 {
  "prototype-notebook.svg"
} else if chapter.order == 3 {
  "workflow-guide.svg"
} else {
  "deployment-notes.svg"
}

= From RISC-V Privilege Levels to Linux Bring-up

This series is the path I am currently using to connect architectural reading with system bring-up work. Instead of explaining how to customize the site, it follows the layers that have become hard to ignore while trying to boot Linux: privilege levels, machine-mode firmware, tool choice, and the checklist I keep returning to when something stalls.

It is not written as if I have already solved every problem in that stack. The point is to keep the learning path explicit: what I need to understand, why each layer matters, and how the pieces fit together once the target is a real boot flow rather than an isolated toy program.

== Recommended reading

Read the chapters in order the first time through. The sequence moves from the privilege model, to OpenSBI, to tool roles, and finally to a practical checklist. Each chapter is short on purpose, so the series stays closer to a guided map than to a full textbook.

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
