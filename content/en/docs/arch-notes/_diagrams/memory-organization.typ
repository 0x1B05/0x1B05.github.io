#import "@preview/cetz:0.5.2"

#let _ink = rgb("#202124")
#let _muted = rgb("#68707A")
#let _rule = rgb("#CBD2DB")
#let _blue = rgb("#2457A6")
#let _blue-fill = rgb("#EAF1FB")
#let _orange = rgb("#B85C00")
#let _orange-fill = rgb("#FFF0DF")
#let _green = rgb("#16724A")
#let _green-fill = rgb("#E7F4ED")
#let _row-fill = rgb("#FFF0B8")

#let memory-array-organization() = cetz.canvas(length: .46cm, padding: .15, {
  import cetz.draw: *

  rect((6.0, 1.2), (17.2, 8.0), fill: white, stroke: _ink)
  for row in range(1, 4) {
    line((6.0, 1.2 + 1.7 * row), (17.2, 1.2 + 1.7 * row), stroke: _rule)
  }
  for col in range(1, 5) {
    line((6.0 + 2.24 * col, 1.2), (6.0 + 2.24 * col, 8.0), stroke: _rule)
  }
  rect((6.0, 4.6), (17.2, 6.3), fill: _row-fill, stroke: none)
  line((6.0, 4.6), (17.2, 4.6), stroke: _ink)
  line((6.0, 6.3), (17.2, 6.3), stroke: _ink)

  rect((1.9, 3.55), (4.75, 6.0), fill: _blue-fill, stroke: _blue)
  content((3.325, 4.775), align(center, text(size: 7pt, weight: "bold")[row #linebreak() decoder]))
  line((.2, 4.775), (1.9, 4.775), stroke: _blue, mark: (end: ">", scale: .55))
  content((1.62, 5.35), text(size: 5.7pt, weight: "bold", fill: _blue)[N-bit address], anchor: "east")
  line((4.75, 5.45), (6.0, 5.45), stroke: _orange, mark: (end: ">", scale: .55))
  content((5.8, 6.65), text(size: 5.4pt, fill: _orange)[one wordline], anchor: "east")

  for col in range(5) {
    let x = 7.12 + 2.24 * col
    line((x, 1.2), (x, .25), stroke: _green, mark: (end: ">"))
  }
  rect((6.0, -1.65), (17.2, -.1), fill: _green-fill, stroke: _green)
  content((11.6, -.875), align(center, text(size: 7pt, weight: "bold")[sense / column select -> M-bit data]))

  content((11.6, 8.65), align(center, text(size: 7pt, weight: "bold")[2^N rows × M columns]))
  content((18.0, 4.6), text(size: 5.8pt, fill: _muted)[selected row], anchor: "west")
  content((11.6, -2.3), align(center, text(size: 5.7pt, fill: _muted)[wordline selects cells; bitlines carry column values]))
})

#let sram-dram-addressing() = cetz.canvas(length: .39cm, padding: .15, {
  import cetz.draw: *

  let panel(a, b, title, subtitle) = {
    rect(a, b, radius: .08, fill: rgb("#FBFCFD"), stroke: _rule)
    content(((a.at(0) + b.at(0)) / 2, b.at(1) - .48), align(center, text(size: 6pt, weight: "bold")[#title]))
    content(((a.at(0) + b.at(0)) / 2, b.at(1) - 1.0), align(center, text(size: 4.6pt, fill: _muted)[#subtitle]))
  }

  let array(a, b) = {
    rect(a, b, fill: white, stroke: _ink)
    for row in range(1, 4) {
      line((a.at(0), a.at(1) + (b.at(1) - a.at(1)) * row / 4), (b.at(0), a.at(1) + (b.at(1) - a.at(1)) * row / 4), stroke: _rule)
    }
    for col in range(1, 5) {
      line((a.at(0) + (b.at(0) - a.at(0)) * col / 5, a.at(1)), (a.at(0) + (b.at(0) - a.at(0)) * col / 5, b.at(1)), stroke: _rule)
    }
  }

  panel((.2, .2), (16.6, 10.8), [SRAM address path], [row and column fields arrive together])
  panel((17.4, .2), (33.8, 10.8), [DRAM address path], [the same address pins are reused in two phases])

  // SRAM: all address bits are available at once and split internally.
  rect((.75, 5.55), (3.25, 7.65), radius: .05, fill: _blue-fill, stroke: _blue)
  content((2.0, 6.6), align(center, text(size: 5pt, weight: "bold")[n+m bit #linebreak() address]))
  line((3.25, 6.6), (3.9, 6.6), stroke: _blue)
  line((3.9, 6.6), (3.9, 7.55), (4.55, 7.55), stroke: _blue)
  line((3.9, 6.6), (3.9, 3.15), (8.5, 3.15), stroke: _green)
  content((4.22, 7.95), align(center, text(size: 4.5pt, weight: "bold", fill: _blue)[n]))
  content((5.65, 2.75), align(center, text(size: 4.5pt, weight: "bold", fill: _green)[column: m bits]))

  rect((4.55, 6.35), (7.35, 8.75), fill: _blue-fill, stroke: _blue)
  content((5.95, 7.55), align(center, text(size: 5pt, weight: "bold")[row #linebreak() decoder]))
  line((7.35, 7.55), (8.5, 7.55), stroke: _blue, mark: (end: ">", scale: .55))

  array((8.5, 4.15), (15.9, 8.75))
  content((12.2, 8.3), align(center, text(size: 5pt, weight: "bold")[bit-cell array]))
  content((12.2, 7.55), align(center, text(size: 4.3pt, fill: _blue)[2^n wordlines]))
  content((12.2, 6.45), align(center, text(size: 4.7pt)[2^n rows x 2^m columns]))

  rect((8.5, 2.15), (15.9, 3.45), fill: _green-fill, stroke: _green)
  content((12.2, 2.8), align(center, text(size: 4.8pt, weight: "bold")[sense amplifiers / column mux]))
  for x in (9.25, 10.7, 12.2, 13.7, 15.15) {
    line((x, 4.15), (x, 3.45), stroke: _green)
  }
  content((12.2, 3.78), align(center, text(size: 4.2pt, fill: _green)[2^m bitline pairs]))
  line((12.2, 2.15), (12.2, 1.25), stroke: _green, mark: (end: ">", scale: .55))
  content((12.75, 1.55), text(size: 4.5pt, weight: "bold", fill: _green)[data], anchor: "west")
  content((8.3, .62), align(center, text(size: 4.5pt, fill: _muted)[single address phase: decode row and select column in parallel]))

  // DRAM: row and column fields time-multiplex the external address pins.
  rect((17.95, 5.4), (20.65, 7.8), radius: .05, fill: _blue-fill, stroke: _blue)
  content((19.3, 6.6), align(center, text(size: 4.8pt, weight: "bold")[shared #linebreak() address pins]))
  content((19.3, 5.75), align(center, text(size: 4pt, fill: _muted)[max(n,m) bits]))

  line((20.65, 6.6), (21.15, 6.6), (21.15, 7.7), (21.7, 7.7), stroke: _blue)
  line((21.15, 6.6), (21.15, 3.05), (21.7, 3.05), stroke: _green)
  content((21.45, 8.45), text(size: 4.3pt, weight: "bold", fill: _blue)[row: n bits], anchor: "east")
  content((23.2, 2.55), text(size: 4.3pt, weight: "bold", fill: _green)[column: m bits], anchor: "west")

  rect((21.7, 7.0), (23.0, 8.4), fill: _blue-fill, stroke: _blue)
  content((22.35, 7.7), align(center, text(size: 4.3pt, weight: "bold")[RAS #linebreak() latch]))
  line((23.0, 7.7), (23.55, 7.7), stroke: _blue, mark: (end: ">", scale: .5))
  rect((23.55, 6.5), (26.0, 8.75), fill: _blue-fill, stroke: _blue)
  content((24.775, 7.625), align(center, text(size: 4.8pt, weight: "bold")[row #linebreak() decoder]))
  line((26.0, 7.7), (26.55, 7.7), stroke: _blue, mark: (end: ">", scale: .5))

  array((26.55, 4.15), (33.1, 8.75))
  content((29.825, 8.3), align(center, text(size: 5pt, weight: "bold")[bit-cell array]))
  content((29.825, 6.45), align(center, text(size: 4.7pt)[2^n rows x 2^m columns]))

  rect((21.7, 2.35), (23.0, 3.75), fill: _green-fill, stroke: _green)
  content((22.35, 3.05), align(center, text(size: 4.3pt, weight: "bold")[CAS #linebreak() latch]))
  line((23.0, 3.05), (26.55, 3.05), stroke: _green, mark: (end: ">", scale: .5))
  rect((26.55, 2.15), (33.1, 3.45), fill: _green-fill, stroke: _green)
  content((29.825, 2.8), align(center, text(size: 4.8pt, weight: "bold")[sense amplifiers / column mux]))
  for x in (27.2, 28.5, 29.825, 31.15, 32.45) {
    line((x, 4.15), (x, 3.45), stroke: _green)
  }
  content((29.825, 3.78), align(center, text(size: 4.2pt, fill: _green)[2^m sensed columns]))
  line((29.825, 2.15), (29.825, 1.25), stroke: _green, mark: (end: ">", scale: .55))
  content((30.35, 1.55), text(size: 4.5pt, weight: "bold", fill: _green)[data], anchor: "west")
  content((25.6, .62), align(center, text(size: 4.5pt, fill: _muted)[two address phases reduce package pin count]))
})

#let dram-system-hierarchy() = cetz.canvas(length: .39cm, padding: .14, {
  import cetz.draw: *

  let panel(a, b, number, title) = {
    rect(a, b, radius: .08, fill: rgb("#FBFCFD"), stroke: _rule)
    content(
      (a.at(0) + .45, b.at(1) - .45),
      text(size: 5.4pt, weight: "bold", fill: _blue)[#number],
      anchor: "west",
    )
    content(
      ((a.at(0) + b.at(0)) / 2, b.at(1) - .48),
      align(center, text(size: 6.1pt, weight: "bold")[#title]),
    )
  }

  let expand(a, b, label-at) = {
    line(a, b, stroke: (paint: _orange, thickness: .8pt), mark: (end: ">", scale: .55))
    content(label-at, align(center, text(size: 4.8pt, weight: "bold", fill: _orange)[expand]))
  }

  panel((.2, 9.0), (10.0, 16.6), [1], [Channel])
  panel((11.4, 9.0), (21.5, 16.6), [2], [DIMM])
  panel((22.9, 9.0), (33.2, 16.6), [3], [Rank])
  panel((.2, .2), (10.0, 7.8), [4], [DRAM chip])
  panel((11.4, .2), (21.5, 7.8), [5], [Bank])
  panel((22.9, .2), (33.2, 7.8), [6], [Subarray / mat])

  // 1. A controller drives one shared channel with multiple DIMMs attached.
  rect((.7, 11.5), (3.2, 14.0), radius: .06, fill: _blue-fill, stroke: _blue)
  content((1.95, 12.75), align(center, text(size: 4.7pt, weight: "bold")[memory #linebreak() controller]))
  line((3.2, 12.75), (3.8, 12.75), (3.8, 10.55), (9.85, 10.55), stroke: (paint: _blue, thickness: 1.05pt))
  content((6.65, 10.15), align(center, text(size: 4.6pt, fill: _blue)[shared channel bus]))
  for dimm in range(2) {
    let x = 5.2 + 2.55 * dimm
    let selected = dimm == 0
    rect(
      (x, 11.2),
      (x + 1.9, 14.8),
      radius: .05,
      fill: if selected { _orange-fill } else { white },
      stroke: if selected { (paint: _orange, thickness: 1pt) } else { _muted },
    )
    content((x + .95, 14.25), align(center, text(size: 4.8pt, weight: "bold")[DIMM #dimm]))
    for rank in range(2) {
      let y = 12.95 - 1.25 * rank
      rect((x + .25, y), (x + 1.65, y + .8), fill: _green-fill, stroke: _green)
      content((x + .95, y + .4), align(center, text(size: 4.1pt)[rank #rank]))
    }
    line((x + .95, 10.55), (x + .95, 11.2), stroke: _blue)
  }
  content((5.35, 9.55), align(center, text(size: 4.7pt, weight: "bold", fill: _blue)[channel I/O: 64b = 8B / transfer]))

  // 2. A DIMM contains one or more separately selected ranks.
  rect((12.25, 10.0), (20.65, 15.25), radius: .06, fill: white, stroke: _ink)
  content((16.45, 14.75), align(center, text(size: 5pt, fill: _muted)[module PCB]))
  for rank in range(2) {
    let x = 12.95 + 3.85 * rank
    let selected = rank == 0
    rect(
      (x, 11.0),
      (x + 3.15, 14.15),
      fill: if selected { _orange-fill } else { _green-fill },
      stroke: if selected { (paint: _orange, thickness: 1pt) } else { _green },
    )
    content((x + 1.575, 13.6), align(center, text(size: 4.8pt, weight: "bold")[rank #rank]))
    for chip in range(4) {
      rect((x + .25 + .68 * chip, 11.45), (x + .75 + .68 * chip, 12.75), fill: white, stroke: _muted)
    }
  }
  content((16.45, 9.55), align(center, text(size: 4.7pt, weight: "bold", fill: _green)[one selected rank: 64b / transfer]))

  // 3. All x8 chips in a rank receive the same command and act in lockstep.
  for chip in range(8) {
    let col = calc.rem(chip, 4)
    let row = calc.floor(chip / 4)
    let x = 23.6 + 2.2 * col
    let y = 13.2 - 2.15 * row
    rect(
      (x, y),
      (x + 1.65, y + 1.55),
      radius: .04,
      fill: _green-fill,
      stroke: if chip == 0 { (paint: _orange, thickness: 1pt) } else { _green },
    )
    content((x + .825, y + 1.05), align(center, text(size: 4.5pt, weight: "bold")[chip #chip]))
    content((x + .825, y + .42), align(center, text(size: 4.2pt, fill: _green)[x8]))
  }
  line((23.9, 10.2), (32.2, 10.2), stroke: (paint: _blue, thickness: 1pt))
  content((28.05, 9.55), align(center, text(size: 4.7pt, weight: "bold", fill: _green)[8 x8 chips = 64b = 8B / transfer]))

  // 4. A chip contains independently operable banks behind shared chip I/O.
  for bank in range(8) {
    let col = calc.rem(bank, 4)
    let row = calc.floor(bank / 4)
    let x = .9 + 2.15 * col
    let y = 4.4 - 1.85 * row
    rect(
      (x, y),
      (x + 1.65, y + 1.3),
      radius: .04,
      fill: if bank == 0 { _orange-fill } else { _blue-fill },
      stroke: if bank == 0 { (paint: _orange, thickness: 1pt) } else { _blue },
    )
    content((x + .825, y + .65), align(center, text(size: 4.4pt, weight: "bold")[bank #bank]))
  }
  line((1.25, 1.75), (9.2, 1.75), stroke: (paint: _blue, thickness: 1pt))
  content((5.225, .8), align(center, text(size: 4.7pt, weight: "bold", fill: _blue)[selected bank -> x8 chip I/O = 1B / transfer]))

  // 5. A bank is built from subarrays connected to a shared internal bus.
  for subarray in range(4) {
    let col = calc.rem(subarray, 2)
    let row = calc.floor(subarray / 2)
    let x = 12.2 + 4.35 * col
    let y = 4.5 - 2.15 * row
    rect(
      (x, y),
      (x + 3.45, y + 1.65),
      fill: if subarray == 0 { _orange-fill } else { white },
      stroke: if subarray == 0 { (paint: _orange, thickness: 1pt) } else { _muted },
    )
    content((x + 1.725, y + 1.1), align(center, text(size: 4.5pt, weight: "bold")[subarray #subarray]))
    rect((x + .25, y + .25), (x + 3.2, y + .62), fill: _green-fill, stroke: _green)
  }
  line((12.6, 1.6), (20.25, 1.6), stroke: (paint: _blue, thickness: 1pt))
  content((16.425, .8), align(center, text(size: 4.7pt, weight: "bold", fill: _orange)[ACTIVATE opens full row (example: 2KB)]))

  // 6. A subarray contains cells, a row decoder, and sense amplifiers.
  rect((25.8, 2.85), (32.15, 6.25), fill: white, stroke: _ink)
  for row in range(1, 4) {
    line((25.8, 2.85 + .85 * row), (32.15, 2.85 + .85 * row), stroke: _rule)
  }
  for col in range(1, 5) {
    line((25.8 + 1.27 * col, 2.85), (25.8 + 1.27 * col, 6.25), stroke: _rule)
  }
  rect((25.8, 4.55), (32.15, 5.4), fill: _row-fill, stroke: none)
  line((25.8, 4.55), (32.15, 4.55), stroke: _ink)
  line((25.8, 5.4), (32.15, 5.4), stroke: _ink)
  rect((23.5, 3.6), (25.25, 5.55), fill: _blue-fill, stroke: _blue)
  content((24.375, 4.575), align(center, text(size: 4.2pt, weight: "bold")[row dec.]))
  line((25.25, 4.975), (25.8, 4.975), stroke: _orange, mark: (end: ">", scale: .55))
  rect((25.8, 1.65), (32.15, 2.45), fill: _green-fill, stroke: _green)
  content((28.975, 2.05), align(center, text(size: 4.6pt, weight: "bold")[sense amplifiers / row buffer]))
  for x in (26.4, 27.7, 29.0, 30.3, 31.6) {
    line((x, 2.85), (x, 2.45), stroke: _green)
  }
  content((28.975, .8), align(center, text(size: 4.7pt, weight: "bold", fill: _green)[full local row -> sense-amp row buffer]))

  expand((10.0, 12.8), (11.4, 12.8), (10.7, 13.2))
  expand((21.5, 12.8), (22.9, 12.8), (22.2, 13.2))
  line((28.05, 9.0), (28.05, 8.4), (5.1, 8.4), (5.1, 7.8), stroke: (paint: _orange, thickness: .8pt), mark: (end: ">", scale: .55))
  content((16.55, 8.72), align(center, text(size: 4.8pt, weight: "bold", fill: _orange)[expand selected chip]))
  expand((10.0, 4.0), (11.4, 4.0), (10.7, 4.4))
  expand((21.5, 4.0), (22.9, 4.0), (22.2, 4.4))
})

#let rank-cache-block-transfer() = cetz.canvas(length: .39cm, padding: .15, {
  import cetz.draw: *

  // 1. Resolve the physical block to one channel, one DIMM, and one rank.
  content((2.75, 15.25), align(center, text(size: 5.8pt, weight: "bold")[physical address space]))
  rect((1.45, 11.15), (3.65, 14.55), fill: _orange-fill, stroke: _orange)
  for part in range(1, 8) {
    line((1.45, 11.15 + .425 * part), (3.65, 11.15 + .425 * part), stroke: _rule)
  }
  content((2.55, 12.85), align(center, text(size: 5.4pt, weight: "bold", fill: _orange)[64B block]))
  content((1.1, 14.55), text(size: 4.7pt, fill: _muted)[0x40], anchor: "east")
  content((1.1, 11.15), text(size: 4.7pt, fill: _muted)[0x00], anchor: "east")
  line((3.95, 12.85), (8.0, 12.85), stroke: (paint: _orange, thickness: .9pt), mark: (end: ">", scale: .55))
  content((5.975, 13.35), align(center, text(size: 5pt, weight: "bold", fill: _orange)[maps to]))
  content((5.975, 12.35), align(center, text(size: 4.7pt, fill: _muted)[8 x 8B]))

  rect((8.35, 10.55), (31.7, 15.75), radius: .08, fill: _blue-fill, stroke: _blue)
  content((20.025, 15.35), align(center, text(size: 5.8pt, weight: "bold", fill: _blue)[Channel 0]))
  rect((9.15, 11.1), (30.9, 14.85), radius: .06, fill: _green-fill, stroke: _green)
  content((20.025, 14.5), align(center, text(size: 5.5pt, weight: "bold", fill: _green)[DIMM 0]))
  rect((9.95, 11.65), (30.1, 14.05), radius: .05, fill: _orange-fill, stroke: _orange)
  content((20.025, 13.72), align(center, text(size: 5.2pt, weight: "bold", fill: _orange)[selected Rank 0]))
  for index in range(8) {
    let x = 10.45 + 2.38 * index
    rect((x, 12.0), (x + 1.72, 13.25), fill: white, stroke: _ink)
    content((x + .86, 12.8), align(center, text(size: 4.2pt, weight: "bold")[chip #index]))
    content((x + .86, 12.35), align(center, text(size: 3.8pt, fill: _blue)[8-bit I/O]))
  }
  content((20.025, 10.87), align(center, text(size: 4.6pt, fill: _muted)[only the selected rank drives the shared 64-bit channel]))

  // 2. Expand the selected rank: all chips execute the same command in lockstep.
  rect((.45, 3.95), (31.7, 9.75), radius: .08, fill: white, stroke: _orange)
  content((16.075, 9.4), align(center, text(size: 5.8pt, weight: "bold")[Rank 0 expanded: eight 8-bit-I/O chips operate in lockstep]))
  line((1.2, 8.65), (30.95, 8.65), stroke: (paint: _orange, thickness: .8pt))
  content((16.075, 8.95), align(center, text(size: 4.8pt, weight: "bold", fill: _orange)[same bank b, ACTIVATE row 0, and READ column k command]))

  for index in range(8) {
    let x = .95 + 3.78 * index
    let lo = 8 * index
    let hi = lo + 7
    rect((x, 5.15), (x + 3.15, 8.15), radius: .04, fill: _blue-fill, stroke: _blue)
    content((x + 1.575, 7.82), align(center, text(size: 4.4pt, weight: "bold")[chip #index]))
    content((x + 1.575, 7.43), align(center, text(size: 3.8pt, fill: _blue)[8-bit I/O]))
    rect((x + .22, 5.32), (x + 2.93, 7.18), radius: .03, fill: _green-fill, stroke: _green)
    content((x + 1.575, 6.96), align(center, text(size: 3.9pt, weight: "bold", fill: _green)[selected bank b]))
    rect((x + .38, 6.25), (x + 2.77, 6.68), fill: _row-fill, stroke: _orange)
    content((x + 1.575, 6.465), align(center, text(size: 3.7pt)[open row 0]))
    content((x + 1.575, 5.87), align(center, text(size: 3.9pt, weight: "bold", fill: _blue)[col k -> 8 bits]))
    content((x + 1.575, 5.5), align(center, text(size: 3.7pt, fill: _muted)[data #lo:#hi]))
    line((x + 1.575, 8.65), (x + 1.575, 8.15), stroke: _orange, mark: (end: ">", scale: .45))
    line((x + 1.575, 5.15), (x + 1.575, 4.62), stroke: _blue)
  }
  line((1.55, 4.62), (30.65, 4.62), stroke: (paint: _blue, thickness: 1pt))
  content((16.075, 4.25), align(center, text(size: 5pt, weight: "bold", fill: _blue)[64-bit data bus: 8 chips x 8 bits = 8B per I/O cycle]))

  // 3. Eight consecutive column reads assemble the cache block.
  line((16.075, 3.95), (16.075, 3.35), stroke: (paint: _orange, thickness: .9pt), mark: (end: ">", scale: .55))
  content((16.075, 3.05), align(center, text(size: 5.4pt, weight: "bold", fill: _orange)[eight sequential transfers assemble one 64B cache block]))
  for beat in range(8) {
    let x = .95 + 3.78 * beat
    rect((x, .45), (x + 3.15, 2.55), fill: if calc.even(beat) { _orange-fill } else { white }, stroke: _orange)
    content(
      (x + 1.575, 1.5),
      align(center, text(size: 4.5pt, weight: "bold")[I/O #str(beat + 1) #linebreak() READ col #beat #linebreak() 8B]),
    )
  }
  content((16.075, -.05), align(center, text(size: 4.8pt, fill: _muted)[columns 0 through 7 x 8B each = bytes 0 through 63]))
})

#let dram-bank-operation() = cetz.canvas(length: .47cm, padding: .15, {
  import cetz.draw: *

  rect((5.0, 5.35), (17.3, 10.1), fill: white, stroke: _ink)
  for row in range(1, 4) {
    line((5.0, 5.35 + 1.1875 * row), (17.3, 5.35 + 1.1875 * row), stroke: _rule)
  }
  rect((5.0, 7.725), (17.3, 8.9125), fill: _row-fill, stroke: none)
  line((5.0, 7.725), (17.3, 7.725), stroke: _ink)
  line((5.0, 8.9125), (17.3, 8.9125), stroke: _ink)
  content((11.15, 10.72), align(center, text(size: 6.4pt, weight: "bold")[DRAM cell array]))

  rect((1.25, 6.45), (3.8, 9.0), fill: _blue-fill, stroke: _blue)
  content((2.525, 7.725), align(center, text(size: 6pt, weight: "bold")[row decoder]))
  line((.1, 7.725), (1.25, 7.725), stroke: _blue, mark: (end: ">"))
  content((.1, 8.25), text(size: 5.7pt, weight: "bold", fill: _blue)[row address], anchor: "west")
  line((3.8, 8.32), (5.0, 8.32), stroke: _orange, mark: (end: ">"))

  rect((5.0, 3.55), (17.3, 4.75), fill: _orange-fill, stroke: _orange)
  content((11.15, 4.15), align(center, text(size: 6.3pt, weight: "bold")[sense amplifiers / row buffer]))
  for x in (6.1, 8.4, 10.7, 13.0, 15.3) {
    line((x, 5.35), (x, 4.75), stroke: _orange, mark: (end: ">"))
  }

  rect((7.4, 1.4), (14.9, 2.6), fill: _green-fill, stroke: _green)
  content((11.15, 2.0), align(center, text(size: 6.3pt, weight: "bold")[column mux / bank I/O]))
  line((11.15, 3.55), (11.15, 2.6), stroke: _green, mark: (end: ">"))
  line((4.3, 2.0), (7.4, 2.0), stroke: _green, mark: (end: ">"))
  content((4.3, 2.55), text(size: 5.7pt, weight: "bold", fill: _green)[column address], anchor: "west")
  line((11.15, 1.4), (11.15, .35), stroke: _green, mark: (end: ">"))
  content((11.75, .75), text(size: 5.7pt, weight: "bold", fill: _green)[data], anchor: "west")

  let command(y, number, title, detail, color, fill) = {
    rect((19.0, y - .72), (31.8, y + .72), radius: .08, fill: fill, stroke: color)
    content((19.65, y), align(center, text(size: 7pt, weight: "bold", fill: color)[#number]))
    content((21.0, y + .22), text(size: 6.1pt, weight: "bold")[#title], anchor: "west")
    content((21.0, y - .32), text(size: 5.1pt, fill: _muted)[#detail], anchor: "west")
  }

  command(8.65, [1], [ACTIVATE row], [copy selected row into row buffer], _blue, _blue-fill)
  command(5.75, [2], [READ / WRITE column], [select bytes from the open row], _green, _green-fill)
  command(2.85, [3], [PRECHARGE], [close row and prepare bitlines], _orange, _orange-fill)
})
