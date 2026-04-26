#import "../index.typ": template, tufted, content-card, locale-url
#show: template.with(locale: "en", route: "blog/", title: "Blog")

= Blog

This section is for notes that are not ready, or not worth, turning into full docs pages: things I noticed while reading tool documentation, problems that came up during bring-up, and judgments that felt worth writing down at the time.

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

== Archive Notes

Not every post here is a tutorial. Some are just my read of a document after one pass; some come from debugging notes. The title and label should make clear whether the post is about a tool, a bring-up problem, or a project I was reading through.
