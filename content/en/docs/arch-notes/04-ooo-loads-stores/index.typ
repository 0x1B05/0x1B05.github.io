#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, tufted, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/04-ooo-loads-stores/",
  title: "Out-of-Order Loads and Stores",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/04-ooo-loads-stores/")

= Out-of-Order Loads and Stores

#series-navbar("en", nav)

#doc-toc("en")


== Registers versus Memory

- Register dependences are known statically, whereas memory dependences are determined dynamically.
- Register state is small; memory state is large.
- Register state is not visible to other threads/processors, whereas memory state is shared between threads/processors in a shared-memory multiprocessor.

== Memory Dependence Handling

An out-of-order machine must obey memory dependences while providing high performance.

Observation: *a memory address is not known until a load/store executes.*

Corollaries:
+ Renaming memory addresses is difficult.(more seriously)
+ Determining dependence or independence of loads/stores must happen after partial execution.
+ When one load/store has its address ready, older or younger loads/stores may still have unknown addresses.

=== Example

```asm
store1 r5(8)  # addr_a = r5+8
store2 ...
load   r25(0) # addr_b = r25
```

Store1 may be dependent on that takes 1000+ cycles, load may be dependent on that takes 2 cycles. So when load addr ready, we don't know store1 addr. But if `addr_a == addr_b`, we want to get the value from the store. Or even worse, there's a store2, and load need 4 bytes (maybe 1 byte from store1, 1 byte from store2..)

== Memory Disambiguation Problem(also called Unknown Address Problem)

When should an OOO engine schedule a load? A younger load can have its address ready before an older store's address is known.

Approaches:
- *Conservative*: stall the load until all previous stores have computed their addresses, or even retired.
- *Aggressive*: assume the load is independent of unknown-address stores and schedule it immediately.
- *Intelligent*: predict whether the load depends on an unknown-address store.

=== Detecting and Scheduling Store-Load Dependences

*The load's dependence status is not known until all previous store addresses are available.*

To detect dependence, the OOO engine can:
1. Wait until all previous stores commit, avoiding address matching.
2. Keep *a list of pending stores in a store buffer* and compare the load address with previous store addresses.

For scheduling a load relative to previous stores, it can:

#three-line-table(columns: (1.5fr, 1.8fr, 2.25fr))[
  | *Option* | *Advantage* | *Cost* |
  | :------- | :---------- | :----- |
  | Dependent on all stores | No recovery needed | Too conservative; delays independent loads |
  | Independent of all stores | Simple and fast common case | Misprediction requires recovery and re-execution of the load and its dependents |
  | Predict dependence | More accurate; load-store dependences persist over time | Still requires recovery/re-execution on a misprediction |
]

Alpha 21264 initially assumes a load is independent and delays loads found to be dependent. Store-set and dynamic-dependence predictors improve this decision.

Predicting store-load dependences is important for performance. Simple predictors based on past history can achieve most of the potential performance.

== Data Forwarding between Stores and Loads

Memory cannot be updated out-of-order, so all store and load instructions must be buffered in the instruction window.

Even when all older store addresses are known, two questions remain:
1. How do we check whether the load depends on a store?
2. How do we forward data to the load if it is dependent on a store?

Modern processors use a *load queue (LQ)* and a *store queue (SQ)*. They may be combined or separate.
- A load searches the SQ after computing its address, to find an older matching store.
- A store searches the LQ after computing its address, to detect younger loads that may have executed incorrectly.
  - needed if doing prediction, check the prediction. If we predict that this load is independent and have been executed, but then the store address becomes available. Then the store needs to check tif any of the loads got the wrong value, because they were predicted to be independent of the store.

When a store finishes execution, it writes its address and data into its ROB or SQ entry. When a later load generates its address,
+ it searches the SQ
+ accesses memory
+ and receives the value from the youngest older instruction that wrote that address(either from the ROB/SQ or memory)

This search logic is a content-addressable memory. Its content is the memory address, together with the access size and age. The mechanism is called *store-to-load forwarding*.

== Store-Load Forwarding Complexity


  #ctext("#B65C00", weight: "bold")[Store Queue]
  #three-line-table(
    inset: 3pt,
    align: center,
  )[
    | *Entry*   | *Valid* | *Addr*  | *AValid* | *Data* | *DValid* |
    | :------   | ------  | :------ | ------   | :----- | ------  |
    | E0(head)  | 0       | --      | 0        | --     | 0       |
    | E1        | 0       | --      | 0        | --     | 0       |
    | ..        | 0       | --      | 0        | --     | 0       |
    | E15(tail) | 0       | --      | 0        | --     | 0       |
  ]


- Content-addressable search based on *load address*.
- Range search based on the *address and size* of both the load and earlier stores.
- Age-based search for the *last value written to the location*.
- Load data can come from one or more stores in the SQ and from memory/cache.


#series-navbar("en", nav)
