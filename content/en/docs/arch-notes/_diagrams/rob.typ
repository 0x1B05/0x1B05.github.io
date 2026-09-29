#import "@preview/cetz:0.5.2"

#let rob-data-path() = cetz.canvas(length: .85cm, padding: .15, {
  import cetz.draw: *

  let node(name, a, b, label, fill, stroke) = {
    rect(a, b, name: name, radius: .1, fill: fill, stroke: stroke)
    content(name + ".center", align(center, label))
  }

  node(
    "cache",
    (0, 2.5),
    (2.5, 4.2),
    [
      #text(size: 8.5pt, weight: "bold")[Instruction] \
      #text(size: 8.5pt, weight: "bold")[cache] \
      #text(size: 7.5pt)[fetch / decode]
    ],
    rgb("#E8F0FE"),
    rgb("#1A41AC"),
  )
  node(
    "rf",
    (3.8, 2.5),
    (6.2, 4.2),
    [
      #text(size: 8.5pt, weight: "bold")[Register file] \
      #text(size: 7.5pt)[values and tags]
    ],
    rgb("#E8F0FE"),
    rgb("#1A41AC"),
  )
  node(
    "alu",
    (7.7, 3.9),
    (10.2, 4.6),
    [#text(size: 8pt)[Integer ALU]],
    rgb("#FFF0D9"),
    rgb("#B65C00"),
  )
  node(
    "mul",
    (7.7, 2.8),
    (10.2, 3.5),
    [#text(size: 8pt)[Multiplier / FP]],
    rgb("#FFF0D9"),
    rgb("#B65C00"),
  )
  node(
    "lsu",
    (7.7, 1.7),
    (10.2, 2.4),
    [#text(size: 8pt)[Load / store]],
    rgb("#FFF0D9"),
    rgb("#B65C00"),
  )
  node(
    "rob",
    (11.8, 1.4),
    (14.8, 4.9),
    [
      #text(size: 8.5pt, weight: "bold")[Reorder buffer] \
      #text(size: 8.5pt, weight: "bold")[(ROB)] \
      #text(size: 7.5pt)[speculative results]
    ],
    rgb("#DFF4E8"),
    rgb("#20744A"),
  )

  line("cache", "rf", mark: (end: ">"))
  content((3.0, 4.65), text(size: 8pt, [decode / rename]))

  line("rf.east", (6.9, 3.35))
  line((6.9, 3.35), (6.9, 4.25), (7.7, 4.25), mark: (end: ">"))
  line((6.9, 3.35), (6.9, 3.15), (7.7, 3.15), mark: (end: ">"))
  line((6.9, 3.35), (6.9, 2.05), (7.7, 2.05), mark: (end: ">"))

  line("alu.east", (11.8, 4.25), mark: (end: ">"))
  line("mul.east", (11.8, 3.15), mark: (end: ">"))
  line("lsu.east", (11.8, 2.05), mark: (end: ">"))
  content((11.1, 5.35), text(size: 8pt, fill: rgb("#B65C00"))[
    complete out of order
  ])

  line("rob.south", (13.3, .55), (5.0, .55), "rf.south", mark: (end: ">"))
  content((9.1, .9), text(size: 8pt, fill: rgb("#20744A"))[
    commit in program order
  ])
})

#let rob-bypass-paths() = cetz.canvas(length: .72cm, padding: .18, {
  import cetz.draw: *

  let box-node(name, a, b, body, fill, stroke) = {
    rect(a, b, name: name, radius: .08, fill: fill, stroke: stroke)
    content(name + ".center", align(center, body))
  }

  let blue = rgb("#001BFF")
  let red = rgb("#F01818")
  let blue-fill = rgb("#F4F7FF")
  let green-fill = rgb("#EAF7EE")
  let orange-fill = rgb("#FFF3E2")

  box-node(
    "cache",
    (0, 5.2),
    (2.7, 7.6),
    [#text(size: 8.5pt)[Instruction] \ #text(size: 8.5pt)[cache]],
    blue-fill,
    blue,
  )
  box-node(
    "rf",
    (5.0, 5.2),
    (7.8, 7.6),
    [#text(size: 8.5pt)[Register] \ #text(size: 8.5pt)[file]],
    blue-fill,
    blue,
  )
  box-node(
    "rob",
    (5.0, 1.7),
    (7.8, 4.2),
    [#text(size: 8.5pt)[Reorder] \ #text(size: 8.5pt)[Buffer]],
    green-fill,
    rgb("#20744A"),
  )

  // The selector is drawn as a trapezoid to emphasize value selection.
  line(
    (9.3, 4.35),
    (9.3, 7.0),
    (10.5, 6.55),
    (10.5, 4.8),
    close: true,
    fill: rgb("#F7F7F7"),
    stroke: rgb("#444444"),
  )

  box-node("fu1", (12.2, 6.25), (15.0, 7.25), [#text(size: 8.2pt)[Func Unit]], orange-fill, rgb("#444444"))
  box-node("fu2", (12.2, 4.8), (15.0, 5.8), [#text(size: 8.2pt)[Func Unit]], orange-fill, rgb("#444444"))
  box-node("fu3", (12.2, 3.35), (15.0, 4.35), [#text(size: 8.2pt)[Func Unit]], orange-fill, rgb("#444444"))

  // Fetch/decode and the content-addressable lookup into the ROB.
  line("cache.east", "rf.west", stroke: (dash: "dotted"), mark: (end: ">"))
  line((3.8, 6.4), (3.8, 3.0), (5.0, 3.0), stroke: (dash: "dotted"), mark: (end: ">"))

  content((3.35, 7.95), text(size: 8pt, fill: blue)[decode / rename])

  line((7.8, 6.4), (8.55, 6.4), (8.55, 6.45), (9.3, 6.45), mark: (end: ">"))
  line((7.8, 2.95), (8.55, 2.95), (8.55, 5.7), (9.3, 5.7), mark: (end: ">"))

  // Distribute the selected value to the functional units.
  line((10.5, 5.68), (11.2, 5.68))
  line((11.2, 5.68), (11.2, 6.75), (12.2, 6.75), mark: (end: ">"))
  line((11.2, 5.68), (11.2, 5.3), (12.2, 5.3), mark: (end: ">"))
  line((11.2, 5.68), (11.2, 3.85), (12.2, 3.85), mark: (end: ">"))

  // Normal result collection and the separate bypass loop.
  line("fu1.east", (16.2, 6.75), mark: (end: ">"))
  line("fu2.east", (16.2, 5.3), mark: (end: ">"))
  line("fu3.east", (16.2, 3.85), mark: (end: ">"))
  line((16.2, 6.75), (16.2, 1.0), (6.4, 1.0), "rob.south", mark: (end: ">"))

  line(
    (16.2, 3.0),
    (15.2, 3.0),
    (15.2, 1.7),
    (8.7, 1.7),
    (8.7, 4.7),
    (9.3, 4.7),
    stroke: red,
    mark: (end: ">"),
  )

  content((10.7, 8.35), [
    #text(size: 8.2pt, fill: blue)[Random Access Memory] \
    #text(size: 7.5pt, fill: red, weight: "bold")[(indexed with Register ID,] \
    #text(size: 7.5pt, fill: red)[which is the address of an entry)]
  ])
  content((0.15, 0.45), [
    #text(size: 7.5pt, fill: blue)[Content-Addressable Memory] \
    #text(size: 7.2pt, fill: red, weight: "bold")[(searched with register ID,] \
    #text(size: 7.2pt, fill: red)[which is part of the content of an entry)]
  ])
  content((12.05, 2.25), text(size: 8pt, fill: red)[bypass paths])
})

#let ooo-two-humps() = cetz.canvas(length: .72cm, padding: .14, {
  import cetz.draw: *

  let black = rgb("#1B1B1B")
  let red = rgb("#EF1B13")
  let blue = rgb("#001BFF")
  let pale = rgb("#FAFAFA")

  let box(a, b, body, width: 8pt) = {
    rect(a, b, radius: .03, fill: pale, stroke: black)
    content(((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2), align(center, text(size: width)[#body]))
  }

  let stage-cell(x, y) = {
    rect((x, y), (x + .62, y + .62), fill: white, stroke: black)
    content((x + .31, y + .31), align(center, text(size: 8pt)[E]))
  }

  let execution-row(y, count, label, ellipsis: false) = {
    for i in range(count) {
      stage-cell(5.15 + i * .68, y)
    }
    let end = 5.15 + count * .68
    let arrow-start = if ellipsis { end + .72 } else { end }
    if ellipsis {
      content((end + .3, y + .31), align(center, text(size: 9pt)[...]))
    }
    line((arrow-start, y + .31), (14.1, y + .31), mark: (end: ">"))
    content((end + 2, y), text(size: 8pt)[#label])
  }

  // Fetch and decode enter the first hump in program order.
  box((.25, 3.05), (.9, 3.72), [F])
  box((.9, 3.05), (1.55, 3.72), [D])
  line((1.55, 3.385), (2.25, 3.385), mark: (end: ">"))

  // Hump 1: a scheduling window holding instructions until operands are ready.
  rect((2.25, 1.05), (4.55, 5.85), fill: pale, stroke: black)
  content((3.4, 3.45), align(center, text(size: 8.5pt, fill: red, weight: "bold")[
    S \
    C \
    H \
    E \
    D \
    U \
    L \
    E
  ]))

  // Functional units execute ready instructions in dataflow order.
  line((4.55, 4.82), (5.15, 4.82), mark: (end: ">"))
  execution-row(4.43, 1, [Integer add])

  line((4.55, 3.74), (5.15, 3.74), mark: (end: ">"))
  execution-row(3.43, 4, [Integer mul])

  line((4.55, 2.66), (5.15, 2.66), mark: (end: ">"))
  execution-row(2.35, 8, [FP mul])

  line((4.55, 1.58), (5.15, 1.58), mark: (end: ">"))
  execution-row(1.27, 8, [Load/store], ellipsis: true)

  // Hump 2: results wait in the reorder buffer and retire in program order.
  rect((14.1, 1.05), (14.85, 5.85), fill: pale, stroke: black)
  content((14.475, 3.45), align(center, text(size: 8.5pt, fill: red, weight: "bold")[
    R \
    E \
    O \
    R \
    D \
    E \
    R
  ]))
  line((14.85, 3.45), (15.55, 3.45), mark: (end: ">"))
  box((15.55, 3.12), (16.2, 3.78), [W])

  // Result tags and values wake dependent instructions in the scheduler.
  line((14.475, 5.85), (14.475, 6.75), (3.15, 6.75), (3.15, 5.85), mark: (end: ">"))
  content((8.8, 7.03), align(center, text(size: 8pt)[TAG and VALUE Broadcast Bus]))

  content((1, .28), text(size: 9pt, fill: blue, weight: "bold")[in order])
  content((7.0, .28), text(size: 9pt, fill: blue, weight: "bold")[out of order])
  content((14.95, .28), text(size: 9pt, fill: blue, weight: "bold")[in order])
})
