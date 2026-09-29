#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, tufted, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#import "../_diagrams/cache.typ": cache-parallel-serial-access
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/17-multi-level-cache/",
  title: "Multi-Level Cache Design and Management",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/17-multi-level-cache/")

= Multi-Level Cache Design and Management

#series-navbar("en", nav)

#doc-toc("en")


== Design Depends on the Cache Level

#three-line-table(
  columns: (1.5fr, 2.5fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Level* | *Typical organization* | *Dominant design pressure* |
  | :------ | :--------------------- | :------------------------- |
  | L1 instruction/data | Small, banked, low/moderate associativity, parallel tag/data lookup | Pipeline cycle time, load-use latency, ports, energy on every access |
  | Private or mid-level L2 | Larger and more associative; may be pipelined or use serial way selection | Balance hit latency against avoiding expensive LLC/memory accesses |
  | Shared last-level cache | Large, sliced/banked, highly associative, often serial tag/data | Capacity, off-chip traffic, coherence, interference, fairness, total energy |
]

An inner cache filters temporal and spatial locality before requests reach the next level. Outer levels therefore see a different access stream: first references, lines displaced by small inner caches, prefetches, and writebacks. Reusing one management policy at every level is not automatically effective.

== Parallel versus Serial Tag/Data Access

In a *parallel* lookup, tag and data arrays read all candidate ways together. A tag match then selects an already available data way. This minimizes hit latency but reads data from ways that do not match.

In a *serial* lookup, hardware first reads and compares tags, then accesses only the matching data way. This saves data-array energy and can reduce ports, but adds another step to hit latency. A pipelined or predicted-way design can occupy intermediate points between these extremes.

#figure(
  html.frame(cache-parallel-serial-access()),
  caption: [Parallel and serial tag/data-array access within one cache level.],
)

A latency-oriented L1 commonly starts tag and all candidate data-way reads together, then uses the tag match to select already-read data. A larger L2 or LLC can first determine the matching way and subsequently read only that data way, trading additional hit latency for less array activity and energy.

== Serial vs. Parallel Access of Cache Levels

Normally L1 and L2 are accessed *serially*: L2 begins only after L1 reports a miss. This avoids spending L2 energy and bandwidth on L1 hits but adds detection and request-transfer latency to every L1 miss. *L1 acts as a filter (filters some temporal and spatial locality).* Management policies are therefore different.

Speculatively accessing L2 in parallel with L1 shortens an L1 miss but performs unnecessary work whenever L1 hits. Parallel level access is attractive only when latency saved on misses justifies energy, ports, and interference from canceled requests.

=== NVIDIA V100 & A100 Memory Hierarchy

A100 feature: *Direct copy from L2 to scratchpad, bypassing L1 and register file.*

Are caches part of the microarchitecture or the ISA, the answer is it depends.

In H100 , we can take the data directly from the global memory to the shared memory(scratchpad in NVIDIA terminology). So we don't need to bring the data into the L2 cache.(under programmer's control)

=== Multi-Level Cache Design Decisions

A multi-level policy must decide:

- Which level receives a block fetched from memory?
- Where does a block evicted from an inner level go?
- Can demand, prefetch, writeback, or non-temporal traffic bypass a level?
- Does an outer level duplicate inner-cache blocks?

#three-line-table(
  columns: (1.2fr, 2.1fr, 2.1fr),
  inset: 5pt,
  align: left,
)[
  | *Hierarchy* | *Benefit* | *Cost / required action* |
  | :---------- | :-------- | :----------------------- |
  | Inclusive | An inner-cache block is guaranteed to exist outside; outer tags can help locate private copies and simplify coherence | Duplicate data reduces aggregate capacity; an outer eviction may require back-invalidating inner copies |
  | Exclusive | A block occupies only one level, increasing aggregate usable capacity | Hits/evictions can move or swap blocks between levels; more movement and control complexity |
  | Non-inclusive | No inclusion guarantee; placement can adapt to level-specific needs | Coherence cannot rely solely on outer data/tag presence, and duplication may still occur |
]

Program-visible non-temporal hints and explicit asynchronous copies can bypass ordinary cache or register paths. Such mechanisms show that whether a cache is completely transparent depends on the ISA and programming model, not only the microarchitecture.


#series-navbar("en", nav)
