#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#import "../_diagrams/cache.typ": private-shared-cache-topology
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/20-multi-core-caches/",
  title: "Multi-Core Caches",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/20-multi-core-caches/")

= Multi-Core Caches

#series-navbar("en", nav)

#doc-toc("en")


Cache efficiency becomes even more important in a multi-core/multi-threaded system
- Memory bandwidth is at premium
- Cache space is a limited resource across cores/threads

How do we design the caches in a multi-core system?
- *Shared vs. private* caches
- How to *maximize performance of the entire system*?
- How to *provide QoS & predictable perf. to different threads* in a shared cache?
- Should *cache* management algorithms *be aware of threads*?
- *How should space be allocated to threads* in a shared cache?
- Should we *store data in compressed format* in some caches?
- How do we do *better reuse prediction & management* in caches?

== Private versus Shared Caches

#figure(
  html.frame(private-shared-cache-topology()),
  caption: [A sliced shared-LLC topology. Each core has private inner caches; memory-block number $q$ selects home slice $q mod 4$. Bidirectional links carry requests and responses, and an LLC miss continues through the memory controller to DRAM.],
)

Multi-core systems usually combine private inner caches with a shared or logically shared last-level cache.
- Private cache: Cache belongs to one core (a shared block can be in multiple caches)
- Shared cache: Cache is shared by multiple cores

L1 is part of the core, so it's usually private. Some L2 private, some L2 shared today. L3 is almost always shared.

=== Resource Sharing Concept

Too expensive to replicate.

Idea: Instead of dedicating a hardware resource(functional units, pipeline, caches, buses, memory) to a hardware context, allow multiple contexts to use it

Advantages
+ Resource sharing *improves utilization/efficiency -> throughput*
  - When a resource is left idle by one thread, another thread can use it; no need to replicate shared data
+ *Reduces communication latency*
  - For example, data shared between multiple threads can be kept in the same cache in multithreaded processors
+ *Compatible with the shared memory programming model*

Disadvantages
+ Resource sharing results in *contention for resources*
  - When the resource is not idle, another thread cannot use it
  - If space is occupied by one thread, another thread needs to reoccupy it
+ *Sometimes reduces each or some thread’s performance*: Thread performance can be worse than when it is run alone
+ *Eliminates performance isolation* -> inconsistent performance across runs: Thread performance depends on co-executing threads
+ Uncontrolled (free-for-all) sharing *degrades QoS*: Causes unfairness, starvation

Need to efficiently and fairly utilize shared resources

=== Shared Caches Between Cores

Advantages:
- High effective capacity
- Dynamic partitioning of available cache space
  - No fragmentation due to static partitioning
  - If one core does not utilize some space, another core can
- Easier to maintain coherence (a cache block is in a single location)

Disadvantages
- Slower access (cache not tightly coupled with the core)
- Cores incur conflict misses due to other cores’ accesses
  - Misses due to inter-core interference
  - Some cores can destroy the hit rate of other cores
- Guaranteeing a minimum level of service (or fairness) to each core is harder (how much space, how much bandwidth?)

=== Inter-Core Conflict Example

Suppose thread 1's useful set fits in a shared cache when run alone. Thread 2 streams through blocks mapping to the same sets. Thread 2 may evict thread 1's reused lines even though total cache occupancy is dynamically shared. Thread 1 slows down while thread 2 gains little from retaining its one-use stream.

== Resource Sharing versus Partitioning

Full sharing maximizes flexibility: any core can use idle ways. Fixed partitioning reserves capacity and gives stronger isolation but wastes space when a partition is idle or has low utility.

Practical policies combine both ideas:

- *Way masks/quotas* limit which ways a core may allocate while allowing controlled borrowing.
- *Set sampling* estimates each thread's misses as a function of allocated ways.
- *Utility-based allocation* gives the next way to the thread expected to eliminate the most misses or stall time.
- *Priority-aware insertion/replacement* protects latency-critical applications without hard physical partitions.
- *Bandwidth and MSHR quotas* accompany capacity partitioning because cache space alone cannot isolate ports, fills, and memory traffic.

A controllable shared resource can retain most utilization benefits while enforcing minimum service or bounded slowdown.


#series-navbar("en", nav)
