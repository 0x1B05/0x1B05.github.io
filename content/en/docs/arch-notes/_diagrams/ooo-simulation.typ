#import "@preview/cetz:0.5.2"
#import "ooo-timelines.typ": ooo-cycle-progress

// Cycle-by-cycle state for the six-instruction Tomasulo example. The source
// data records only state transitions; every displayed RAT and RS snapshot is
// derived from these events so repeated cycles cannot drift out of sync.

#let _black = rgb("#1B1B1B")
#let _muted = rgb("#6F737B")
#let _rule = rgb("#D9DDE5")
#let _header-fill = rgb("#F3F5F8")
#let _changed-fill = rgb("#FFF2CC")
#let _rat-accent = rgb("#B65C00")
#let _ready-fill = rgb("#E6F4EA")
#let _ready-text = rgb("#0B6B37")
#let _wait-fill = rgb("#FFF1E3")
#let _wait-text = rgb("#A34F00")
#let _exec-fill = rgb("#E8F0FE")
#let _exec-text = rgb("#1A41AC")
#let _done-fill = rgb("#E4F3F1")
#let _done-text = rgb("#00796B")

// These colors match the value identities in ooo-timelines.typ. The final d
// value has no consumer in this example, so it intentionally uses black rather
// than sharing a's R5-dependence color.
#let _tag-colors = (
  x: rgb("#C62828"),
  a: rgb("#7B1FA2"),
  b: rgb("#1565C0"),
  c: rgb("#9A5B00"),
  y: rgb("#00796B"),
  d: _black,
  z: _muted,
  t: _muted,
)

#let _registers = range(1, 12).map(number => "R" + str(number))

#let _rat-updates = (
  (cycle: 2, reg: "R3", valid: false, tag: "x", value: none),
  (cycle: 3, reg: "R5", valid: false, tag: "a", value: none),
  (cycle: 4, reg: "R7", valid: false, tag: "b", value: none),
  (cycle: 5, reg: "R10", valid: false, tag: "c", value: none),
  (cycle: 6, reg: "R11", valid: false, tag: "y", value: none),
  // I5 creates a newer R5 version. A later broadcast from a must not update it.
  (cycle: 7, reg: "R5", valid: false, tag: "d", value: none),
  (cycle: 8, reg: "R3", valid: true, tag: none, value: 2),
  (cycle: 8, reg: "R7", valid: true, tag: none, value: 8),
  (cycle: 9, reg: "R10", valid: true, tag: none, value: 17),
  (cycle: 15, reg: "R11", valid: true, tag: none, value: 136),
  (cycle: 19, reg: "R5", valid: true, tag: none, value: 142),
)

#let _source(events, cycle) = {
  let visible = events.filter(event => event.cycle <= cycle)
  if visible.len() == 0 {
    none
  } else {
    let latest = visible.last()
    latest + (changed: latest.cycle == cycle,)
  }
}

// Each source list starts with its allocation-time state. Later items are
// captures from a tag/value broadcast.
#let _rs-entries = (
  (
    name: "a", unit: "ADD", allocated: 3, ready: 8, execute: 9, done: 12,
    src1: (
      (cycle: 3, valid: false, tag: "x", value: none),
      (cycle: 8, valid: true, tag: none, value: 2),
    ),
    src2: ((cycle: 3, valid: true, tag: none, value: 4),),
  ),
  (
    name: "b", unit: "ADD", allocated: 4, ready: 4, execute: 5, done: 8,
    src1: ((cycle: 4, valid: true, tag: none, value: 2),),
    src2: ((cycle: 4, valid: true, tag: none, value: 6),),
  ),
  (
    name: "c", unit: "ADD", allocated: 5, ready: 5, execute: 6, done: 9,
    src1: ((cycle: 5, valid: true, tag: none, value: 8),),
    src2: ((cycle: 5, valid: true, tag: none, value: 9),),
  ),
  (
    name: "d", unit: "ADD", allocated: 7, ready: 15, execute: 16, done: 19,
    src1: (
      (cycle: 7, valid: false, tag: "a", value: none),
      (cycle: 12, valid: true, tag: none, value: 6),
    ),
    src2: (
      (cycle: 7, valid: false, tag: "y", value: none),
      (cycle: 15, valid: true, tag: none, value: 136),
    ),
  ),
  (
    name: "x", unit: "MUL", allocated: 2, ready: 2, execute: 3, done: 8,
    src1: ((cycle: 2, valid: true, tag: none, value: 1),),
    src2: ((cycle: 2, valid: true, tag: none, value: 2),),
  ),
  (
    name: "y", unit: "MUL", allocated: 6, ready: 9, execute: 10, done: 15,
    src1: (
      (cycle: 6, valid: false, tag: "b", value: none),
      (cycle: 8, valid: true, tag: none, value: 8),
    ),
    src2: (
      (cycle: 6, valid: false, tag: "c", value: none),
      (cycle: 9, valid: true, tag: none, value: 17),
    ),
  ),
)

#let _cycle-events = (
  (cycle: 2, summary: [Decode I0: allocate MUL RS x and rename R3 -> x. Both operands are ready.]),
  (cycle: 3, summary: [x starts E1. Decode I1 into ADD RS a and rename R5 -> a; a waits for x.]),
  (cycle: 4, summary: [x executes E2. Decode I2 into ADD RS b and rename R7 -> b; b is ready.]),
  (cycle: 5, summary: [x executes E3 and b starts E1. Decode I3 into c; rename R10 -> c.]),
  (cycle: 6, summary: [Decode I4 into MUL RS y and rename R11 -> y. y waits for tags b and c.]),
  (cycle: 7, summary: [Decode I5 into ADD RS d and rename R5 -> d. All instructions are now renamed.]),
  (cycle: 8, summary: [x = 2 and b = 8 broadcast on the separate MUL and ADD buses. a captures 2; y captures 8.]),
  (cycle: 9, summary: [c = 17 broadcasts. y captures 17 and becomes ready; a starts E1.]),
  (cycle: 10, summary: [a executes E2 while y starts E1 on the multiplier.]),
  (cycle: 11, summary: [a executes E3 while y executes E2.]),
  (cycle: 12, summary: [a = 6 broadcasts after E4. d captures 6; RAT R5 stays mapped to the newer tag d.]),
  (cycle: 13, summary: [a writes back while y executes E4. d still waits for tag y.]),
  (cycle: 14, summary: [y executes E5. d remains waiting for its second operand.]),
  (cycle: 15, summary: [y = 136 broadcasts after E6. RAT R11 is updated; d captures 136 and becomes ready.]),
  (cycle: 16, summary: [y writes back and d starts E1 with operands 6 and 136.]),
  (cycle: 17, summary: [d executes E2.]),
  (cycle: 18, summary: [d executes E3.]),
  (cycle: 19, summary: [d = 142 broadcasts after E4 and updates RAT R5.]),
  (cycle: 20, summary: [d writes back. The six-instruction sequence completes in 20 cycles.]),
)

#let _event-at(cycle) = _cycle-events.filter(event => event.cycle == cycle).first().summary

#let _rat-at(cycle) = _registers.enumerate().map(pair => {
  let index = pair.at(0)
  let reg = pair.at(1)
  let updates = _rat-updates.filter(update => update.reg == reg and update.cycle <= cycle)

  if updates.len() == 0 {
    (reg: reg, valid: true, tag: none, value: index + 1, changed: false)
  } else {
    let latest = updates.last()
    latest + (changed: latest.cycle == cycle,)
  }
})

#let _status(entry, cycle) = {
  if cycle < entry.allocated {
    "EMPTY"
  } else if cycle >= entry.done {
    "DONE"
  } else if cycle >= entry.execute {
    "EXEC E" + str(cycle - entry.execute + 1)
  } else if cycle >= entry.ready {
    "READY"
  } else {
    "WAIT"
  }
}

#let _status-style(status) = {
  if status == "EMPTY" {
    (fill: white, text: _muted)
  } else if status == "WAIT" {
    (fill: _wait-fill, text: _wait-text)
  } else if status == "READY" {
    (fill: _ready-fill, text: _ready-text)
  } else if status == "DONE" {
    (fill: _done-fill, text: _done-text)
  } else {
    (fill: _exec-fill, text: _exec-text)
  }
}

#let _tag(tag, size: 7pt) = {
  if tag == none {
    text("--", size: size, fill: _muted)
  } else {
    text(tag, size: size, fill: _tag-colors.at(tag), weight: "bold")
  }
}

#let _plain(value, size: 7pt, fill: _black, weight: "regular") = {
  let shown = if value == none { "--" } else { str(value) }
  text(shown, size: size, fill: if value == none { _muted } else { fill }, weight: weight)
}

#let _table-cell(body, fill: white, bold: false, left-align: false, size: 7pt) = table.cell(
  text(body, size: size, weight: if bold { "bold" } else { "regular" }),
  fill: fill,
  inset: (x: 2.4pt, y: 2.2pt),
  align: if left-align { left + horizon } else { center + horizon },
)

#let _content-cell(body, fill: white, left-align: false) = table.cell(
  body,
  fill: fill,
  inset: (x: 2.4pt, y: 2.2pt),
  align: if left-align { left + horizon } else { center + horizon },
)

#let _rat-table(cycle) = {
  let state = _rat-at(cycle)
  let columns = (1.25fr,) + range(11).map(index => 1fr)

  table(
    columns: columns,
    stroke: _rule,
    table.header(
      _table-cell([Reg], fill: _header-fill, bold: true),
      .._registers.map(reg => _table-cell([#reg], fill: _header-fill, bold: true, size: 6.8pt)),
    ),
    _table-cell([Valid], fill: _header-fill, bold: true, left-align: true),
    ..state.map(item => _table-cell(
      [#if item.valid { 1 } else { 0 }],
      fill: if item.changed { _changed-fill } else { white },
      bold: item.changed,
    )),
    _table-cell([Value], fill: _header-fill, bold: true, left-align: true),
    ..state.map(item => _content-cell(
      _plain(item.value, weight: if item.changed { "bold" } else { "regular" }),
      fill: if item.changed { _changed-fill } else { white },
    )),
    _table-cell([Tag], fill: _header-fill, bold: true, left-align: true),
    ..state.map(item => _content-cell(
      _tag(item.tag),
      fill: if item.changed { _changed-fill } else { white },
    )),
  )
}

#let _operand-head() = grid(
  columns: (.45fr, .75fr, 1fr),
  column-gutter: 1pt,
  align: center,
  text("V", size: 6.2pt, weight: "bold"),
  text("Tag", size: 6.2pt, weight: "bold"),
  text("Value", size: 6.2pt, weight: "bold"),
)

#let _operand-cell(source) = {
  if source == none {
    grid(
      columns: (.45fr, .75fr, 1fr),
      column-gutter: 1pt,
      align: center,
      _plain(none, size: 6.5pt),
      _plain(none, size: 6.5pt),
      _plain(none, size: 6.5pt),
    )
  } else {
    grid(
      columns: (.45fr, .75fr, 1fr),
      column-gutter: 1pt,
      align: center,
      _plain(if source.valid { 1 } else { 0 }, size: 6.5pt, weight: if source.changed { "bold" } else { "regular" }),
      _tag(source.tag, size: 6.5pt),
      _plain(source.value, size: 6.5pt, weight: if source.changed { "bold" } else { "regular" }),
    )
  }
}

#let _empty-entry(name, unit) = (
  name: name,
  unit: unit,
  allocated: 21,
  ready: 21,
  execute: 21,
  done: 21,
  src1: (),
  src2: (),
)

#let _entries-for(unit) = {
  let names = if unit == "ADD" { ("a", "b", "c", "d") } else { ("x", "y", "z", "t") }
  names.map(name => {
    let matches = _rs-entries.filter(entry => entry.name == name)
    if matches.len() == 0 { _empty-entry(name, unit) } else { matches.first() }
  })
}

#let _rs-table(cycle, unit) = {
  let entries = _entries-for(unit)

  table(
    columns: (.48fr, 1fr, 1.75fr, 1.75fr),
    stroke: _rule,
    table.header(
      _table-cell([RS], fill: _header-fill, bold: true, size: 6.5pt),
      _table-cell([State], fill: _header-fill, bold: true, size: 6.5pt),
      _content-cell(_operand-head(), fill: _header-fill),
      _content-cell(_operand-head(), fill: _header-fill),
    ),
    ..entries.map(entry => {
      let status = _status(entry, cycle)
      let style = _status-style(status)
      let src1 = _source(entry.src1, cycle)
      let src2 = _source(entry.src2, cycle)

      (
        _content-cell(_tag(entry.name, size: 7.2pt)),
        _content-cell(text(status, size: 6.2pt, weight: "bold", fill: style.text), fill: style.fill),
        _content-cell(
          _operand-cell(src1),
          fill: if src1 != none and src1.changed { _changed-fill } else { white },
        ),
        _content-cell(
          _operand-cell(src2),
          fill: if src2 != none and src2.changed { _changed-fill } else { white },
        ),
      )
    }).flatten(),
  )
}

#let _event-banner(cycle) = block(
  [#text(size: 7.6pt, fill: _black)[*End-of-cycle event:* #_event-at(cycle)]],
  width: 100%,
  inset: (x: 7pt, y: 4pt),
  fill: rgb("#F7F8FA"),
  stroke: _rule,
  radius: 3pt,
)

#let _rs-panel(cycle, unit) = align(center)[
  #text(size: 8.5pt, weight: "bold")[RS for #unit Unit]
  #v(2pt)
  #_rs-table(cycle, unit)
]

#let ooo-cycle-snapshot(cycle) = {
  assert(cycle >= 2 and cycle <= 20, message: "OoO snapshot cycle must be between 2 and 20")

  block(
    [
      #align(left)[#ooo-cycle-progress(cycle)]
      #v(4pt)
      #_event-banner(cycle)
      #v(6pt)
      #align(center)[
        #text(size: 8.8pt, weight: "bold", fill: _rat-accent)[Register Alias Table]
      ]
      #v(2pt)
      // Site note: outside align(center) so the fr columns expand to the full
      // block width — inside align() the table shrinks to content width and
      // its rules end up shorter than the banner/RS tables above and below.
      #_rat-table(cycle)
      #v(7pt)
      #grid(
        columns: (1fr, 1fr),
        column-gutter: 10pt,
        align: top,
        [#_rs-panel(cycle, "ADD")],
        [#_rs-panel(cycle, "MUL")],
      )
      #v(3pt)
      #align(center)[#text(size: 6.2pt, fill: _muted)[
        amber = RAT/operand update this cycle | V=1: value ready; V=0: wait for tag | completed RS contents are retained
      ]]
    ],
    // Site note: a fixed width instead of 100% — inside html.frame a
    // percentage width has no page to resolve against and collapses.
    width: 440pt,
    breakable: false,
  )
}

// Cycle 8 has two independent result buses. Keep the broadcasts in separate
// lanes so tag matching and value capture can be followed without long,
// crossing wires.
#let ooo-cycle8-broadcast() = cetz.canvas(length: .355cm, padding: .14, {
  import cetz.draw: *

  let x-color = _tag-colors.x
  let b-color = _tag-colors.b
  let x-fill = rgb("#FDECEC")
  let b-fill = rgb("#E8F0FE")

  let node(a, b, body, fill: white, stroke: _rule, radius: .06) = {
    rect(a, b, radius: radius, fill: fill, stroke: stroke)
    content(
      ((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2),
      align(center, body),
    )
  }

  let result-bus(y, unit, tag, value, color, fill) = {
    content(
      (15.9, y + 1.25),
      align(center, text(size: 6.1pt, weight: "bold", fill: color)[#unit result bus]),
    )
    rect((13.5, y - .85), (18.3, y + .85), radius: .05, fill: fill, stroke: color)
    line((15.8, y - .85), (15.8, y + .85), stroke: color)
    content((14.65, y + .28), align(center, text(size: 5.2pt, fill: _muted)[tag]))
    content((14.65, y - .28), align(center, text(size: 7pt, weight: "bold", fill: color)[#tag]))
    content((17.05, y + .28), align(center, text(size: 5.2pt, fill: _muted)[value]))
    content((17.05, y - .28), align(center, text(size: 7pt, weight: "bold")[#value]))
  }

  let target(a, b, title, before, after, note, color, note-color) = {
    let center-x = (a.at(0) + b.at(0)) / 2
    let top = b.at(1)
    let bottom = a.at(1)

    rect(a, b, radius: .06, fill: white, stroke: color)
    content(
      (center-x, top - .4),
      align(center, text(size: 6.1pt, weight: "bold")[#title]),
    )
    line(
      (a.at(0), top - .76),
      (b.at(0), top - .76),
      stroke: (paint: _rule, thickness: .45pt),
    )
    content(
      (center-x, top - 1.12),
      align(center, text(size: 5.1pt, fill: _muted)[before: #before]),
    )
    content(
      (center-x, top - 1.78),
      align(center, text(size: 5.4pt, weight: "bold", fill: color)[after: #after]),
    )
    content(
      (center-x, bottom + .38),
      align(center, text(size: 4.8pt, weight: "bold", fill: note-color)[#note]),
    )
  }

  let lane(
    y,
    unit,
    producer,
    expression,
    tag,
    value,
    color,
    fill,
    rat-reg,
    consumer,
    consumer-before,
    consumer-after,
    consumer-note,
    consumer-note-color,
  ) = {
    let symbol = if unit == "MUL" { [×] } else { [+] }

    // Fixed baselines keep both lines comfortably inside the producer box.
    rect(
      (.4, y - 1.2),
      (7.5, y + 1.2),
      radius: .06,
      fill: fill,
      stroke: color,
    )
    content(
      (3.95, y + .48),
      align(center, [
        #text(size: 5.8pt, weight: "bold")[Producer: #unit RS ]#text(size: 6.1pt, weight: "bold", fill: color)[#producer]
      ]),
    )
    content(
      (3.95, y - .46),
      align(center, text(size: 6.8pt, weight: "bold")[#expression]),
    )

    line((7.5, y), (8.45, y), stroke: color, mark: (end: ">"))
    rect(
      (8.45, y - .82),
      (12.2, y + .82),
      radius: .06,
      fill: _header-fill,
      stroke: color,
    )
    content(
      (10.325, y + .3),
      align(center, text(size: 4.9pt, fill: _muted)[execute]),
    )
    content(
      (10.325, y - .31),
      align(center, text(size: 7.7pt, weight: "bold")[#symbol]),
    )
    line((12.2, y), (13.5, y), stroke: color, mark: (end: ">"))
    result-bus(y, unit, tag, value, color, fill)

    // Every RAT/RS entry snoops the bus. Only matching invalid entries capture.
    line((18.3, y), (44.8, y), stroke: (paint: color, thickness: 1.05pt))
    content(
      (32.0, y + .42),
      align(center, text(size: 5.2pt, fill: _muted)[all RAT and RS entries snoop tag #tag]),
    )

    let target-top = y - 1.9
    let target-bottom = y - 5.2
    let rat-center = 25.2
    let rs-center = 38.0

    line(
      (rat-center, y),
      (rat-center, target-top),
      stroke: (paint: color, thickness: .8pt),
      mark: (end: ">"),
    )
    line(
      (rs-center, y),
      (rs-center, target-top),
      stroke: (paint: color, thickness: .8pt),
      mark: (end: ">"),
    )

    target(
      (20.0, target-bottom),
      (30.4, target-top),
      [RAT #rat-reg],
      [V=0 | tag=#tag | value=--],
      [V=1 | tag=-- | value=#value],
      [invalid + tag match -> update],
      color,
      _ready-text,
    )
    target(
      (31.2, target-bottom),
      (44.8, target-top),
      consumer,
      consumer-before,
      consumer-after,
      consumer-note,
      color,
      consumer-note-color,
    )
  }

  content(
    (.4, 19.15),
    text(size: 8.2pt, weight: "bold")[Cycle 8: two independent broadcasts in parallel],
  )
  content(
    (44.8, 19.15),
    align(right, text(size: 5.8pt, fill: _muted)[broadcast tag -> compare -> capture value]),
  )

  lane(
    16.0,
    "MUL",
    "x",
    [1 × 2 = 2],
    "x",
    2,
    x-color,
    x-fill,
    "R3",
    [ADD RS a, source 1],
    [V=0 | tag=x | value=--],
    [V=1 | tag=-- | value=2],
    [source 2 is 4 -> a READY for Cycle 9],
    _ready-text,
  )

  line((.4, 9.75), (44.8, 9.75), stroke: _rule)

  lane(
    7.8,
    "ADD",
    "b",
    [2 + 6 = 8],
    "b",
    8,
    b-color,
    b-fill,
    "R7",
    [MUL RS y, source 1],
    [V=0 | tag=b | value=--],
    [V=1 | tag=-- | value=8],
    [source 2 still waits for c -> y WAIT],
    _wait-text,
  )
})

// The six decoded instructions form a dataflow graph inside the instruction
// window. Colored edges name renamed values, so the two R5 definitions remain
// visually and semantically distinct.
#let ooo-dataflow-graph() = cetz.canvas(length: .42cm, padding: .14, {
  import cetz.draw: *

  let x-color = _tag-colors.x
  let a-color = _tag-colors.a
  let b-color = _tag-colors.b
  let c-color = _tag-colors.c
  let y-color = _tag-colors.y
  let d-color = _tag-colors.d
  let window-fill = rgb("#FAFBFC")

  let instruction(at, id, unit, symbol) = {
    let x = at.at(0)
    let y = at.at(1)
    rect(
      (x - 1.6, y - .82),
      (x + 1.6, y + .82),
      radius: .12,
      fill: white,
      stroke: (paint: _black, thickness: .75pt),
    )
    content(
      (x, y + .35),
      align(center, text(size: 5.1pt, fill: _muted)[#id · #unit]),
    )
    content(
      (x, y - .27),
      align(center, text(size: 9pt, weight: "bold")[#symbol]),
    )
  }

  let source(x, label, target-x, target-y) = {
    content(
      (x, 17.45),
      align(center, text(size: 6.1pt, weight: "bold")[#label]),
    )
    line(
      (x, 17.0),
      (target-x, target-y),
      stroke: (paint: _muted, thickness: .65pt),
      mark: (end: ">"),
    )
  }

  let dependency(points, label-at, label, color) = {
    line(
      ..points,
      stroke: (paint: color, thickness: 1.05pt),
      mark: (end: ">"),
    )
    content(
      label-at,
      box(
        inset: (x: 2.4pt, y: 1.2pt),
        fill: white,
        stroke: (paint: color, thickness: .45pt),
        radius: 2pt,
        text(size: 5.5pt, weight: "bold", fill: color)[#label],
      ),
    )
  }

  content(
    (.8, 18.55),
    text(size: 6.2pt, weight: "bold")[_Architectural source values_],
    anchor: "west",
  )
  rect(
    (.6, .55),
    (31.5, 16.35),
    radius: .1,
    fill: window-fill,
    stroke: (paint: _muted, thickness: .7pt, dash: "dashed"),
  )
  instruction((5.0, 14.0), "I0", "MUL", "×")
  instruction((17.0, 14.0), "I2", "ADD", "+")
  instruction((29.0, 14.0), "I3", "ADD", "+")
  instruction((5.0, 9.4), "I1", "ADD", "+")
  instruction((23.0, 9.4), "I4", "MUL", "×")
  instruction((14.0, 4.4), "I5", "ADD", "+")

  source(4.15, "R1", 4.35, 14.82)
  source(5.85, "R2", 5.65, 14.82)
  source(16.15, "R2", 16.35, 14.82)
  source(17.85, "R6", 17.65, 14.82)
  source(28.15, "R8", 28.35, 14.82)
  source(29.85, "R9", 29.65, 14.82)

  dependency(
    ((5.0, 13.18), (5.0, 10.22)),
    (6.55, 11.7),
    "R3 (x)",
    x-color,
  )
  content(
    (8.05, 9.4),
    align(center, text(size: 6.1pt, weight: "bold")[R4]),
  )
  line(
    (7.55, 9.4),
    (6.6, 9.4),
    stroke: (paint: _muted, thickness: .65pt),
    mark: (end: ">"),
  )

  dependency(
    ((17.0, 13.18), (22.1, 10.22)),
    (18.55, 11.95),
    "R7 (b)",
    b-color,
  )
  dependency(
    ((29.0, 13.18), (23.9, 10.22)),
    (27.45, 11.95),
    "R10 (c)",
    c-color,
  )

  dependency(
    ((5.0, 8.58), (13.05, 5.22)),
    (8.4, 7.25),
    "R5 (a)",
    a-color,
  )
  dependency(
    ((23.0, 8.58), (14.95, 5.22)),
    (19.7, 7.25),
    "R11 (y)",
    y-color,
  )
  dependency(
    ((14.0, 3.58), (14.0, .05)),
    (15.45, 2.45),
    "R5 (d)",
    d-color,
  )

})
