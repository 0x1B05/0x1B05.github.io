#import "../index.typ": template, tufted, content-card, locale-url
#show: template.with(locale: "en", route: "blog/", title: "Blog")

= Blog

Short essays, worked examples, and exploratory notes live here. The cards are written to explain what each entry is for before a reader clicks, which matters even more in a bilingual archive.

== Featured Reading

#html.div(class: "content-grid")[
  #content-card(
    locale-url("en", route: "blog/2025-10-30-normal-distribution/"),
    "research-log.svg",
    "The Normal Distribution",
    "A compact explainer on why the Gaussian distribution matters, where it appears, and what its core parameters mean in practice.",
    label: "Statistics",
  )
  #content-card(
    locale-url("en", route: "blog/2024-10-04-iterators-generators/"),
    "workflow-guide.svg",
    "Iterators vs Generators in Python",
    "A practical programming note comparing explicit iterator objects with generator-based control flow in day-to-day Python.",
    label: "Programming",
  )
  #content-card(
    locale-url("en", route: "blog/2025-04-16-monkeys-apes/"),
    "reading-notes.svg",
    "Monkeys vs Apes",
    "A lightweight reference-style example that shows how a friendly archive can stay structured and explanatory.",
    label: "Reference Piece",
  )
]

== How To Read This Section

- Look at the label above each card to understand whether the piece is a tutorial, note, or lightweight reference.
- Use this page as the archive front door; every card should explain the post before the reader opens it.
- Keep the English and Chinese summaries aligned so the language switcher always lands on equivalent pages.
