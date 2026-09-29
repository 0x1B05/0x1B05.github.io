// Shared helpers for the arch-notes series: the pieces of the source notes'
// @local/notes package that the chapters actually use, kept with their
// original colors. Excluded from page compilation (leading underscore).

#let redt(content) = text(fill: rgb("#DC143C"), content)
#let bluet(content) = text(fill: rgb("#1E90FF"), content)
#let greent(content) = text(fill: rgb("#32CD32"), content)

// The HTML export silently drops text(fill: ...). ctext keeps the color as an
// inline style so colored emphasis survives (used for register names, RF/ROB
// headings, and status text in the source notes).
#let ctext(color, body, weight: "regular") = {
  let w = if weight == "bold" { "bold" } else { "normal" }
  html.elem("span", attrs: (style: "color: " + color + "; font-weight: " + w), body)
}

// Two narrow tables side by side (stacks on narrow screens).
#let table-pair(left, right) = html.div(class: "table-pair")[
  #html.div[#left]
  #html.div[#right]
]
