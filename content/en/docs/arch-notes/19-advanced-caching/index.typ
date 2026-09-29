#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, tufted, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#import "../_diagrams/cache.typ": cache-mlp-replacement
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/19-advanced-caching/",
  title: "Advanced Caching",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/19-advanced-caching/")

= Advanced Caching

#series-navbar("en", nav)

#doc-toc("en")


== Miss Latency/Cost

Where does the miss get serviced from?
+ What level of cache in the hierarchy?
+ Row hit versus row conflict in DRAM (bank/rank/channel conflict)
+ Queueing delays in the memory controller and the interconnect
+ Local vs. remote memory (chip, node, rack, remote server, …)
+ …

How much does the miss stall the processor?
+ Is it overlapped with other latencies?
+ Is the data immediately needed by the processor?
+ Is the incoming block going to evict a longer-to-refetch block?
+ …

== Memory-Level Parallelism

*Memory-level parallelism (MLP)* is the number of memory accesses generated and serviced concurrently. Four misses issued together can overlap one latency interval, while three dependent pointer misses serialize into three intervals.

- Several techniques to improve MLP (e.g., out-of-order execution)
- MLP varies. Some misses are isolated and some parallel

How does this affect cache replacement?

Traditional cache replacement policies try to reduce miss count
- *Implicit assumption: Reducing miss count reduces memory-related stall time*

Misses with varying cost/MLP breaks this assumption!
- Eliminating an isolated miss helps performance more than eliminating a parallel miss
- Eliminating a higher-latency miss could help performance more than eliminating a lower-latency miss

=== Fewest Misses != Best Performance

#figure(
  html.frame(cache-mlp-replacement()),
  caption: [The policy with fewer misses can be slower: performance follows exposed miss latency, not miss count alone.],
)

The trace is shown in steady state for a four-block fully associative cache; warm-up is omitted. Misses to `P1`--`P4` within either P region can overlap, whereas `S1`, `S2`, and `S3` are isolated accesses whose misses serialize.

- *Belady OPT* enters the loop with `{P4, P3, P2, S3}`. The first P region loads `P1`, producing the complete P working set `{P1, P2, P3, P4}`; the reverse P region then hits. Sacrificing the S blocks leaves one P stall batch plus three isolated S stall batches: four misses and four exposed batches.
- *MLP-aware replacement* enters with `{P4, S1, S2, S3}`. It preserves the three isolated S blocks and streams P blocks through the remaining entry. Each P region has three concurrent misses but exposes only one latency interval, while all S accesses hit: six misses but only two exposed batches.

- How do we incorporate MLP and miss cost into replacement decisions?
- How do we design a hybrid cache replacement policy (latency-aware and cost-aware)?


#series-navbar("en", nav)
