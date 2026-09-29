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

#let tlb-lookup-example() = cetz.canvas(length: .4cm, padding: .18, {
  import cetz.draw: *

  let centered(pos, body, size: 5pt, weight: "regular", fill: _ink) = content(
    pos,
    align(center, text(size: size, weight: weight, fill: fill)[#body]),
  )

  let field(a, b, heading, value, bits, fill-color, line-color) = {
    rect(a, b, fill: fill-color, stroke: line-color)
    let cx = (a.at(0) + b.at(0)) / 2
    let cy = (a.at(1) + b.at(1)) / 2
    centered((cx, cy + .34), heading, size: 4.7pt, weight: "bold", fill: line-color)
    centered((cx, cy - .3), value, size: 6pt, weight: "bold", fill: line-color)
    centered((cx, b.at(1) + .38), bits, size: 4.3pt, fill: _muted)
  }

  let entry-card(x, y, number, vpn, ppn, matched: false) = {
    let accent = if matched { _blue } else { _muted }
    let card-fill = if matched { _blue-fill } else { white }
    rect((x, y), (x + 8.7, y + 3.0), radius: .06, fill: card-fill, stroke: accent)
    centered((x + 4.35, y + 2.58), [Entry #number], size: 5.2pt, weight: "bold", fill: accent)
    line((x, y + 2.15), (x + 8.7, y + 2.15), stroke: accent)
    line((x + 1.35, y), (x + 1.35, y + 2.15), stroke: accent)
    line((x + 5.45, y), (x + 5.45, y + 2.15), stroke: accent)
    centered((x + .675, y + 1.77), [V], size: 4.2pt, weight: "bold", fill: accent)
    centered((x + 3.4, y + 1.77), [stored VPN], size: 4.2pt, weight: "bold", fill: accent)
    centered((x + 7.075, y + 1.77), [stored PPN], size: 4.2pt, weight: "bold", fill: accent)
    centered((x + .675, y + .78), [1], size: 5.7pt, weight: "bold")
    centered((x + 3.4, y + .78), vpn, size: 5.5pt, weight: "bold", fill: accent)
    centered((x + 7.075, y + .78), ppn, size: 5.5pt, weight: "bold", fill: accent)
  }

  let match-box(x, number, result, matched: false) = {
    let accent = if matched { _blue } else { _muted }
    let box-fill = if matched { _blue-fill } else { _panel }
    rect((x, 6.75), (x + 8.7, 8.75), radius: .06, fill: box-fill, stroke: accent)
    centered((x + 4.35, 8.17), [compare in parallel], size: 4.5pt, weight: "bold", fill: accent)
    centered((x + 4.35, 7.46), [$"Hit"_#number = V_#number " AND " ("query VPN" = "VPN"_#number) = #result$], size: 4.65pt, weight: "bold", fill: accent)
  }

  // A 31-bit virtual address: 19-bit VPN and an unchanged 12-bit page offset.
  centered((9.85, 18.35), [virtual address], size: 5.8pt, weight: "bold")
  field((2.2, 15.9), (11.45, 17.7), [virtual page number], [0x00002], [19 bits], _blue-fill, _blue)
  field((11.45, 15.9), (17.5, 17.7), [page offset], [0x47C], [12 bits], _green-fill, _green)

  // Query VPN fans out to all entries; there is no index selection first.
  line((6.825, 15.9), (6.825, 15.05), (1.35, 15.05), (1.35, 9.5), stroke: (paint: _blue, thickness: .8pt))
  line((1.35, 9.5), (6.55, 9.5), (6.55, 8.75), stroke: _blue, mark: (end: ">", scale: .43))
  line((1.35, 9.5), (17.05, 9.5), (17.05, 8.75), stroke: _blue, mark: (end: ">", scale: .43))
  centered((3.75, 9.98), [same query VPN], size: 4.4pt, weight: "bold", fill: _blue)

  centered((11.8, 14.65), [two-entry, fully associative TLB], size: 5.3pt, weight: "bold")
  entry-card(2.2, 10.6, [1], [0x7FFFD], [0x0000])
  entry-card(12.7, 10.6, [0], [0x00002], [0x7FFF], matched: true)
  match-box(2.2, [1], [0])
  match-box(12.7, [0], [1], matched: true)

  // Each entry contributes its valid bit and stored VPN to the local match logic.
  line((2.875, 10.6), (2.875, 9.85), (4.65, 9.85), (4.65, 8.75), stroke: _muted, mark: (end: ">", scale: .38))
  line((5.6, 10.6), (5.6, 8.75), stroke: _muted, mark: (end: ">", scale: .38))
  line((13.375, 10.6), (13.375, 9.85), (15.15, 9.85), (15.15, 8.75), stroke: _blue, mark: (end: ">", scale: .38))
  line((16.1, 10.6), (16.1, 8.75), stroke: _blue, mark: (end: ">", scale: .38))

  // Hit aggregation is independent of selecting the PPN from the matching entry.
  rect((2.7, 3.75), (10.8, 5.55), radius: .06, fill: _orange-fill, stroke: _orange)
  centered((6.75, 4.95), [hit reduction (OR)], size: 4.7pt, weight: "bold", fill: _orange)
  centered((6.75, 4.34), [$"Hit" = "Hit"_1 " OR " "Hit"_0 = 1$], size: 5pt, weight: "bold", fill: _orange)
  line((6.55, 6.75), (6.55, 5.55), stroke: _muted, mark: (end: ">", scale: .42))
  line((17.05, 6.75), (17.05, 6.05), (8.55, 6.05), (8.55, 5.55), stroke: _blue, mark: (end: ">", scale: .42))

  // Candidate PPNs are data inputs to a one-hot-controlled selector. Keep the
  // data paths outside the comparison and hit-reduction logic so the two roles
  // remain visually distinct.
  rect((23.2, 10.4), (30.2, 13.3), radius: .06, fill: _blue-fill, stroke: _blue)
  centered((26.7, 12.72), [PPN selector], size: 5.0pt, weight: "bold", fill: _blue)
  centered((26.7, 11.95), [candidate PPN data], size: 4.3pt, fill: _muted)
  centered((26.7, 11.12), [$"selected PPN" = "0x7FFF"$], size: 4.8pt, weight: "bold", fill: _blue)

  // Entry 0 is the matching entry, so its PPN travels directly to the mux.
  line((21.4, 11.38), (23.2, 11.38), stroke: _blue, mark: (end: ">", scale: .4))

  // Entry 1's candidate leaves through the gap, runs above both entries, and
  // enters from the top without crossing either parallel comparator.
  line(
    (10.9, 11.38),
    (11.75, 11.38),
    (11.75, 14.05),
    (24.45, 14.05),
    (24.45, 13.3),
    stroke: _muted,
    mark: (end: ">", scale: .4),
  )

  // The match results form a control vector, not another PPN data path.
  rect((23.2, 7.35), (30.2, 9.05), radius: .06, fill: _orange-fill, stroke: _orange)
  centered((26.7, 8.53), [one-hot hit vector], size: 4.7pt, weight: "bold", fill: _orange)
  centered((26.7, 7.9), [$("Hit"_1, "Hit"_0) = (0, 1)$], size: 4.8pt, weight: "bold", fill: _orange)
  line((26.7, 9.05), (26.7, 10.4), stroke: (paint: _orange, thickness: .85pt), mark: (end: ">", scale: .42))
  content((27.08, 9.72), text(size: 4.2pt, weight: "bold", fill: _orange)[select], anchor: "west")

  // The selected 15-bit PPN is concatenated with the original 12-bit offset.
  centered((25.45, 2.75), [physical address (27 bits)], size: 5.2pt, weight: "bold")
  field((20.4, .25), (25.8, 2.0), [physical page number], [0x7FFF], [15 bits], _blue-fill, _blue)
  field((25.8, .25), (30.5, 2.0), [page offset], [0x47C], [12 bits], _green-fill, _green)
  line(
    (23.2, 10.78),
    (22.25, 10.78),
    (22.25, 3.35),
    (19.55, 3.35),
    (19.55, 1.125),
    (20.4, 1.125),
    stroke: _blue,
    mark: (end: ">", scale: .43),
  )
  centered((19.0, 3.86), [selected PPN], size: 4.4pt, weight: "bold", fill: _blue)
  line((14.475, 15.9), (14.475, 15.45), (30.9, 15.45), (30.9, 1.125), (30.5, 1.125), stroke: _green, mark: (end: ">", scale: .43))
  content((30.5, 6.25), text(size: 4.4pt, weight: "bold", fill: _green)[offset bypasses the TLB], anchor: "east")
  centered((25.45, -.55), [$"PA" = "0x7FFF47C"$], size: 5.4pt, weight: "bold", fill: _green)
})

#let vipt-cache-lookup() = cetz.canvas(length: .43cm, padding: .18, {
  import cetz.draw: *

  let box(a, b, body, fill-color: white, line-color: _ink, size: 5.2pt) = {
    rect(a, b, radius: .06, fill: fill-color, stroke: line-color)
    content(
      ((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2),
      align(center, text(size: size, weight: "bold", fill: line-color)[#body]),
    )
  }

  // Virtual address. Both the set index and block offset are untranslated
  // page-offset bits, so cache indexing can overlap the TLB lookup.
  content((15.0, 14.65), align(center, text(size: 5.8pt, weight: "bold")[virtual byte address]))
  rect((1.0, 12.7), (29.0, 14.15), fill: white, stroke: _ink)
  rect((1.0, 12.7), (11.25, 14.15), fill: _blue-fill, stroke: _blue)
  rect((11.25, 12.7), (23.4, 14.15), fill: _orange-fill, stroke: _orange)
  rect((23.4, 12.7), (29.0, 14.15), fill: _green-fill, stroke: _green)
  content((6.125, 13.425), align(center, text(size: 5.3pt, weight: "bold", fill: _blue)[virtual page number (VPN)]))
  content((17.325, 13.425), align(center, text(size: 5.3pt, weight: "bold", fill: _orange)[set index]))
  content((26.2, 13.425), align(center, text(size: 5.3pt, weight: "bold", fill: _green)[block offset]))
  line((11.25, 12.25), (11.25, 11.78), (29.0, 11.78), (29.0, 12.25), stroke: _green)
  content((20.125, 11.35), align(center, text(size: 4.7pt, weight: "bold", fill: _green)[page offset: identical in VA and PA]))

  content((11.5, 10.5), align(center, text(size: 5.2pt, weight: "bold", fill: _muted)[same-cycle parallel lookup]))
  box((1.8, 7.65), (9.0, 9.7), [TLB lookup\ VPN -> PPN], fill-color: _blue-fill, line-color: _blue)
  box((13.0, 7.65), (22.2, 9.7), [read indexed cache set\ all ways: physical tags + data], fill-color: _orange-fill, line-color: _orange, size: 4.9pt)
  line((6.125, 12.7), (6.125, 9.7), stroke: _blue, mark: (end: ">", scale: .45))
  line((17.325, 12.7), (17.325, 9.7), stroke: _orange, mark: (end: ">", scale: .45))

  box((2.2, 4.45), (8.6, 6.35), [physical tag\ PPN + any unused high\ page-offset bits], fill-color: _blue-fill, line-color: _blue, size: 4.35pt)
  box((10.2, 4.55), (16.8, 6.25), [compare with\ stored physical tags], fill-color: _orange-fill, line-color: _orange, size: 4.8pt)
  box((19.0, 4.55), (25.0, 6.25), [matching-way\ data select], fill-color: _green-fill, line-color: _green, size: 4.9pt)
  box((23.25, 1.75), (29.0, 3.25), [hit data], fill-color: _green-fill, line-color: _green)

  line((5.4, 7.65), (5.4, 6.35), stroke: _blue, mark: (end: ">", scale: .45))
  content((5.8, 7.1), text(size: 4.4pt, weight: "bold", fill: _blue)[TLB hit + permissions], anchor: "west")
  line((8.6, 5.4), (10.2, 5.4), stroke: _blue, mark: (end: ">", scale: .45))
  line((15.6, 7.65), (15.6, 6.9), (13.5, 6.9), (13.5, 6.25), stroke: _orange, mark: (end: ">", scale: .45))
  content((14.55, 7.18), align(center, text(size: 4.3pt, fill: _orange)[way tags]))
  line((19.6, 7.65), (19.6, 6.9), (22.0, 6.9), (22.0, 6.25), stroke: _green, mark: (end: ">", scale: .45))
  content((21.05, 7.18), align(center, text(size: 4.3pt, fill: _green)[way data]))
  line((16.8, 5.4), (19.0, 5.4), stroke: _orange, mark: (end: ">", scale: .45))
  content((17.9, 5.85), align(center, text(size: 4.3pt, weight: "bold", fill: _orange)[way]))
  line((22.0, 4.55), (22.0, 4.0), (26.125, 4.0), (26.125, 3.25), stroke: _green, mark: (end: ">", scale: .45))
  line((26.2, 12.7), (30.0, 12.7), (30.0, 2.5), (29.0, 2.5), stroke: _green, mark: (end: ">", scale: .45))
  content((29.7, 6.25), text(size: 4.3pt, weight: "bold", fill: _green)[byte / word select], anchor: "east")

  rect((.75, -.35), (29.25, 1.05), radius: .06, fill: _panel, stroke: _rule)
  content((15.0, .58), align(center, text(size: 5pt, weight: "bold")[$"index bits" + "block-offset bits" <= "page-offset bits"$]))
  content((15.0, .08), align(center, text(size: 4.7pt, fill: _muted)[$C <= A times "page size"$; otherwise aliases need additional handling]))
})

#let virtualized-address-translation() = cetz.canvas(length: .46cm, padding: .18, {
  import cetz.draw: *

  let box(a, b, body, fill-color, line-color, size: 5.0pt) = {
    rect(a, b, radius: .06, fill: fill-color, stroke: line-color)
    content(
      ((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2),
      align(center, text(size: size, weight: "bold", fill: line-color)[#body]),
    )
  }

  // Ownership bands make the two independent address spaces explicit.
  rect((.4, 8.1), (29.6, 13.7), radius: .08, fill: rgb("#F6F9FD"), stroke: _rule)
  content((1.0, 13.15), text(size: 5.7pt, weight: "bold", fill: _blue)[guest virtual machine], anchor: "west")
  content((29.0, 13.15), text(size: 4.6pt, fill: _muted)[application + guest OS view], anchor: "east")

  rect((.4, 4.25), (29.6, 7.7), radius: .08, fill: rgb("#FFF9F2"), stroke: _rule)
  content((1.0, 7.15), text(size: 5.7pt, weight: "bold", fill: _orange)[hypervisor / host], anchor: "west")

  rect((.4, .25), (29.6, 3.85), radius: .08, fill: rgb("#F4FAF7"), stroke: _rule)
  content((1.0, 3.3), text(size: 5.7pt, weight: "bold", fill: _green)[physical machine], anchor: "west")

  box((1.2, 9.4), (6.1, 11.25), [guest virtual\ address (GVA)], _blue-fill, _blue)
  box((8.0, 9.15), (13.8, 11.5), [guest page table\ owned by guest OS], _blue-fill, _blue, size: 4.8pt)
  box((15.7, 9.4), (20.6, 11.25), [guest physical\ address (GPA)], _orange-fill, _orange)
  line((6.1, 10.325), (8.0, 10.325), stroke: _blue, mark: (end: ">", scale: .45))
  line((13.8, 10.325), (15.7, 10.325), stroke: _blue, mark: (end: ">", scale: .45))
  content((10.9, 12.0), align(center, text(size: 4.7pt, weight: "bold", fill: _blue)[translation 1: guest mapping]))

  box((15.7, 5.0), (21.6, 6.85), [host-controlled mapping\ GPA -> HPA], _orange-fill, _orange, size: 4.7pt)
  box((23.6, 5.0), (28.8, 6.85), [host / machine\ physical address (HPA)], _green-fill, _green, size: 4.7pt)
  line((18.15, 9.4), (18.15, 6.85), stroke: _orange, mark: (end: ">", scale: .45))
  line((21.6, 5.925), (23.6, 5.925), stroke: _orange, mark: (end: ">", scale: .45))
  content((24.5, 7.25), align(center, text(size: 4.7pt, weight: "bold", fill: _orange)[translation 2: machine placement]))

  box((23.6, 1.0), (28.8, 2.85), [physical memory\ DRAM frame], _green-fill, _green)
  line((26.2, 5.0), (26.2, 2.85), stroke: _green, mark: (end: ">", scale: .45))

  rect((1.3, 4.9), (13.2, 6.65), radius: .06, fill: white, stroke: _muted)
  content((7.25, 5.95), align(center, text(size: 4.8pt, weight: "bold")[effective translation applies both mappings]))
  content((7.25, 5.45), align(center, text(size: 4.5pt, fill: _muted)[the TLB normally caches the combined GVA -> HPA result]))

  content((15.0, .62), align(center, text(size: 4.8pt, weight: "bold")[$"GVA" arrow.r "GPA" arrow.r "HPA"$: the same GPA may map to a different HPA for each VM]))
})

#let shadow-vs-nested-paging() = cetz.canvas(length: .42cm, padding: .18, {
  import cetz.draw: *

  let panel(x1, x2, title, subtitle, title-color) = {
    rect((x1, .35), (x2, 16.8), radius: .08, fill: _panel, stroke: _rule)
    content(((x1 + x2) / 2, 16.15), align(center, text(size: 6.2pt, weight: "bold", fill: title-color)[#title]))
    content(((x1 + x2) / 2, 15.4), align(center, text(size: 4.6pt, fill: _muted)[#subtitle]))
  }

  let box(a, b, body, fill-color, line-color, size: 4.8pt) = {
    rect(a, b, radius: .06, fill: fill-color, stroke: line-color)
    content(
      ((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2),
      align(center, text(size: size, weight: "bold", fill: line-color)[#body]),
    )
  }

  panel(.0, 14.9, [Shadow paging], [one hardware walk; software maintains a derived table], _blue)
  panel(15.6, 31.4, [Nested paging], [two-dimensional hardware translation; independent tables], _orange)

  // Shadow paging: hardware consumes only the pre-composed GVA -> HPA map.
  box((.75, 13.0), (5.0, 14.3), [guest virtual\ address], _blue-fill, _blue)
  box((5.95, 12.75), (10.7, 14.55), [shadow page table\ GVA -> HPA], _blue-fill, _blue)
  box((11.55, 13.0), (14.15, 14.3), [host physical\ address], _green-fill, _green, size: 4.4pt)
  line((5.0, 13.65), (5.95, 13.65), stroke: _blue, mark: (end: ">", scale: .43))
  line((10.7, 13.65), (11.55, 13.65), stroke: _green, mark: (end: ">", scale: .43))

  content((5.8, 11.95), align(center, text(size: 4.6pt, weight: "bold", fill: _blue)[TLB miss: one hardware-visible walk]))
  content((5.8, 11.4), align(center, text(size: 4.3pt, weight: "bold", fill: _blue)[$"sCR3"$ -> shadow root (HPA)]))
  for i in range(4) {
    let x = 2.0 + i * 2.75
    rect((x, 9.65), (x + 2.1, 10.75), radius: .04, fill: white, stroke: _blue)
    content((x + 1.05, 10.2), align(center, text(size: 4.5pt, weight: "bold", fill: _blue)[level #(i + 1)]))
    if i < 3 {
      line((x + 2.1, 10.2), (x + 2.75, 10.2), stroke: _blue, mark: (end: ">", scale: .38))
    }
  }
  line((10.3, 12.75), (10.3, 11.0), (3.05, 11.0), (3.05, 10.75), stroke: _blue, mark: (end: ">", scale: .42))
  content((7.45, 9.05), align(center, text(size: 5pt, weight: "bold", fill: _blue)[one N-level page-table walk]))

  box((.75, 6.15), (5.25, 7.65), [guest page table\ GVA -> GPA], _orange-fill, _orange, size: 4.5pt)
  box((9.65, 6.15), (14.15, 7.65), [host mapping\ GPA -> HPA], _green-fill, _green, size: 4.5pt)
  box((5.7, 3.55), (9.2, 5.05), [hypervisor\ synchronizes], _red-fill, _red, size: 4.6pt)
  line((3.0, 6.15), (3.0, 4.3), (5.7, 4.3), stroke: (paint: _red, dash: "dashed"), mark: (end: ">", scale: .42))
  line((11.9, 6.15), (11.9, 4.3), (9.2, 4.3), stroke: (paint: _red, dash: "dashed"), mark: (end: ">", scale: .42))
  line((7.45, 5.05), (7.45, 5.5), (14.45, 5.5), (14.45, 12.15), (9.8, 12.15), (9.8, 12.75), stroke: (paint: _red, dash: "dashed"), mark: (end: ">", scale: .42))
  content((7.45, 2.65), align(center, text(size: 4.6pt, weight: "bold", fill: _red)[guest PTE writes trap; shadow entries must stay consistent]))
  content((7.45, 1.55), align(center, text(size: 4.8pt, weight: "bold", fill: _blue)[fast misses, expensive updates]))

  // Nested paging: every guest PTE location is itself a GPA and must be
  // translated through the host-controlled nested table before it can be read.
  box((16.4, 13.0), (20.35, 14.3), [guest virtual\ address], _blue-fill, _blue)
  box((21.25, 12.65), (25.9, 14.65), [guest page-table walk\ gCR3 root is a GPA\ N levels], _blue-fill, _blue, size: 4.2pt)
  box((27.0, 13.0), (30.6, 14.3), [guest physical\ address], _orange-fill, _orange, size: 4.4pt)
  line((20.35, 13.65), (21.25, 13.65), stroke: _blue, mark: (end: ">", scale: .43))
  line((25.9, 13.65), (27.0, 13.65), stroke: _orange, mark: (end: ">", scale: .43))

  content((30.45, 11.75), text(size: 4.5pt, weight: "bold", fill: _orange)[each guest PTE address is a GPA], anchor: "east")
  box((18.05, 9.2), (29.1, 10.95), [nested / EPT walk: translate that GPA through M host levels], _orange-fill, _orange, size: 4.6pt)
  line((23.575, 12.65), (23.575, 10.95), stroke: _orange, mark: (end: ">", scale: .43))
  line((18.05, 10.075), (16.9, 10.075), (16.9, 12.05), (22.0, 12.05), (22.0, 12.65), stroke: (paint: _orange, dash: "dashed"), mark: (end: ">", scale: .4))
  content((17.25, 11.15), text(size: 4.4pt, weight: "bold", fill: _orange)[repeat x N], anchor: "west")

  box((18.05, 6.25), (25.1, 7.85), [final nested walk\ GPA -> HPA], _orange-fill, _orange, size: 4.6pt)
  box((27.0, 6.4), (30.6, 7.7), [host physical\ address], _green-fill, _green, size: 4.4pt)
  line((28.8, 13.0), (30.95, 13.0), (30.95, 8.65), (21.575, 8.65), (21.575, 7.85), stroke: _orange, mark: (end: ">", scale: .43))
  line((25.1, 7.05), (27.0, 7.05), stroke: _green, mark: (end: ">", scale: .43))

  rect((16.7, 3.2), (30.3, 5.15), radius: .06, fill: white, stroke: _rule)
  content((23.5, 4.55), align(center, text(size: 5pt, weight: "bold")[$N times (M + 1) + M = N M + N + M$ references]))
  content((23.5, 3.85), align(center, text(size: 4.5pt, fill: _muted)[4 guest + 4 nested levels: 24; final demand access not included]))
  content((23.5, 1.55), align(center, text(size: 4.8pt, weight: "bold", fill: _orange)[easy updates, expensive TLB misses]))
})

#let skylake-mmu-overview() = cetz.canvas(length: .43cm, padding: .18, {
  import cetz.draw: *

  let yellow = rgb("#8A6D00")
  let yellow-fill = rgb("#FFF7CC")

  let box(a, b, body, fill-color, line-color, size: 5.2pt) = {
    rect(a, b, radius: .12, fill: fill-color, stroke: (paint: line-color, thickness: .8pt))
    content(
      ((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2),
      align(center, text(size: size, weight: "bold", fill: line-color)[#body]),
    )
  }

  // Skylake keeps these translation structures private to each core.
  rect((.45, .45), (30.55, 14.45), radius: .25, fill: _panel, stroke: (paint: _muted, thickness: .85pt))
  content((1.15, 13.72), text(size: 5pt, weight: "bold", fill: _muted)[per-core MMU], anchor: "west")

  box((2.0, 9.35), (9.0, 12.15), [L1 instruction\ TLB], yellow-fill, yellow, size: 5.6pt)
  box((2.0, 2.75), (9.0, 5.55), [L1 data\ TLB], _green-fill, _green, size: 5.6pt)
  box((12.0, 4.35), (18.9, 10.75), [L2 unified\ TLB], _blue-fill, _blue, size: 6pt)
  box((22.0, 9.35), (28.9, 12.15), [page-walk\ caches], _orange-fill, _orange, size: 5.6pt)
  box((21.0, 2.75), (29.9, 6.15), [hardware\ page-table walker], white, _orange, size: 5.5pt)

  // Instruction and data translations share the second-level TLB. The two
  // request lanes enter separately so neither arrow overlaps a box corner.
  line((9.0, 10.75), (10.45, 10.75), (10.45, 8.9), (12.0, 8.9), stroke: (paint: yellow, thickness: .9pt), mark: (end: ">", scale: .42))
  content((9.55, 11.35), text(size: 4.4pt, weight: "bold", fill: yellow)[I-TLB miss], anchor: "west")
  line((9.0, 4.15), (10.45, 4.15), (10.45, 6.2), (12.0, 6.2), stroke: (paint: _green, thickness: .9pt), mark: (end: ">", scale: .42))
  content((9.55, 3.55), text(size: 4.4pt, weight: "bold", fill: _green)[D-TLB miss], anchor: "west")

  // Only an L2 miss invokes the page-table walker.
  line((18.9, 7.55), (20.0, 7.55), (20.0, 4.45), (21.0, 4.45), stroke: (paint: _blue, thickness: .92pt), mark: (end: ">", scale: .43))
  content((20.05, 8.15), align(center, text(size: 4.5pt, weight: "bold", fill: _blue)[L2 miss]))

  // The walker probes cached non-leaf entries while following the hierarchy.
  line((25.45, 6.15), (25.45, 9.35), stroke: (paint: _orange, thickness: .92pt), mark: (start: "<", end: ">", scale: .42))
  content((26.0, 7.75), text(size: 4.25pt, weight: "bold", fill: _orange)[intermediate\ page-table entries], anchor: "west")

  // A completed walk returns the leaf translation to the shared TLB; the
  // requesting L1 TLB is subsequently supplied/refilled from that result.
  line((21.0, 3.45), (19.65, 3.45), (19.65, 1.45), (15.45, 1.45), (15.45, 4.35), stroke: (paint: _green, thickness: .82pt, dash: "dashed"), mark: (end: ">", scale: .42))
  content((18.2, .95), align(center, text(size: 4.4pt, weight: "bold", fill: _green)[leaf PTE / TLB refill]))
})

#let software-vs-hardware-ptw() = cetz.canvas(length: .43cm, padding: .18, {
  import cetz.draw: *

  let panel(a, b, title, subtitle, title-color) = {
    rect(a, b, radius: .1, fill: _panel, stroke: (paint: _rule, thickness: .7pt))
    content((a.at(0) + .65, b.at(1) - .55), text(size: 6.1pt, weight: "bold", fill: title-color)[#title], anchor: "west")
    content((a.at(0) + .65, b.at(1) - 1.02), text(size: 4.25pt, fill: _muted)[#subtitle], anchor: "west")
  }

  let box(a, b, body, fill-color, line-color, size: 4.8pt) = {
    rect(a, b, radius: .08, fill: fill-color, stroke: (paint: line-color, thickness: .75pt))
    content(
      ((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2),
      align(center, text(size: size, weight: "bold", fill: line-color)[#body]),
    )
  }

  let tag(pos, body, color) = {
    content(pos, align(center, text(size: 4.25pt, weight: "bold", fill: color)[#body]))
  }

  // Keep the two mechanisms in separate horizontal bands.  The upper band
  // serializes progress through an OS handler; the lower band exposes the
  // hardware walk and the independent work that can overlap it.
  panel((.45, 8.15), (31.55, 15.65), [Software PTW], [TLB miss traps to software; the handler/context switch delays the next access], _red)
  panel((.45, .35), (31.55, 7.85), [Hardware PTW], [the walker follows the page table in hardware while independent work continues], _blue)

  // Software-managed TLB miss: one serial request lane.
  tag((2.55, 13.98), [VPN = 1], _muted)
  box((.95, 12.05), (4.15, 13.65), [LOAD A], _blue-fill, _ink, size: 5.1pt)
  box((5.05, 12.05), (8.75, 13.65), [TLB miss], _red-fill, _red, size: 4.9pt)
  box((9.65, 11.78), (17.45, 13.92), [context switch +\ TLB-miss handler], _blue-fill, _blue, size: 4.55pt)
  tag((20.0, 13.98), [VPN = 5], _muted)
  box((18.25, 12.05), (22.0, 13.65), [LOAD B], white, _ink, size: 5.0pt)
  box((22.95, 12.05), (26.85, 13.65), [TLB hit], _green-fill, _green, size: 4.9pt)
  line((4.15, 12.85), (5.05, 12.85), stroke: _ink, mark: (end: ">", scale: .4))
  line((8.75, 12.85), (9.65, 12.85), stroke: _red, mark: (end: ">", scale: .4))
  line((17.45, 12.85), (18.25, 12.85), stroke: _blue, mark: (end: ">", scale: .4))
  line((22.0, 12.85), (22.95, 12.85), stroke: _ink, mark: (end: ">", scale: .4))
  content((13.55, 10.85), align(center, text(size: 4.35pt, weight: "bold", fill: _red)[OS work and context-switch overhead]))
  line((9.8, 10.48), (17.25, 10.48), stroke: (paint: _red, dash: "dashed", thickness: .65pt), mark: (start: "<", end: ">", scale: .35))
  content((13.55, 9.78), align(center, text(size: 4.05pt, fill: _muted)[the faulting access waits for software to install the translation]))

  // Hardware-managed miss: the page-table walk and the next load occupy
  // separate lanes, aligned to make the overlap visible without crossing
  // any boxes.
  tag((2.55, 6.32), [VPN = 1], _muted)
  box((.95, 4.55), (4.15, 6.15), [LOAD A], _blue-fill, _ink, size: 5.1pt)
  box((5.05, 4.55), (8.75, 6.15), [TLB miss], _red-fill, _red, size: 4.9pt)
  box((9.65, 4.28), (17.45, 6.42), [hardware\ page-table walk], _orange-fill, _orange, size: 4.65pt)
  box((18.25, 4.55), (22.15, 6.15), [TLB refill], _green-fill, _green, size: 4.75pt)
  box((22.95, 4.55), (27.05, 6.15), [A resumes], _blue-fill, _blue, size: 4.8pt)
  line((4.15, 5.35), (5.05, 5.35), stroke: _ink, mark: (end: ">", scale: .4))
  line((8.75, 5.35), (9.65, 5.35), stroke: _red, mark: (end: ">", scale: .4))
  line((17.45, 5.35), (18.25, 5.35), stroke: _orange, mark: (end: ">", scale: .4))
  line((22.15, 5.35), (22.95, 5.35), stroke: _green, mark: (end: ">", scale: .4))

  // LOAD B starts while the walker is active.  Its lane is deliberately
  // below the walk lane, so the overlap is an interval rather than a tangled
  // arrow crossing.
  tag((11.15, 3.25), [VPN = 5], _muted)
  box((9.65, 1.35), (13.75, 2.95), [LOAD B], white, _ink, size: 5.0pt)
  box((14.45, 1.35), (18.35, 2.95), [TLB hit], _green-fill, _green, size: 4.9pt)
  line((13.75, 2.15), (14.45, 2.15), stroke: _ink, mark: (end: ">", scale: .4))
  line((9.65, 3.8), (17.45, 3.8), stroke: (paint: _green, dash: "dashed", thickness: .7pt), mark: (start: "<", end: ">", scale: .35))
  content((15.7, 3.45), align(center, text(size: 4.1pt, weight: "bold", fill: _green)[overlap: LOAD B proceeds during the walk]))
  // A compact double-headed marker makes the latency advantage explicit.
  line((19.0, .82), (27.4, .82), stroke: (paint: _green, thickness: .72pt), mark: (start: "<", end: ">", scale: .38))
  content((23.2, 1.1), align(center, text(size: 4.35pt, weight: "bold", fill: _green)[saved cycles]))
  content((23.2, .52), align(center, text(size: 4.05pt, fill: _muted)[no context switch on a TLB miss]))
})
