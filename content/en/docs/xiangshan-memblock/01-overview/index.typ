#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "en", route: "docs/xiangshan-memblock/01-overview/", title: "What MemBlock Really Is")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/01-overview/")

= What MemBlock Really Is: Building the Memory Subsystem Map First

#series-navbar("en", nav)

The first reading mistake is to treat MemBlock as a single giant load-store unit. The top-level file is large, but the more useful mental model is "the core's internal memory subsystem coordinator." It owns the place where backend issue streams, load/store execution units, translation checks, cache interfaces, uncache handling, vector-memory machinery, and rollback decisions all meet.

== Start from the parameter block, not the wiring wall

`HasMemBlockParameters` is a better entry point than the full implementation body because it tells you what kinds of units MemBlock believes it owns:

- three scalar `LoadUnit`s
- two `StoreUnit`s for store-address work
- two store-data execution units
- vector load and vector store lanes
- dedicated constants for `AtomicWBPort`, `MisalignWBPort`, and `UncacheWBPort`

That last line matters more than it first looks. The code is already telling you that the three load pipelines are not symmetric copies.

== The three load lanes are deliberately specialized

One of the most useful early conclusions is that `loadUnits(0)`, `loadUnits(1)`, and `loadUnits(2)` are shared lanes with extra duties:

- `loadUnits(0)` is the special lane reused by atomics and by the vector segment path
- `loadUnits(1)` is the lane that participates in misaligned-load writeback handling
- `loadUnits(2)` is the lane that carries the scalar uncache return path

So even before reading the detailed loops, you already know this is not a "three identical ports" design. It is a design with explicit role assignment, and that role assignment will keep surfacing in writeback, DTLB, DCache, and replay logic.

== Why MemBlock feels like a coordinator

MemBlock looks central because it is central. It sits between:

- the backend issue side that sends memory micro-ops in
- the memory-facing side that touches DCache, uncache, and lower levels
- the translation and permission side built around DTLB, PTW, and PMP
- the ordering side built around the LSQ, forwarding, replay, and rollback
- the vector side that still borrows scalar resources underneath

That is why the file reads less like one pipeline and more like a switchyard. Many of the hardest bugs are not "inside one unit." They come from resource sharing and control coordination across units.

#figure(
  image("imgs/memblock.svg"),
  caption: [A reference MemBlock block diagram from the XiangShan design documentation, useful as a subsystem map before tracing individual lanes],
)

== How I would start reading

If I were restarting from zero, I would use this order:

- read the parameter counts and special writeback-port constants
- identify the backend boundary interfaces
- trace one load lane, one store-address lane, and one store-data lane end to end
- only then expand outward into DTLB/PTW/PMP, DCache, uncache, and vector memory

The point of the first pass is not completeness. It is to establish the map well enough that later details have somewhere to attach.

#series-navbar("en", nav)
