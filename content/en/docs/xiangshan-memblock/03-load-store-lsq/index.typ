#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "en", route: "docs/xiangshan-memblock/03-load-store-lsq/", title: "Load, Store, Std, and LSQ")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/03-load-store-lsq/")

= Load, Store, Std, and the LSQ: How One Memory Instruction Gets Split

#series-navbar("en", nav)

One of the clearest patterns in MemBlock is that a "memory instruction" is not handled as one opaque thing. Load, store-address, and store-data responsibilities are separated early, then re-coordinated through the LSQ and the surrounding control fabric.

== The load loop is where the subsystem becomes concrete

The loop that wires each `loadUnits(i)` is worth revisiting several times because it shows almost every major dependency in one place:

- backend issue and feedback
- DCache access
- LSQ forward and replay connections
- uncache forward and MSHR-related forwarding
- DTLB and PMP hookups
- misaligned-load buffering
- writeback-side error reporting

Reading that loop makes one thing obvious: a load unit is not a lone executor. It is a consumer of many shared services and a producer of many control-visible outcomes.

== Why store address and store data are separate

The store side is split between `StoreUnit` and store-data execution units because address readiness and data readiness do not necessarily happen together in an out-of-order core.

- `StoreUnit` handles address-side work such as translation-related progress and store-queue entry preparation
- the store-data execution path carries the actual data that will eventually be committed to memory ordering structures

That is why the backend exposes `issueSta` and `issueStd` separately in the first place. The split is architectural inside the microarchitecture, not just a coding preference.

== The LSQ is more than a queue

The LSQ is the ordering and coordination structure sitting in the middle of all this:

- loads query it for forwarding
- stores send address and data into it
- replay information comes back out of it
- rollback and nuke paths are connected through it
- uncache requests are also launched from this territory

So the LSQ is not simply "where memory ops wait." It is where ordering, dependency resolution, replay, and visibility all intersect.

#tufted.margin-note[
  #image("imgs/LSQ.svg")
  The XiangShan LSQ diagram is compact enough to work as a side reference: queues, replay structures, and committed-store buffering still fit in one frame.
]

== What I would review carefully here

This chapter gives me a first serious review checklist:

- Are load-lane responsibilities still correct after special paths borrow them?
- Are store-address and store-data halves guaranteed to reunite coherently in the LSQ?
- Can replay or rollback choose the wrong winner when several subpaths complain at once?
- Does a path that looks symmetric actually hide lane-specific exceptions?

The deeper I read MemBlock, the less I trust symmetry by default. That lesson starts here.

#series-navbar("en", nav)
