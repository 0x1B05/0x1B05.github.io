#import "../index.typ": (
  content-card, definition, example, locale-url, note, template, tip, tufted,
  warning,
)
#show: template.with(locale: "en", route: "blog/", title: "Blog")

= Blog

// TODO: one-sentence intro for this section.

#html.div(class: "content-grid")[
  // Add one content-card per post, newest first:
  //
  // #content-card(
  //   locale-url("en", route: "blog/<slug>/"),
  //   "<thumbnail.svg>",
  //   "<post title>",
  //   "<one-line summary>",
  //   label: "<card label>",
  // )
]
