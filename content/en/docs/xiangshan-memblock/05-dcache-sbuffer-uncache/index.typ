#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "en", route: "docs/xiangshan-memblock/05-dcache-sbuffer-uncache/", title: "DCache, SBuffer, and Uncache")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/05-dcache-sbuffer-uncache/")

= DCache, SBuffer, and Uncache/MMIO: Separating Cacheable and Uncacheable Paths

#series-navbar("en", nav)

One reason MemBlock grows large is that "memory" is not one traffic class. Cacheable loads, draining stores, and uncache or MMIO requests obey different progress rules. The code has to keep those paths related but not confused with one another.

== DCache is a shared execution-side resource

The load units connect to DCache request ports, forwarding paths, and refill-related information. This is already enough to make DCache part of the execution story rather than a passive endpoint. The load side is not simply issuing requests downward; it is also receiving fast-forwarding opportunities and timing-sensitive readiness information back.

== Why SBuffer is not folded into the LSQ

The LSQ and SBuffer serve different roles:

- the LSQ is about ordering, dependency, replay, and instruction-lifetime coordination
- the SBuffer is about stores that are ready to drain toward cache or memory

That is why the path looks more like:

`StoreUnit / store-data path -> LSQ -> SBuffer -> DCache or lower memory`

Keeping SBuffer distinct helps keep "store ordering state" separate from "store writeout buffering."

#figure(
  image("imgs/sbuffer.svg"),
  caption: [The SBuffer block diagram from the XiangShan design doc helps separate committed-store buffering and forward-service logic from the LSQ's ordering role],
)

== Why uncache and MMIO need their own control path

The uncache side is not an optional corner. It has different outstanding rules, different return behavior, and a different risk profile from normal cacheable access. A dedicated control path or small state machine is exactly what I would expect once those semantics need to coexist with the rest of MemBlock.

This is also where lane ownership matters again. If a specific load lane handles scalar uncache return traffic, then return routing is tied to an explicit design decision rather than to an automatically symmetric network.

== What I would watch in review

This chapter is where I start asking ready/valid questions very aggressively:

- Can cacheable and uncacheable paths accidentally share assumptions that should be separate?
- Is return traffic always routed back to the correct lane?
- Can an outstanding uncache request block or corrupt an unrelated cacheable flow?
- Does the LSQ-to-SBuffer handoff preserve the same ordering story the backend expects?

Many memory bugs do not come from the happy cacheable path. They come from the boundary where one path stops being like the others.

#series-navbar("en", nav)
