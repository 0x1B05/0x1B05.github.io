#import "../index.typ": template, tufted, content-card, locale-url
#show: template.with(locale: "en", route: "blog/", title: "Blog")

= Blog

This section is for the smaller pieces: reading notes, tool-focused reflections, and the short observations that come out of bring-up work before they are ready to become a structured docs page. I want these posts to keep some personal angle instead of pretending every topic is already a settled conclusion.

== Featured Reading

#html.div(class: "content-grid")[
  #content-card(
    locale-url("en", route: "blog/2025-10-30-normal-distribution/"),
    "research-log.svg",
    "Why OpenSBI Became Hard to Ignore",
    "A short note on how Linux bring-up turns M-mode firmware and the SBI boundary from background reading into an operational concern.",
    label: "Bring-up Note",
  )
  #content-card(
    locale-url("en", route: "blog/2024-10-04-iterators-generators/"),
    "workflow-guide.svg",
    "What LightSSS Seems to Optimize For",
    "A reading note on why lightweight snapshots matter when long RTL runs make full reruns and full-wave debugging too expensive.",
    label: "Tool Note",
  )
  #content-card(
    locale-url("en", route: "blog/2025-04-16-monkeys-apes/"),
    "reading-notes.svg",
    "Reading LibCheckpointAlpha as Infrastructure",
    "A short reflection on checkpoint restoration, bootloader linkage, and why this kind of plumbing changes how the whole stack is understood.",
    label: "Reading Note",
  )
]

== How To Read This Section

- Look at the label above each card to understand whether the piece is a tutorial, note, or lightweight reference.
- Use this page as the archive front door; every card should explain the post before the reader opens it.
- Keep the English and Chinese summaries aligned so the language switcher always lands on equivalent pages.
