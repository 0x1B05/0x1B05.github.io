#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "en", route: "docs/xiangshan-memblock/06-vector-memory/", title: "Vector Memory in MemBlock")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/06-vector-memory/")

= Why Vector Memory Is So Much More Complicated: Split, Merge, Segment, and FOF

#series-navbar("en", nav)

The vector-memory section looks intimidating because it is solving several problems at once. One vector memory instruction can expand into many internal operations, still needs ordering and feedback, and may borrow scalar memory resources while preserving vector semantics on the way back out.

== Split first, then merge later

The split and merge structures make much more sense once I stop expecting one vector instruction to stay intact:

- splitters break one vector memory instruction into smaller internal pieces
- scalar execution-side resources can then process those pieces
- merge buffers reconstruct the results into something that matches vector-visible semantics again

This is a necessary translation layer between vector instruction meaning and the scalarized substrate that actually performs much of the work.

== Segment and first-fault behavior add more special cases

Two especially important special paths are:

- segment memory operations, which have their own handling and may borrow special resources
- first-fault behavior, which cannot be modeled as "just another ordinary load"

Once those are in the picture, the vector side is not merely wider. It is semantically different in ways that need dedicated control support.

== Scalar resources are still underneath

One of the highest-risk facts in this chapter is that vector logic still reuses scalar ports underneath. In your notes, the clearest example is the vector segment path preempting load port 0 resources. That means the scalar lane is not exclusively scalar. It becomes a shared lane with arbitration, timing, and ownership consequences.

The same lesson from earlier chapters returns here: a lane that looks ordinary may secretly be the meeting place for multiple subsystems.

#figure(
  image("imgs/VSegmentUnit-FSM.svg"),
  caption: [The VSegmentUnit state machine is a good visual cue that segment memory access is a dedicated control path, not just another split-and-merge variant],
)

== Review hotspots for vector memory

When I review this part, I mainly look for:

- whether split outputs and merged results preserve the same instruction identity assumptions
- whether scalar-resource borrowing can starve or corrupt scalar traffic
- whether segment and first-fault control paths preserve rollback and exception expectations
- whether vector feedback is reassembled at the right boundary, not merely "somewhere later"

This is the point where MemBlock stops looking like a classic LSU entirely. It becomes a coordination layer for two memory worlds that partially overlap.

#series-navbar("en", nav)
