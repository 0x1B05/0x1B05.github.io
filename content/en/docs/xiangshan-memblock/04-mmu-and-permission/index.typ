#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "en", route: "docs/xiangshan-memblock/04-mmu-and-permission/", title: "DTLB, PTW, and PMP")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/04-mmu-and-permission/")

= DTLB, PTW, and PMP: Why Translation and Permission Checks Converge Here

#series-navbar("en", nav)

MemBlock is also where translation and permission machinery stop looking like background services and start looking like active scheduling constraints. Once loads, stores, prefetch, and vector paths are all in play, the MMU-facing side becomes part of the core control story.

#figure(
  image("imgs/two-stage-translation-sv39-sv39x4.svg"),
  caption: [The XiangShan MMU documentation's two-stage translation diagram is a useful reminder that translation quickly becomes a multi-stage coordination problem instead of a single TLB lookup],
)

== Why there are multiple DTLB groups

The DTLB structure is easier to read if I stop expecting one monolithic block. MemBlock uses multiple requester groups because different traffic classes have different timing and conflict patterns:

- one group for load-oriented requesters
- one group for store-oriented requesters
- one group for prefetch or L2-related requesters

That organization is a hint about microarchitectural pressure. Different memory classes are not forced through one shared shape if that would make ports, replay, or replacement logic harder to manage.

== Why PTW fanout appears in MemBlock

The PTW is shared, but the requesters are many. That means MemBlock has to collect requests, distribute responses, and keep the shared walk machinery coordinated across several DTLB-facing clients. The PTW is not just "somewhere below the DTLB." At this level it becomes an arbitration and fanout problem.

== PMP and PMPChecker are split on purpose

Another useful reading handle is to separate "global configuration source" from "per-requester checking":

- a global PMP block holds the relevant configuration view
- multiple `PMPChecker`s evaluate individual requester paths in parallel

That split keeps permission checks close to the active requesters without cloning all global state logic into every execution unit.

== Why `sfence`, CSR control, and redirect live here

Translation state is global enough that MemBlock becomes the obvious broadcast point for events such as:

- `sfence`
- address-translation control changes through CSR state
- redirect and flush-like control events

These are not local details that one load pipe should guess about privately. They are consistency events that have to reach the translation side in a coordinated way.

== Review hotspots in this layer

When I read this part for risk, I mostly watch for:

- stale translation state surviving a flush or redirect
- request arbitration that favors the wrong requester at the wrong time
- mismatches between translation success and permission-check timing
- vector or special paths borrowing translation ports without preserving ordering assumptions

At that point, MMU logic is no longer isolated infrastructure. It is part of MemBlock's control surface.

#series-navbar("en", nav)
