#import "@preview/cetz:0.5.2"

#let _ink = rgb("#202124")
#let _muted = rgb("#68707A")
#let _rule = rgb("#CBD2DB")
#let _panel = rgb("#FBFCFD")
#let _blue = rgb("#2457A6")
#let _blue-fill = rgb("#EAF1FB")
#let _orange = rgb("#B85C00")
#let _orange-fill = rgb("#FFF0DF")
#let _green = rgb("#16724A")
#let _green-fill = rgb("#E7F4ED")
#let _red = rgb("#B42318")
#let _red-fill = rgb("#FDECEC")

#let _page-flow-canvas(draw-body) = cetz.canvas(length: .43cm, padding: .18, {
  import cetz.draw: *

  let box(a, b, body, fill-color, line-color, size: 5pt) = {
    rect(a, b, radius: .07, fill: fill-color, stroke: (paint: line-color, thickness: .72pt))
    content(
      ((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2),
      align(center, text(size: size, weight: "bold", fill: line-color)[#body]),
    )
  }

  let step(pos, number, color) = {
    circle(pos, radius: .42, fill: white, stroke: (paint: color, thickness: .8pt))
    content(pos, align(center, text(size: 4.7pt, weight: "bold", fill: color)[#number]))
  }

  draw-body(box, step)
})

#let page-hit-flow() = _page-flow-canvas((box, step) => {
  import cetz.draw: *

  // Keep the CPU-local path visually separate from the memory-system path.
  rect((.4, 2.25), (18.1, 11.25), radius: .08, fill: _panel, stroke: (paint: _rule, dash: "dashed"))
  content((1.0, 10.65), text(size: 5.3pt, weight: "bold", fill: _muted)[CPU chip], anchor: "west")

  box((1.4, 5.65), (6.4, 8.35), [processor], _blue-fill, _blue, size: 5.7pt)
  box((10.2, 4.7), (15.0, 9.3), [MMU\ + page-table walker], _orange-fill, _orange, size: 5.2pt)
  box((21.0, 3.45), (29.0, 10.1), [cache hierarchy\ + main memory], _green-fill, _green, size: 5.4pt)

  // 1: the instruction presents a virtual address to the MMU.
  line((6.4, 7.55), (10.2, 7.55), stroke: (paint: _blue, thickness: .85pt), mark: (end: ">", scale: .43))
  step((8.0, 8.22), [1], _blue)
  content((8.55, 8.22), text(size: 4.6pt, weight: "bold", fill: _blue)[virtual address], anchor: "west")

  // 2 and 3 use independent lanes so request and response arrows are explicit.
  line((15.0, 8.15), (21.0, 8.15), stroke: (paint: _orange, thickness: .82pt), mark: (end: ">", scale: .42))
  step((16.65, 8.82), [2], _orange)
  content((17.2, 8.82), text(size: 4.5pt, weight: "bold", fill: _orange)[PTE address], anchor: "west")
  line((21.0, 6.95), (15.0, 6.95), stroke: (paint: _orange, thickness: .82pt), mark: (end: ">", scale: .42))
  step((17.0, 6.28), [3], _orange)
  content((17.55, 6.28), text(size: 4.5pt, weight: "bold", fill: _orange)[present PTE], anchor: "west")

  // 4: after translation, the demand access uses a physical address.
  line((15.0, 5.55), (21.0, 5.55), stroke: (paint: _green, thickness: .85pt), mark: (end: ">", scale: .43))
  step((17.05, 4.88), [4], _green)
  content((17.6, 4.88), text(size: 4.5pt, weight: "bold", fill: _green)[physical address], anchor: "west")

  // 5: returned data runs below the CPU boundary, away from every request lane.
  line((25.0, 3.45), (25.0, 1.05), (3.9, 1.05), (3.9, 5.65), stroke: (paint: _green, thickness: .9pt), mark: (end: ">", scale: .44))
  step((13.5, 1.05), [5], _green)
  content((14.05, 1.62), text(size: 4.7pt, weight: "bold", fill: _green)[requested data], anchor: "west")

  content((25.0, 2.6), align(center, text(size: 4.25pt, fill: _muted)[the PTE may be supplied by a cache;\ the referenced page is resident in DRAM]))
})

#let page-fault-flow() = _page-flow-canvas((box, step) => {
  import cetz.draw: *

  rect((.35, 2.0), (15.8, 11.0), radius: .08, fill: _panel, stroke: (paint: _rule, dash: "dashed"))
  content((.95, 10.4), text(size: 5.3pt, weight: "bold", fill: _muted)[CPU chip], anchor: "west")

  box((1.35, 5.25), (5.9, 7.8), [processor], _blue-fill, _blue, size: 5.5pt)
  box((9.5, 4.45), (14.2, 8.65), [MMU\ + page-table walker], _orange-fill, _orange, size: 5.0pt)
  box((18.1, 3.55), (23.0, 9.55), [cache hierarchy\ + main memory], _orange-fill, _orange, size: 4.8pt)
  box((25.7, 11.2), (31.7, 13.35), [OS page-fault\ exception handler], _red-fill, _red, size: 4.8pt)
  box((26.3, 3.55), (31.3, 8.45), [backing store\ disk / SSD], _green-fill, _green, size: 5.0pt)

  // 1-3: the ordinary lookup discovers a non-present PTE.
  line((5.9, 6.95), (9.5, 6.95), stroke: (paint: _blue, thickness: .84pt), mark: (end: ">", scale: .42))
  step((7.35, 7.62), [1], _blue)
  content((7.9, 7.62), text(size: 4.4pt, weight: "bold", fill: _blue)[virtual address], anchor: "west")
  line((14.2, 7.55), (18.1, 7.55), stroke: (paint: _orange, thickness: .82pt), mark: (end: ">", scale: .42))
  step((15.55, 8.22), [2], _orange)
  content((16.1, 8.22), text(size: 4.35pt, weight: "bold", fill: _orange)[PTE address], anchor: "west")
  line((18.1, 6.35), (14.2, 6.35), stroke: (paint: _red, thickness: .86pt), mark: (end: ">", scale: .42))
  step((15.6, 5.68), [3], _red)
  content((16.15, 5.68), text(size: 4.3pt, weight: "bold", fill: _red)[present = 0], anchor: "west")

  // 4: trap to software on a dedicated upper lane.
  line((12.8, 8.65), (12.8, 12.25), (25.7, 12.25), stroke: (paint: _red, thickness: .9pt), mark: (end: ">", scale: .43))
  step((18.3, 12.25), [4], _red)
  content((18.85, 12.9), text(size: 4.55pt, weight: "bold", fill: _red)[page-fault exception], anchor: "west")

  // 5 and 6: an optional dirty victim leaves before the demanded page enters.
  line((23.0, 7.2), (26.3, 7.2), stroke: (paint: _red, thickness: .86pt), mark: (end: ">", scale: .42))
  step((24.05, 7.88), [5], _red)
  content((24.6, 7.88), text(size: 4.25pt, weight: "bold", fill: _red)[victim writeback], anchor: "west")
  line((26.3, 4.8), (23.0, 4.8), stroke: (paint: _green, thickness: .9pt), mark: (end: ">", scale: .43))
  step((24.0, 4.12), [6], _green)
  content((24.55, 4.12), text(size: 4.3pt, weight: "bold", fill: _green)[page in], anchor: "west")

  // 7: handler completion returns control above the exception lane and retries.
  line((28.7, 13.35), (28.7, 14.45), (3.625, 14.45), (3.625, 7.8), stroke: (paint: _blue, thickness: .82pt, dash: "dashed"), mark: (end: ">", scale: .42))
  step((10.5, 14.45), [7], _blue)
  content((11.05, 15.05), text(size: 4.55pt, weight: "bold", fill: _blue)[update PTE, resume, and retry], anchor: "west")

  content((20.55, 2.35), align(center, text(size: 4.25pt, fill: _muted)[the faulting instruction completes only after the page is resident]))
})

#let page-fault-dma-flow() = _page-flow-canvas((box, step) => {
  import cetz.draw: *

  box((.8, 9.2), (7.0, 12.0), [processor / OS], _blue-fill, _blue, size: 5.5pt)
  box((1.6, 6.55), (6.2, 8.15), [CPU cache], white, _muted, size: 5.0pt)
  line((3.9, 9.2), (3.9, 8.15), stroke: _muted)

  // A common interconnect joins memory and I/O, but the control/data lanes are
  // drawn outside it so labels stay readable.
  rect((.8, 4.95), (31.2, 5.85), radius: .03, fill: _panel, stroke: _muted)
  content((5.0, 6.25), text(size: 4.4pt, weight: "bold", fill: _muted)[memory / I/O interconnect], anchor: "west")
  line((3.9, 6.55), (3.9, 5.85), stroke: _muted)

  box((1.4, .65), (7.1, 3.75), [main memory\ destination frame Y], _green-fill, _green, size: 5.1pt)
  box((18.7, .65), (24.8, 3.75), [I/O controller\ + DMA engine], _orange-fill, _orange, size: 5.0pt)
  box((27.1, .65), (31.2, 3.75), [disk / SSD\ source block X], _blue-fill, _blue, size: 4.8pt)
  line((4.25, 4.95), (4.25, 3.75), stroke: _muted)
  line((21.75, 4.95), (21.75, 3.75), stroke: _muted)
  line((29.15, 4.95), (29.15, 3.75), stroke: _muted)

  // 1: software programs source, destination, and length. This is a short
  // command path, not the bulk page-data path. It enters the controller from
  // the right so it never crosses the completion-interrupt route.
  line((7.0, 10.85), (25.65, 10.85), (25.65, 3.0), (24.8, 3.0), stroke: (paint: _red, thickness: .9pt), mark: (end: ">", scale: .43))
  step((10.15, 10.85), [1], _red)
  content((10.7, 11.5), text(size: 4.7pt, weight: "bold", fill: _red)[start block read: X -> Y, length = one page], anchor: "west")

  // 2: data flows from storage through the DMA engine and over the interconnect
  // directly into memory. The processor is not in this bulk-transfer path.
  line((27.1, 2.2), (24.8, 2.2), stroke: (paint: _green, thickness: .95pt), mark: (end: ">", scale: .44))
  line((19.8, 3.75), (19.8, 5.4), (4.25, 5.4), (4.25, 3.75), stroke: (paint: _green, thickness: .95pt), mark: (end: ">", scale: .44))
  step((13.3, 5.4), [2], _green)
  content((12.0, 6.35), text(size: 4.7pt, weight: "bold", fill: _green)[DMA transfers the page directly into memory], anchor: "west")

  // 3: completion is a small control message back to the processor.
  // It enters the processor horizontally, away from the box corners.
  line((18.7, 3.0), (17.65, 3.0), (17.65, 9.75), (7.0, 9.75), stroke: (paint: _blue, thickness: .88pt), mark: (end: ">", scale: .43))
  step((14.5, 9.75), [3], _blue)
  content((15.05, 10.28), text(size: 4.7pt, weight: "bold", fill: _blue)[completion interrupt], anchor: "west")

  content((15.9, -.3), align(center, text(size: 4.6pt, weight: "bold", fill: _muted)[DMA moves bulk data without copying each word through a processor register or CPU cache.]))
})
