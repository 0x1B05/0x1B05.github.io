#import "@preview/cetz:0.5.2" as cetz
#import cetz.draw: rect, content, line, on-layer

#let neutral = rgb("#85898F")
#let neutral-dark = rgb("#5F646B")
#let neutral-line = rgb("#AEB2B7")
#let panel-fill = rgb("#F5F6F7")

#let palette = (
  teal: (
    light: rgb("#C9DEE5"),
    mid: rgb("#83B2C1"),
    dark: rgb("#4F8FA5"),
  ),
  orange: (
    light: rgb("#F9D9C3"),
    mid: rgb("#F3B789"),
    dark: rgb("#EE995B"),
  ),
  coral: (
    light: rgb("#EDCBCB"),
    mid: rgb("#D98E8E"),
    dark: rgb("#C95B5B"),
  ),
  violet: (
    light: rgb("#DCD5E9"),
    mid: rgb("#B7A9D0"),
    dark: rgb("#8A74B5"),
  ),
)

#let default-values = (
  1, 3, 2, 2, 1, 3, 3, 2, 1, 2,
  3, 1, 2, 1, 3, 1, 2, 3, 2, 1,
)

#let tensor-block(
  pos,
  cols: 4,
  rows: 3,
  cell: 0.52,
  role: palette.teal,
  values: none,
  depth: 1,
  offset: (0.12, 0.10),
  name: none,
  symbol: [],
  shape: [],
) = {
  let (x, y) = pos
  let width = cols * cell
  let height = rows * cell
  let (dx, dy) = offset
  let tile-gap = 0.035
  let vals = if values == none { default-values } else { values }

  if depth > 1 {
    for sheet in range(1, depth).rev() {
      rect(
        (x + sheet * dx, y + sheet * dy),
        (x + width + sheet * dx, y + height + sheet * dy),
        fill: white,
        stroke: (paint: rgb("#C7CACD"), thickness: 0.55pt),
        radius: 0.045,
      )
    }
  }

  for row in range(rows) {
    for col in range(cols) {
      let index = row * cols + col
      let value = vals.at(calc.rem(index, vals.len()))
      let fill = if value == 0 {
        white
      } else if value == 1 {
        role.light
      } else if value == 2 {
        role.mid
      } else {
        role.dark
      }
      rect(
        (x + col * cell + tile-gap, y + row * cell + tile-gap),
        (x + (col + 1) * cell - tile-gap, y + (row + 1) * cell - tile-gap),
        fill: fill,
        stroke: none,
        radius: 0.035,
      )
    }
  }

  rect(
    (x, y),
    (x + width, y + height),
    fill: none,
    stroke: (paint: neutral-dark, thickness: 0.65pt),
    radius: 0.045,
    name: name,
  )
  content(
    (x + width / 2, y - 0.30),
    text(size: 9pt, fill: black, symbol),
  )
  content(
    (x + width / 2, y - 0.62),
    text(size: 7pt, fill: neutral, shape),
  )
}

#let operator(pos, body) = content(
  pos,
  text(size: 15pt, fill: neutral-dark, body),
)

#let flow-arrow(from, to, label: none, name: none) = on-layer(-1, {
  line(
    from,
    to,
    stroke: (paint: neutral-dark, thickness: 0.8pt),
    mark: (end: ">", scale: 0.75),
    name: name,
  )
  if label != none {
    content(
      (from, 50%, to),
      box(
        fill: white,
        inset: (x: 2.5pt, y: 1.5pt),
        text(size: 7pt, fill: neutral-dark, label),
      ),
      anchor: "south",
    )
  }
})

#let stage-heading(body) = text(
  size: 8pt,
  weight: "semibold",
  fill: neutral,
  body,
)

#let meaning-box(
  axes: none,
  objects: none,
  mechanism: none,
  width: 135mm,
) = {
  assert(axes != none, message: "meaning-box requires axes")
  assert(objects != none, message: "meaning-box requires objects")
  assert(mechanism != none, message: "meaning-box requires mechanism")
  box(
    width: width,
    fill: panel-fill,
    stroke: (paint: rgb("#D6D8DA"), thickness: 0.55pt),
    radius: 2pt,
    inset: (x: 9pt, y: 8pt),
    grid(
      columns: (18mm, 1fr),
      column-gutter: 8pt,
      row-gutter: 5pt,
      text(size: 8pt, weight: "semibold", fill: neutral-dark)[Axes],
      text(size: 8.5pt, fill: neutral-dark, axes),
      text(size: 8pt, weight: "semibold", fill: neutral-dark)[Objects],
      text(size: 8.5pt, fill: neutral-dark, objects),
      text(size: 8pt, weight: "semibold", fill: neutral-dark)[Mechanism],
      text(size: 8.5pt, fill: neutral-dark, mechanism),
    ),
  )
}

#let signature(body) = text(size: 7pt, fill: neutral, body)
