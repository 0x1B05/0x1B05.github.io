#import "@preview/cetz:0.5.2"
#import cetz.draw: *

// Fixed-grid timing diagrams for the six-instruction OoO exercise.
// Each column is one cycle, so an empty interval is real whitespace in the
// diagram rather than a sequence of placeholder glyphs.

#let _black = rgb("#1B1B1B")
#let _muted = rgb("#767676")
#let _grid = rgb("#D9DDE5")
#let _fetch-fill = rgb("#E8F0FE")
#let _fetch-stroke = rgb("#1A41AC")
#let _add-fill = rgb("#EAF2FF")
#let _add-stroke = rgb("#3159B7")
#let _mul-fill = rgb("#FFF0D9")
#let _mul-stroke = rgb("#B65C00")
#let _write-fill = rgb("#DFF4E8")
#let _write-stroke = rgb("#20744A")
#let _wait-fill = rgb("#F1F2F4")
#let _wait-stroke = rgb("#9AA0AA")
#let _r3 = rgb("#C62828")
#let _r7 = rgb("#1565C0")
#let _r10 = rgb("#9A5B00")
#let _r5 = rgb("#7B1FA2")
#let _r11 = rgb("#00796B")

#let _instructions = (
  [MUL R1, R2 -> #text(fill: _r3, weight: "bold")[R3]],
  [ADD #text(fill: _r3, weight: "bold")[R3], R4 -> #text(fill: _r5, weight: "bold")[R5]],
  [ADD R2, R6 -> #text(fill: _r7, weight: "bold")[R7]],
  [ADD R8, R9 -> #text(fill: _r10, weight: "bold")[R10]],
  [MUL #text(fill: _r7, weight: "bold")[R7], #text(fill: _r10, weight: "bold")[R10] -> #text(fill: _r11, weight: "bold")[R11]],
  [ADD #text(fill: _r5, weight: "bold")[R5], #text(fill: _r11, weight: "bold")[R11] -> R5],
)

#let _cell(x, y, label, fill, stroke, size: 5.7pt) = {
  rect(
    (x, y - .31),
    (x + 1, y + .31),
    radius: .04,
    fill: fill,
    stroke: stroke,
  )
  content(
    (x + .5, y),
    align(center, text(size: size, weight: "bold")[#label]),
  )
}

#let _wait-band(x, y, width, label: "wait") = {
  if width > 0 {
    rect(
      (x, y - .31),
      (x + width, y + .31),
      radius: .04,
      fill: _wait-fill,
      stroke: (paint: _wait-stroke, dash: "dashed"),
    )
    content(
      (x + width / 2, y),
      align(center, text(size: 5.2pt, fill: _muted)[#label]),
    )
  }
}

#let _row-y(index) = 6.6 - index * 1.02

#let _draw-row(x0, row, index, through: none) = {
  let y = _row-y(index)
  let id = row.id
  let instruction = _instructions.at(index)
  let f = row.f
  let d = row.d
  let e = row.e
  let elen = row.elen
  let w = row.w
  let wait = row.wait
  let is-mul = index == 0 or index == 4
  let e-fill = if is-mul { _mul-fill } else { _add-fill }
  let e-stroke = if is-mul { _mul-stroke } else { _add-stroke }
  let last = if through == none { row.cycles } else { through }

  // The complete instruction stays in a dedicated gutter outside the grid.
  content((1.25, y), text(size: 6.4pt, weight: "bold")[#id], anchor: "east")
  content((1.55, y), text(size: 5.5pt)[#instruction], anchor: "west")

  line((x0, y - .43), (x0 + last, y - .43), stroke: _grid)
  if f <= last {
    _cell(x0 + f - 1, y, [F], _fetch-fill, _fetch-stroke)
  }
  if d <= last {
    _cell(x0 + d - 1, y, [D], _fetch-fill, _fetch-stroke)
  }

  if wait != none {
    let wait-start = wait.at(0)
    let wait-end = wait.at(1)
    if wait-start <= last {
      let visible-end = calc.min(wait-end, last)
      _wait-band(x0 + wait-start - 1, y, visible-end - wait-start + 1)
    }
  }

  for i in range(elen) {
    let number = i + 1
    if e + i <= last {
      _cell(x0 + e + i - 1, y, [E#number], e-fill, e-stroke, size: 5.0pt)
    }
  }
  if w <= last {
    _cell(x0 + w - 1, y, [W], _write-fill, _write-stroke)
  }
}

#let _dependency(x0, from-cycle, from-row, to-cycle, to-row, bend, target, color) = {
  let from-x = x0 + from-cycle - .5
  let to-x = x0 + to-cycle - .5 + target
  let from-y = _row-y(from-row)
  let to-y = _row-y(to-row)

  let start-x = from-x
  let start-y = from-y - .34
  let end-x = to-x
  let end-y = to-y + .34
  let dx = end-x - start-x
  let dy = end-y - start-y
  let reach = if dx < 1.2 { .48 } else { dx * .28 }
  let ctrl-1 = (start-x + reach + bend, start-y + dy * .28)
  let ctrl-2 = (end-x - reach + bend, end-y - dy * .28)

  // Separate curves and target offsets prevent multiple dependences from
  // sharing the same trunk or piling their arrowheads onto one point.
  bezier(
    (start-x, start-y),
    (end-x, end-y),
    ctrl-1,
    ctrl-2,
    stroke: (paint: color, thickness: .75pt),
    mark: (end: ">"),
  )

}

#let _timeline(
  title,
  cycles,
  rows,
  dependencies,
  total,
  total-fill,
) = cetz.canvas(length: .37cm, padding: .16, {
  import cetz.draw: *

  let x0 = 10.65
  let top = 6.6
  // Keep the vertical cycle grid flush with the bottom rule of the last lane.
  let bottom = _row-y(rows.len() - 1) - .43

  // Header and cycle ruler.
  content((.25, top + 1.30), text(size: 8pt, weight: "bold")[#title])
  rect(
    (x0 + cycles - 5.8, top + 1.00),
    (x0 + cycles, top + 1.60),
    radius: .08,
    fill: total-fill,
    stroke: total-fill,
  )
  content(
    (x0 + cycles - 2.9, top + 1.30),
    align(center, text(size: 9pt, weight: "bold", fill: white)[#total cycles]),
  )

  for cycle in range(1, cycles + 1) {
    let x = x0 + cycle - 1
    line((x, bottom), (x, top + .45), stroke: _grid)
  }
  line((x0 + cycles, bottom), (x0 + cycles, top + .45), stroke: _grid)

  // Draw lanes first. Dependency arrows are added afterward so their heads
  // remain visible at the consumer's execute cell.
  for row in rows {
    _draw-row(x0, row, row.index)
  }
  for dependency in dependencies {
    _dependency(
      x0,
      dependency.from,
      dependency.from-row,
      dependency.to,
      dependency.to-row,
      dependency.bend,
      dependency.target,
      dependency.color,
    )
  }

  // Draw ruler labels last and above the first lane so no stage box or
  // dependency arrow can cover the cycle numbers.
  content((x0 - .35, top + .65), align(right, text(size: 5.2pt, fill: _muted)[cycle]))
  for cycle in range(1, cycles + 1) {
    let x = x0 + cycle - 1
    content(
      (x + .5, top + .65),
      align(center, text(size: 4.8pt, fill: _muted)[#cycle]),
    )
  }

  content(
    (.25, .72),
    text(size: 5.2pt, fill: _muted)[F/D fetch + decode  •  E execute  •  W writeback],
  )
  content(
    (.25, .20),
    text(size: 5.2pt, fill: _muted)[matching register colors identify the same RAW value],
  )
  content(
    (x0 + cycles, .72),
    align(right, text(size: 5.2pt, fill: _muted)[colored arrows = RAW dependence]),
  )
})

#let _rows-no-forwarding = (
  (id: "I0", op: "MUL R3", index: 0, f: 1, d: 2, e: 3, elen: 6, w: 9, wait: none, cycles: 31),
  (id: "I1", op: "ADD R5", index: 1, f: 2, d: 3, e: 11, elen: 4, w: 15, wait: (4, 10), cycles: 31),
  (id: "I2", op: "ADD R7", index: 2, f: 3, d: 4, e: 12, elen: 4, w: 16, wait: (5, 11), cycles: 31),
  (id: "I3", op: "ADD R10", index: 3, f: 10, d: 11, e: 13, elen: 4, w: 17, wait: (12, 12), cycles: 31),
  (id: "I4", op: "MUL R11", index: 4, f: 11, d: 12, e: 19, elen: 6, w: 25, wait: (13, 18), cycles: 31),
  (id: "I5", op: "ADD R5", index: 5, f: 12, d: 13, e: 27, elen: 4, w: 31, wait: (14, 26), cycles: 31),
)

#let _deps-no-forwarding = (
  (from: 9, from-row: 0, to: 11, to-row: 1, bend: .24, target: 0, color: _r3),
  (from: 16, from-row: 2, to: 19, to-row: 4, bend: 1.8, target: -.22, color: _r7),
  (from: 17, from-row: 3, to: 19, to-row: 4, bend: -.28, target: .22, color: _r10),
  (from: 15, from-row: 1, to: 27, to-row: 5, bend: 3.0, target: -.18, color: _r5),
  (from: 25, from-row: 4, to: 27, to-row: 5, bend: .36, target: .18, color: _r11),
)

#let _rows-forwarding = (
  (id: "I0", op: "MUL R3", index: 0, f: 1, d: 2, e: 3, elen: 6, w: 9, wait: none, cycles: 25),
  (id: "I1", op: "ADD R5", index: 1, f: 2, d: 3, e: 9, elen: 4, w: 13, wait: (4, 8), cycles: 25),
  (id: "I2", op: "ADD R7", index: 2, f: 3, d: 4, e: 10, elen: 4, w: 14, wait: (5, 9), cycles: 25),
  (id: "I3", op: "ADD R10", index: 3, f: 4, d: 5, e: 11, elen: 4, w: 15, wait: (6, 10), cycles: 25),
  (id: "I4", op: "MUL R11", index: 4, f: 5, d: 6, e: 15, elen: 6, w: 21, wait: (7, 14), cycles: 25),
  (id: "I5", op: "ADD R5", index: 5, f: 6, d: 7, e: 21, elen: 4, w: 25, wait: (8, 20), cycles: 25),
)

#let _deps-forwarding = (
  (from: 8, from-row: 0, to: 9, to-row: 1, bend: .24, target: 0, color: _r3),
  (from: 13, from-row: 2, to: 15, to-row: 4, bend: 1.8, target: -.22, color: _r7),
  (from: 14, from-row: 3, to: 15, to-row: 4, bend: -.28, target: .22, color: _r10),
  (from: 12, from-row: 1, to: 21, to-row: 5, bend: 3.0, target: -.18, color: _r5),
  (from: 20, from-row: 4, to: 21, to-row: 5, bend: .36, target: .18, color: _r11),
)

#let _rows-ooo = (
  (id: "I0", op: "MUL R3", index: 0, f: 1, d: 2, e: 3, elen: 6, w: 9, wait: none, cycles: 20),
  (id: "I1", op: "ADD R5", index: 1, f: 2, d: 3, e: 9, elen: 4, w: 13, wait: (4, 8), cycles: 20),
  (id: "I2", op: "ADD R7", index: 2, f: 3, d: 4, e: 5, elen: 4, w: 9, wait: none, cycles: 20),
  (id: "I3", op: "ADD R10", index: 3, f: 4, d: 5, e: 6, elen: 4, w: 10, wait: none, cycles: 20),
  (id: "I4", op: "MUL R11", index: 4, f: 5, d: 6, e: 10, elen: 6, w: 16, wait: (7, 9), cycles: 20),
  (id: "I5", op: "ADD R5", index: 5, f: 6, d: 7, e: 16, elen: 4, w: 20, wait: (8, 15), cycles: 20),
)

#let _deps-ooo = (
  (from: 8, from-row: 0, to: 9, to-row: 1, bend: .24, target: 0, color: _r3),
  (from: 8, from-row: 2, to: 10, to-row: 4, bend: 1.8, target: -.22, color: _r7),
  (from: 9, from-row: 3, to: 10, to-row: 4, bend: -.28, target: .22, color: _r10),
  (from: 12, from-row: 1, to: 16, to-row: 5, bend: 3.0, target: -.18, color: _r5),
  (from: 15, from-row: 4, to: 16, to-row: 5, bend: .36, target: .18, color: _r11),
)

#let ooo-timeline-no-forwarding() = _timeline(
  [In-order dispatch • no forwarding],
  31,
  _rows-no-forwarding,
  _deps-no-forwarding,
  31,
  _mul-stroke,
)

#let ooo-timeline-forwarding() = _timeline(
  [In-order dispatch • full forwarding],
  25,
  _rows-forwarding,
  _deps-forwarding,
  25,
  _mul-stroke,
)

#let ooo-timeline-out-of-order() = _timeline(
  [Out-of-order dispatch • full forwarding],
  20,
  _rows-ooo,
  _deps-ooo,
  20,
  _fetch-stroke,
)

// A compact, prefix-only view used by the cycle-by-cycle machine simulation.
// The current cycle is highlighted; no future stages or dependency arrows are
// drawn, so each snapshot reads as the state known at the end of that cycle.
#let ooo-cycle-progress(cycle) = {
  assert(cycle >= 1 and cycle <= 20, message: "cycle must be in 1..20")

  cetz.canvas(length: .37cm, padding: .12, {
    import cetz.draw: *

    let x0 = 10.65
    let top = 6.6
    let bottom = _row-y(_rows-ooo.len() - 1) - .43
    let current-x = x0 + cycle - 1

    // Pale amber is reserved for the cycle being explained on this page.
    rect(
      (current-x, bottom),
      (current-x + 1, top + .45),
      fill: rgb("#FFF1C7"),
      stroke: none,
    )

    for tick in range(1, cycle + 1) {
      let x = x0 + tick - 1
      line((x, bottom), (x, top + .45), stroke: _grid)
    }
    line((x0 + cycle, bottom), (x0 + cycle, top + .45), stroke: _grid)

    for row in _rows-ooo {
      _draw-row(x0, row, row.index, through: cycle)
    }

    content(
      (.25, top + .65),
      text(size: 6.2pt, weight: "bold", fill: _muted)[Pipeline progress],
    )
    content(
      (x0 - .35, top + .65),
      align(right, text(size: 5.2pt, fill: _muted)[cycle]),
    )
    for tick in range(1, cycle + 1) {
      let x = x0 + tick - 1
      let is-current = tick == cycle
      content(
        (x + .5, top + .65),
        align(center, text(
          size: 4.8pt,
          weight: if is-current { "bold" } else { "regular" },
          fill: if is-current { _mul-stroke } else { _muted },
        )[#tick]),
      )
    }
  })
}
