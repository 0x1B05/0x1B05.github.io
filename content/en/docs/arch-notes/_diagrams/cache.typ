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
#let _red = rgb("#B42318")
#let _red-fill = rgb("#FDECEC")

#let cache-placement-organizations() = cetz.canvas(length: .5cm, padding: .15, {
  import cetz.draw: *

  let panel(x, title, subtitle) = {
    rect((x, .25), (x + 9.65, 12.55), radius: .08, fill: rgb("#FBFCFD"), stroke: _rule)
    content((x + 4.825, 11.95), align(center, text(size: 6.4pt, weight: "bold", fill: _blue)[#title]))
    content((x + 4.825, 11.25), align(center, text(size: 5.1pt, fill: _muted)[#subtitle]))
  }

  let source-block(x) = {
    content((x + 1.35, 8.45), align(center, text(size: 5pt, fill: _muted)[main memory]))
    rect((x + .35, 6.55), (x + 2.35, 7.95), radius: .04, fill: _green-fill, stroke: _green)
    content((x + 1.35, 7.25), align(center, text(size: 6pt, weight: "bold", fill: _green)[$q = 5$]))
  }

  let address-field(x1, x2, label, bits, fill-color, line-color) = {
    rect((x1, 9.15), (x2, 10.15), fill: fill-color, stroke: line-color)
    content(((x1 + x2) / 2, 9.82), align(center, text(size: 3.9pt, fill: line-color)[#label]))
    content(((x1 + x2) / 2, 9.43), align(center, text(size: 5.1pt, weight: "bold")[#bits]))
  }

  panel(.0, [Direct-mapped], [4 sets x 1 way])
  panel(10.15, [2-way set-associative], [2 sets x 2 ways])
  panel(20.3, [Fully associative], [1 set x 4 ways])

  for x in (0.0, 10.15, 20.3) {
    content((x + 4.825, 10.65), align(center, text(size: 4.8pt, weight: "bold")[same byte address $a = 10110_2$]))
  }

  address-field(.45, 3.35, [tag], [1], _blue-fill, _blue)
  address-field(3.35, 6.2, [index], [01], _orange-fill, _orange)
  address-field(6.2, 9.2, [offset], [10], _green-fill, _green)

  address-field(10.6, 14.2, [tag], [10], _blue-fill, _blue)
  address-field(14.2, 16.35, [index], [1], _orange-fill, _orange)
  address-field(16.35, 19.35, [offset], [10], _green-fill, _green)

  address-field(20.75, 26.5, [tag], [101], _blue-fill, _blue)
  address-field(26.5, 29.5, [offset], [10], _green-fill, _green)

  source-block(.0)
  source-block(10.15)
  source-block(20.3)

  // Direct-mapped: q = 5 selects exactly line 1.
  for i in range(4) {
    let y = 6.0 - i * 1.25
    rect((4.45, y), (8.95, y + 1.05), fill: if i == 1 { _orange-fill } else { white }, stroke: if i == 1 { _orange } else { _rule })
    content((6.7, y + .525), align(center, text(size: 5.3pt, weight: if i == 1 { "bold" } else { "regular" })[line #i]))
  }
  line((2.35, 7.25), (3.25, 7.25), (3.25, 5.275), (4.45, 5.275), stroke: _orange, mark: (end: ">", scale: .48))
  content((6.7, 7.45), align(center, text(size: 5.1pt, weight: "bold", fill: _orange)[$5 mod 4 = 1$]))
  content((4.825, 1.0), align(center, text(size: 5.2pt, weight: "bold", fill: _orange)[1 legal candidate]))

  // Set-associative: the index selects set 1; either way is legal.
  content((16.85, 7.45), align(center, text(size: 5.1pt, weight: "bold", fill: _orange)[$5 mod 2 = 1$]))
  content((16.25, 6.55), align(center, text(size: 4.8pt, fill: _muted)[way 0]))
  content((18.25, 6.55), align(center, text(size: 4.8pt, fill: _muted)[way 1]))
  for set-idx in range(2) {
    let y = 4.2 - set-idx * 1.65
    content((13.15, y + .6), align(right, text(size: 5pt, weight: "bold")[set #set-idx]))
    for way in range(2) {
      let x = 14.45 + way * 2.4
      rect((x, y), (x + 2.15, y + 1.2), fill: if set-idx == 1 { _orange-fill } else { white }, stroke: if set-idx == 1 { _orange } else { _rule })
      content((x + 1.075, y + .6), align(center, text(size: 5pt, weight: if set-idx == 1 { "bold" } else { "regular" })[entry]))
    }
  }
  line((12.5, 7.25), (13.75, 7.25), (13.75, 4.0), (17.925, 4.0), stroke: _orange)
  for x in (15.525, 17.925) {
    line((x, 4.0), (x, 3.75), stroke: _orange, mark: (end: ">", scale: .45))
  }
  content((14.975, 1.0), align(center, text(size: 5.2pt, weight: "bold", fill: _orange)[2 legal candidates in set 1]))

  // Fully associative: there is no index restriction; all entries are candidates.
  content((27.0, 7.45), align(center, text(size: 5.1pt, weight: "bold", fill: _orange)[no set-index restriction]))
  for i in range(4) {
    let y = 6.0 - i * 1.25
    rect((24.75, y), (29.25, y + 1.05), fill: _orange-fill, stroke: _orange)
    content((27.0, y + .525), align(center, text(size: 5.3pt, weight: "bold")[entry #i]))
  }
  line((22.65, 7.25), (23.75, 7.25), (23.75, 2.775), stroke: _orange)
  for y in (6.525, 5.275, 4.025, 2.775) {
    line((23.75, y), (24.75, y), stroke: _orange, mark: (end: ">", scale: .45))
  }
  content((25.125, 1.0), align(center, text(size: 5.2pt, weight: "bold", fill: _orange)[4 legal candidates]))

  rect((10.2, -.7), (20.1, .0), fill: _orange-fill, stroke: _orange)
  content((15.15, -.35), align(center, text(size: 4.9pt, weight: "bold", fill: _orange)[orange cells are alternatives, not duplicate copies]))
})

#let cache-parallel-serial-access() = cetz.canvas(length: .47cm, padding: .15, {
  import cetz.draw: *

  let panel(x1, x2, title, subtitle) = {
    rect((x1, 1.0), (x2, 10.9), radius: .08, fill: rgb("#FBFCFD"), stroke: _rule)
    content(((x1 + x2) / 2, 10.25), align(center, text(size: 6.5pt, weight: "bold", fill: _blue)[#title]))
    content(((x1 + x2) / 2, 9.55), align(center, text(size: 4.9pt, fill: _muted)[#subtitle]))
  }

  let block(a, b, body, fill-color, line-color) = {
    rect(a, b, radius: .05, fill: fill-color, stroke: line-color)
    content(((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2), align(center, text(size: 5pt, weight: "bold", fill: line-color)[#body]))
  }

  panel(.0, 15.0, [Parallel tag/data access], [common in a small, latency-critical L1])
  panel(15.7, 30.7, [Serial tag-then-data access], [common in larger L2 and LLC structures])

  // Parallel path: the indexed tag and every candidate data way start together.
  block((.55, 5.45), (2.85, 7.05), [address\ tag + index], white, _ink)
  block((4.0, 7.05), (7.25, 8.5), [read N tags], _blue-fill, _blue)
  block((4.0, 4.05), (7.25, 5.5), [read N data ways], _green-fill, _green)
  block((8.3, 7.05), (11.55, 8.5), [N tag compares], _orange-fill, _orange)
  block((8.3, 4.05), (11.55, 5.5), [matching-way mux], _orange-fill, _orange)
  block((12.35, 4.05), (14.45, 5.5), [hit data], _green-fill, _green)

  line((2.85, 6.25), (3.45, 6.25), stroke: _ink)
  line((3.45, 6.25), (3.45, 7.775), (4.0, 7.775), stroke: _blue, mark: (end: ">", scale: .45))
  line((3.45, 6.25), (3.45, 4.775), (4.0, 4.775), stroke: _green, mark: (end: ">", scale: .45))
  line((7.25, 7.775), (8.3, 7.775), stroke: _blue, mark: (end: ">", scale: .45))
  line((7.25, 4.775), (8.3, 4.775), stroke: _green, mark: (end: ">", scale: .45))
  line((9.925, 7.05), (9.925, 5.5), stroke: _orange, mark: (end: ">", scale: .45))
  content((10.35, 6.25), text(size: 4.4pt, weight: "bold", fill: _orange)[way select], anchor: "west")
  line((11.55, 4.775), (12.35, 4.775), stroke: _green, mark: (end: ">", scale: .45))
  content((7.5, 1.55), align(center, text(size: 5pt, weight: "bold", fill: _green)[lower hit latency; all candidate data ways are read]))

  // Serial path: tag lookup produces way k before the selected data way can be read.
  content((22.85, 8.95), align(center, text(size: 4.8pt, weight: "bold", fill: _blue)[phase 1: tag lookup and way selection]))
  block((16.25, 7.0), (18.65, 8.4), [address\ tag + index], white, _ink)
  block((19.45, 7.0), (22.45, 8.4), [read N tags], _blue-fill, _blue)
  block((23.25, 7.0), (26.35, 8.4), [N tag compares], _orange-fill, _orange)
  block((27.2, 7.0), (29.85, 8.4), [matching way k], _orange-fill, _orange)
  line((18.65, 7.7), (19.45, 7.7), stroke: _blue, mark: (end: ">", scale: .45))
  line((22.45, 7.7), (23.25, 7.7), stroke: _blue, mark: (end: ">", scale: .45))
  line((26.35, 7.7), (27.2, 7.7), stroke: _orange, mark: (end: ">", scale: .45))

  content((24.1, 4.7), text(size: 4.8pt, weight: "bold", fill: _green)[phase 2: selected-way data read], anchor: "east")
  block((21.0, 2.65), (25.6, 4.05), [read only data way k], _green-fill, _green)
  block((26.7, 2.65), (29.85, 4.05), [hit data], _green-fill, _green)
  line((17.45, 7.0), (17.45, 3.35), (21.0, 3.35), stroke: _green, mark: (end: ">", scale: .45))
  content((18.0, 3.7), text(size: 4.4pt, weight: "bold", fill: _green)[set index], anchor: "west")
  line((28.525, 7.0), (28.525, 5.3), (25.1, 5.3), (25.1, 4.05), stroke: _orange, mark: (end: ">", scale: .45))
  line((25.6, 3.35), (26.7, 3.35), stroke: _green, mark: (end: ">", scale: .45))
  content((23.2, 1.55), align(center, text(size: 5pt, weight: "bold", fill: _green)[lower data-array energy; one extra dependent lookup step]))
})

#let cache-hit-data-path() = cetz.canvas(length: .39cm, padding: .15, {
  import cetz.draw: *

  content((15.7, 14.75), align(center, text(size: 6.2pt, weight: "bold")[A-bit byte address]))
  rect((1.0, 12.65), (30.4, 14.25), fill: white, stroke: _ink)
  rect((1.0, 12.65), (15.0, 14.25), fill: _blue-fill, stroke: _blue)
  rect((15.0, 12.65), (23.7, 14.25), fill: _orange-fill, stroke: _orange)
  rect((23.7, 12.65), (30.4, 14.25), fill: _green-fill, stroke: _green)
  content((8.0, 13.45), align(center, text(size: 5.5pt, weight: "bold", fill: _blue)[tag: A - log2(S) - log2(b) bits]))
  content((19.35, 13.45), align(center, text(size: 5.5pt, weight: "bold", fill: _orange)[set index: log2(S) bits]))
  content((27.05, 13.45), align(center, text(size: 5.5pt, weight: "bold", fill: _green)[block offset: log2(b) bits]))

  // One indexed row returns metadata and data from all candidate ways.
  rect((1.5, 7.65), (29.8, 11.55), radius: .08, fill: rgb("#FBFCFD"), stroke: _rule)
  content((15.65, 11.12), align(center, text(size: 5.2pt, weight: "bold")[selected set: N ways read in parallel]))
  line((19.35, 12.65), (19.35, 11.55), stroke: _orange, mark: (end: ">", scale: .5))

  let way(x, number) = {
    rect((x, 8.15), (x + 7.2, 10.65), radius: .05, fill: white, stroke: _rule)
    content((x + 3.6, 10.3), align(center, text(size: 4.8pt, weight: "bold")[way #number]))
    rect((x + .3, 8.5), (x + 2.65, 9.9), fill: _blue-fill, stroke: _blue)
    content((x + 1.475, 9.2), align(center, text(size: 4.5pt, weight: "bold")[V + tag]))
    rect((x + 2.95, 8.5), (x + 6.9, 9.9), fill: _green-fill, stroke: _green)
    content((x + 4.925, 9.2), align(center, text(size: 4.5pt, weight: "bold")[data block]))
  }

  way(2.0, [0])
  way(9.55, [1])
  content((18.0, 9.2), align(center, text(size: 9pt, fill: _muted)[...]))
  way(20.0, [N-1])

  // Separate comparison and data-selection stages keep wires readable.
  rect((2.1, 4.85), (13.7, 6.65), radius: .06, fill: _blue-fill, stroke: _blue)
  content((7.9, 5.75), align(center, text(size: 5pt, weight: "bold")[N x (valid && tag compare)]))
  for x in (3.475, 11.025, 21.475) {
    line((x, 8.5), (x, 7.2), (7.9, 7.2), (7.9, 6.65), stroke: _blue, mark: (end: ">", scale: .42))
  }
  line((8.0, 12.65), (.55, 12.65), (.55, 5.75), (2.1, 5.75), stroke: _blue, mark: (end: ">", scale: .5))
  content((.8, 6.2), text(size: 4.5pt, weight: "bold", fill: _blue)[address tag], anchor: "west")

  rect((18.0, 4.85), (29.1, 6.65), radius: .06, fill: _orange-fill, stroke: _orange)
  content((23.55, 5.75), align(center, text(size: 5pt, weight: "bold")[matching-way data mux]))
  for x in (6.925, 14.475, 24.925) {
    line((x, 8.5), (x, 7.45), (23.55, 7.45), (23.55, 6.65), stroke: _green, mark: (end: ">", scale: .42))
  }
  line((13.7, 5.75), (18.0, 5.75), stroke: _orange, mark: (end: ">", scale: .5))
  content((15.85, 6.2), align(center, text(size: 4.4pt, weight: "bold", fill: _orange)[hit vector]))

  // A miss leaves through a separate red path; a hit continues to offset selection.
  rect((1.5, 1.8), (10.0, 3.25), radius: .06, fill: _red-fill, stroke: _red)
  content((5.75, 2.525), align(center, text(size: 4.8pt, weight: "bold", fill: _red)[no matching valid tag -> miss handling]))
  line((7.9, 4.85), (7.9, 3.25), stroke: _red, mark: (end: ">", scale: .5))

  rect((17.5, 1.8), (27.5, 3.45), radius: .06, fill: _green-fill, stroke: _green)
  content((22.5, 2.625), align(center, text(size: 5pt, weight: "bold")[word / byte select]))
  line((23.55, 4.85), (23.55, 3.45), stroke: _green, mark: (end: ">", scale: .5))
  line((27.05, 12.65), (30.65, 12.65), (30.65, 2.625), (27.5, 2.625), stroke: _green, mark: (end: ">", scale: .5))
  line((22.5, 1.8), (22.5, .65), stroke: _green, mark: (end: ">", scale: .55))
  content((23.05, .95), text(size: 5pt, weight: "bold", fill: _green)[requested data], anchor: "west")
})

#let cache-mlp-replacement() = cetz.canvas(length: .39cm, padding: .16, {
  import cetz.draw: *

  let accesses = ("P4", "P3", "P2", "P1", "P1", "P2", "P3", "P4", "S1", "S2", "S3")
  let opt-outcomes = ("H", "H", "H", "M", "H", "H", "H", "H", "M", "M", "M")
  let mlp-outcomes = ("H", "M", "M", "M", "H", "M", "M", "M", "H", "H", "H")
  let trace-x = 5.0
  let cell-width = 1.35
  let cell-gap = .08

  let access-x(i) = {
    (trace-x + i * (cell-width + cell-gap) + (if i >= 4 { .34 } else { 0 }) + (if i >= 8 { .34 } else { 0 }))
  }

  let group-1 = (access-x(0), access-x(3) + cell-width)
  let group-2 = (access-x(4), access-x(7) + cell-width)
  let serial = (access-x(8), access-x(10) + cell-width)

  let cache-state(x, y, blocks, label) = {
    content((x + 2.24, y + 1.18), align(center, text(size: 4.4pt, weight: "bold", fill: _muted)[#label]))
    for i in range(4) {
      let block = blocks.at(i)
      let is-parallel = block.starts-with("P")
      rect(
        (x + i * 1.12, y),
        (x + (i + 1) * 1.12, y + .88),
        fill: if is-parallel { _blue-fill } else { _orange-fill },
        stroke: if is-parallel { _blue } else { _orange },
      )
      content(
        (x + (i + .5) * 1.12, y + .44),
        align(center, text(size: 5pt, weight: "bold", fill: if is-parallel { _blue } else { _orange })[#block]),
      )
    }
  }

  let outcome-row(y, outcomes) = {
    for i in range(accesses.len()) {
      let result = outcomes.at(i)
      let color = if result == "H" { _green } else { _red }
      content(
        (access-x(i) + cell-width / 2, y),
        align(center, text(size: 5.7pt, weight: "bold", fill: color)[#result]),
      )
    }
  }

  let interval(x1, x2, y, body, stalled: true) = {
    let fill-color = if stalled { _red-fill } else { _green-fill }
    let line-color = if stalled { _red } else { _green }
    rect(
      (x1, y),
      (x2, y + .82),
      radius: .04,
      fill: fill-color,
      stroke: (paint: line-color, thickness: .72pt),
    )
    content(
      ((x1 + x2) / 2, y + .41),
      align(center, text(size: 4.3pt, weight: "bold", fill: line-color)[#body]),
    )
  }

  let result-box(y, misses, batches, batch-color, note) = {
    rect((22.15, y), (31.65, y + 3.05), radius: .06, fill: rgb("#FBFCFD"), stroke: _rule)
    content((26.9, y + 2.55), align(center, text(size: 4.5pt, weight: "bold", fill: _muted)[result]))
    content((26.9, y + 1.88), align(center, text(size: 6.1pt, weight: "bold", fill: _red)[#misses misses]))
    content((26.9, y + 1.15), align(center, text(size: 5.7pt, weight: "bold", fill: batch-color)[#batches exposed stall batches]))
    content((26.9, y + .42), align(center, text(size: 4.4pt, fill: _muted)[#note]))
  }

  // Shared steady-state access stream.
  content(
    (16.0, 19.45),
    align(center, text(size: 6.2pt, weight: "bold")[4-block fully associative cache; steady-state loop (warm-up omitted)]),
  )
  content((.35, 17.65), text(size: 5.4pt, weight: "bold")[access stream], anchor: "west")

  for i in range(accesses.len()) {
    let block = accesses.at(i)
    let is-parallel = i < 8
    let x = access-x(i)
    rect(
      (x, 17.05),
      (x + cell-width, 18.15),
      radius: .04,
      fill: if is-parallel { _blue-fill } else { _orange-fill },
      stroke: if is-parallel { _blue } else { _orange },
    )
    content(
      (x + cell-width / 2, 17.6),
      align(center, text(size: 5.4pt, weight: "bold", fill: if is-parallel { _blue } else { _orange })[#block]),
    )
  }

  content(((group-1.at(0) + group-1.at(1)) / 2, 16.48), align(center, text(size: 4.4pt, weight: "bold", fill: _blue)[parallel region 1]))
  content(((group-2.at(0) + group-2.at(1)) / 2, 16.48), align(center, text(size: 4.4pt, weight: "bold", fill: _blue)[parallel region 2]))
  content(((serial.at(0) + serial.at(1)) / 2, 16.48), align(center, text(size: 4.4pt, weight: "bold", fill: _orange)[isolated accesses]))

  line(
    (serial.at(1), 17.6),
    (serial.at(1) + .45, 17.6),
    (serial.at(1) + .45, 18.8),
    (trace-x - .45, 18.8),
    (trace-x - .45, 17.6),
    (trace-x, 17.6),
    stroke: (paint: _muted, thickness: .75pt),
    mark: (end: ">", scale: .45),
  )
  content((trace-x - .15, 19.08), text(size: 4.2pt, weight: "bold", fill: _muted)[repeat], anchor: "west")
  line((.3, 15.75), (31.7, 15.75), stroke: _rule)

  // Belady OPT keeps the P working set, minimizing misses but exposing S misses.
  content((.35, 15.05), text(size: 6.1pt, weight: "bold", fill: _blue)[1  Belady OPT: minimize miss count], anchor: "west")
  content((.35, 13.7), text(size: 5pt, weight: "bold")[cache], anchor: "west")
  cache-state(5.0, 13.2, ("P4", "P3", "P2", "S3"), [loop entry])
  line((9.65, 13.64), (10.75, 13.64), stroke: _muted, mark: (end: ">", scale: .42))
  content((10.2, 14.17), align(center, text(size: 4.1pt, weight: "bold", fill: _muted)[P1 fill]))
  cache-state(10.95, 13.2, ("P1", "P2", "P3", "P4"), [after first P region])
  content((15.78, 13.64), text(size: 4.5pt, fill: _muted)[retain P1-P4;#linebreak()S1-S3 miss serially], anchor: "west")

  content((.35, 11.9), text(size: 5pt, weight: "bold")[hit / miss], anchor: "west")
  outcome-row(11.9, opt-outcomes)
  content((.35, 10.7), text(size: 5pt, weight: "bold")[stall batches], anchor: "west")
  interval(group-1.at(0), group-1.at(1), 10.28, [P1 miss -> 1 batch])
  interval(group-2.at(0), group-2.at(1), 10.28, [all hit], stalled: false)
  for i in range(8, 11) {
    interval(access-x(i), access-x(i) + cell-width, 10.28, [1])
  }
  result-box(11.5, 4, 4, _red, [three isolated S misses remain exposed])

  line((.3, 9.45), (31.7, 9.45), stroke: _rule)

  // MLP-aware replacement protects isolated S blocks and streams P blocks.
  content((.35, 8.75), text(size: 6.1pt, weight: "bold", fill: _green)[2  MLP-aware: reduce isolated misses], anchor: "west")
  content((.35, 7.4), text(size: 5pt, weight: "bold")[cache], anchor: "west")
  cache-state(5.0, 6.9, ("P4", "S1", "S2", "S3"), [loop entry])
  line((9.65, 7.34), (10.75, 7.34), stroke: _muted, mark: (end: ">", scale: .42))
  content((10.2, 7.87), align(center, text(size: 4.1pt, weight: "bold", fill: _muted)[P slot rotates]))
  cache-state(10.95, 6.9, ("P1", "S1", "S2", "S3"), [after first P region])
  content((15.78, 7.34), text(size: 4.5pt, fill: _muted)[keep S1-S3;#linebreak()stream P through one slot], anchor: "west")

  content((.35, 5.6), text(size: 5pt, weight: "bold")[hit / miss], anchor: "west")
  outcome-row(5.6, mlp-outcomes)
  content((.35, 4.4), text(size: 5pt, weight: "bold")[stall batches], anchor: "west")
  interval(group-1.at(0), group-1.at(1), 3.98, [3 misses overlap -> 1 batch])
  interval(group-2.at(0), group-2.at(1), 3.98, [3 misses overlap -> 1 batch])
  interval(serial.at(0), serial.at(1), 3.98, [S1-S3 all hit], stalled: false)
  result-box(5.2, 6, 2, _green, [two fewer exposed batches overall])

  rect((5.0, 2.55), (31.65, 3.28), radius: .04, fill: _green-fill, stroke: _green)
  content(
    (18.325, 2.915),
    align(center, text(size: 5pt, weight: "bold", fill: _green)[more misses, but less exposed miss latency]),
  )
  content(
    (18.325, 1.92),
    align(center, text(size: 4.4pt, fill: _muted)[Each red block is one exposed latency interval; widths are schematic.]),
  )
})

#let private-shared-cache-topology() = cetz.canvas(length: .4cm, padding: .15, {
  import cetz.draw: *

  let centers = (4.0, 11.5, 19.0, 26.5)

  let node(a, b, body, fill-color, line-color, text-color: _ink) = {
    rect(a, b, radius: .06, fill: fill-color, stroke: (paint: line-color, thickness: .75pt))
    content(
      ((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2),
      align(center, text(size: 5pt, weight: "bold", fill: text-color)[#body]),
    )
  }

  // Request/response connections are bidirectional.  The shared horizontal
  // lines are schematic buses; larger systems commonly implement them as a NoC.
  for (i, x) in centers.enumerate() {
    node((x - 2.25, 12.15), (x + 2.25, 13.55), [core #i], _blue-fill, _blue)
    node(
      (x - 2.25, 9.65),
      (x + 2.25, 11.15),
      [private L1 / L2],
      _orange-fill,
      _orange,
    )
    line(
      (x, 12.15),
      (x, 11.15),
      stroke: (paint: _blue, thickness: .72pt),
      mark: (start: ">", end: ">", scale: .34),
    )
    line(
      (x, 9.65),
      (x, 8.55),
      stroke: (paint: _blue, thickness: .72pt),
      mark: (start: ">", end: ">", scale: .34),
    )
  }

  line((1.0, 8.55), (29.5, 8.55), stroke: (paint: _blue, thickness: 1.1pt))
  content(
    (15.25, 9.05),
    align(center, text(size: 4.7pt, weight: "bold", fill: _blue)[shared on-chip bus / NoC]),
  )

  for (i, x) in centers.enumerate() {
    node(
      (x - 2.5, 5.65),
      (x + 2.5, 7.15),
      [LLC slice #i\ #text(size: 4.2pt, weight: "regular")[home: $q mod 4 = #i$]],
      _green-fill,
      _green,
      text-color: _green,
    )
    line(
      (x, 8.55),
      (x, 7.15),
      stroke: (paint: _blue, thickness: .72pt),
      mark: (start: ">", end: ">", scale: .34),
    )
    line(
      (x, 5.65),
      (x, 4.45),
      stroke: (paint: _green, thickness: .72pt),
      mark: (start: ">", end: ">", scale: .34),
    )
  }

  content(
    (15.25, 7.7),
    align(center, text(size: 4.7pt, weight: "bold", fill: _green)[one logically shared LLC]),
  )

  line((1.0, 4.45), (29.5, 4.45), stroke: (paint: _green, thickness: 1.05pt))
  content((1.0, 3.98), text(size: 4.5pt, weight: "bold", fill: _green)[memory-side bus], anchor: "west")

  node((11.65, 2.35), (18.85, 3.75), [memory controller], _orange-fill, _orange)
  line(
    (15.25, 4.45),
    (15.25, 3.75),
    stroke: (paint: _green, thickness: .72pt),
    mark: (start: ">", end: ">", scale: .34),
  )

  node((11.65, .15), (18.85, 1.45), [main memory (DRAM)], rgb("#FBFCFD"), _ink)
  line(
    (15.25, 2.35),
    (15.25, 1.45),
    stroke: (paint: _ink, thickness: .72pt),
    mark: (start: ">", end: ">", scale: .34),
  )
})

#let cache-coherence-example() = cetz.canvas(length: .4cm, padding: .15, {
  import cetz.draw: *

  let panel(a, b, title, subtitle, color) = {
    rect(a, b, radius: .08, fill: rgb("#FBFCFD"), stroke: _rule)
    content(((a.at(0) + b.at(0)) / 2, b.at(1) - .55), align(center, text(size: 6pt, weight: "bold", fill: color)[#title]))
    content(((a.at(0) + b.at(0)) / 2, b.at(1) - 1.15), align(center, text(size: 4.6pt, fill: _muted)[#subtitle]))
  }

  panel((.2, .2), (15.35, 11.8), [without coherence], [P1 can retain a stale private copy], _red)
  panel((16.05, .2), (31.2, 11.8), [invalidate protocol], [a writer obtains ownership before updating], _green)

  // Left: stale replicated data.
  for x in (1.1, 9.1) {
    rect((x, 8.15), (x + 5.15, 9.65), fill: _blue-fill, stroke: _blue)
  }
  content((3.675, 8.9), align(center, text(size: 5pt, weight: "bold")[core 0]))
  content((11.675, 8.9), align(center, text(size: 5pt, weight: "bold")[core 1]))
  rect((1.1, 5.85), (6.25, 7.45), fill: _red-fill, stroke: _red)
  rect((9.1, 5.85), (14.25, 7.45), fill: _orange-fill, stroke: _orange)
  content((3.675, 6.65), align(center, text(size: 4.8pt, weight: "bold", fill: _red)[cache: x = 2000]))
  content((11.675, 6.65), align(center, text(size: 4.8pt, weight: "bold", fill: _orange)[cache: x = 1000]))
  line((3.675, 8.15), (3.675, 7.45), stroke: _blue)
  line((11.675, 8.15), (11.675, 7.45), stroke: _blue)
  line((1.1, 4.8), (14.25, 4.8), stroke: (paint: _muted, thickness: 1pt))
  content((7.675, 4.35), align(center, text(size: 4.6pt, fill: _muted)[shared interconnect]))
  rect((4.8, 1.25), (10.55, 2.85), fill: white, stroke: _ink)
  content((7.675, 2.05), align(center, text(size: 4.8pt, weight: "bold")[memory: x = 1000]))
  content((11.675, 5.35), align(center, text(size: 4.5pt, weight: "bold", fill: _red)[load x incorrectly returns 1000]))

  // Right: invalidate, then refetch the writer's value.
  for x in (16.95, 24.95) {
    rect((x, 8.15), (x + 5.15, 9.65), fill: _blue-fill, stroke: _blue)
  }
  content((19.525, 8.9), align(center, text(size: 5pt, weight: "bold")[core 0: write x]))
  content((27.525, 8.9), align(center, text(size: 5pt, weight: "bold")[core 1: load x]))
  rect((16.95, 5.85), (22.1, 7.45), fill: _green-fill, stroke: _green)
  rect((24.95, 5.85), (30.1, 7.45), fill: _red-fill, stroke: _red)
  content((19.525, 6.65), align(center, text(size: 4.8pt, weight: "bold", fill: _green)[M: x = 2000]))
  content((27.525, 6.65), align(center, text(size: 4.8pt, weight: "bold", fill: _red)[I: no valid copy]))
  line((19.525, 8.15), (19.525, 7.45), stroke: _blue)
  line((27.525, 8.15), (27.525, 7.45), stroke: _blue)
  line((16.95, 4.8), (30.1, 4.8), stroke: (paint: _muted, thickness: 1pt))
  content((23.525, 4.35), align(center, text(size: 4.6pt, fill: _muted)[coherent interconnect / directory]))
  line((22.1, 6.65), (24.95, 6.65), stroke: _red, mark: (end: ">", scale: .5))
  content((23.525, 7.15), align(center, text(size: 4.4pt, weight: "bold", fill: _red)[invalidate]))
  line((27.525, 5.85), (27.525, 4.8), (19.525, 4.8), (19.525, 5.85), stroke: _green, mark: (end: ">", scale: .5))
  content((23.525, 3.55), align(center, text(size: 4.5pt, weight: "bold", fill: _green)[read miss obtains x = 2000 from owner or memory]))
  rect((20.65, 1.25), (26.4, 2.85), fill: white, stroke: _ink)
  content((23.525, 2.05), align(center, text(size: 4.8pt, weight: "bold")[memory / directory]))
})
