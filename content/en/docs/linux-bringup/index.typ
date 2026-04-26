#import "../index.typ": template, tufted, content-card, locale-url, series-begin, doc-toc
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

#doc-toc("en")

This series is the path I am using to connect architectural reading with system bring-up work. The layers that keep showing up are privilege levels, machine-mode firmware, tool choice, and the checks I return to when the boot flow stalls.

I have not figured out the whole stack. These notes keep the parts I currently need most: why each layer shows up, and how it connects to the next failure I am likely to see.

== Recommended reading

Read the chapters in order the first time through: privilege model, OpenSBI, tool roles, then the bring-up checklist. The chapters are short because I first want the path to stay visible.

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
