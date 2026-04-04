#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "en", route: "docs/xiangshan-memblock/07-review-checklist/", title: "MemBlock Review Checklist")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/07-review-checklist/")

= How I Would Review MemBlock: A Checklist for High-Risk Paths

#series-navbar("en", nav)

After reading the subsystem by pieces, I want to compress it into a checklist I can actually use while reviewing code or designing targeted tests. The point is not to prove every detail wrong in advance. The point is to avoid reading such a large subsystem without a stable set of questions.

== Structural checks I would keep first

- Are the ownership rules for `loadUnits(0)`, `loadUnits(1)`, and `loadUnits(2)` still explicit and consistent?
- Whenever a special path borrows a lane, does the code also make the preemption rule explicit?
- Are writeback overrides tied to one clear source of truth, or are there several partially overlapping winners?
- Is there one obvious place where rollback candidates are compared and the oldest one is selected?

== MMU and permission checks

- Does every requester class reach the intended DTLB group?
- Do shared PTW responses get redistributed in a way that preserves requester identity?
- Do `sfence`, CSR translation changes, and redirect events reach every path that can cache translation state?
- Does PMP checking stay aligned with the requester that produced the access?

== Data-path and memory-system checks

- Do load, store-address, and store-data paths reunite at the LSQ with the intended lifetime and ordering assumptions?
- Is the LSQ-to-SBuffer boundary clear about what is still ordering state and what is already writeout state?
- Are cacheable and uncacheable return paths visibly separate?
- Does a special return lane such as the uncache lane stay special everywhere, not just at one endpoint?

== Vector and special-case checks

- When vector memory borrows scalar resources, is the arbitration rule explicit?
- Do split and merge boundaries preserve the same exception and feedback story?
- Are first-fault and segment paths integrated into rollback and writeback logic, not merely added as side features?
- When atomics or misaligned access handling reuse a lane, does every surrounding path still know who owns that lane this cycle?

== How I would turn this into tests

For testing, I would not begin from a full-system run and hope the right corner appears. I would rather build small scenarios around the checklist:

- construct one case per borrowed lane
- construct one case per return-path specialization
- combine one control event such as redirect or exception with one shared-resource path
- keep records of which combinations are covered, not just which files were read

That is the main reason for writing this series at all. MemBlock is large enough that reading without a checklist quickly becomes passive. A useful review path has to keep turning structure into concrete suspicion.

#series-navbar("en", nav)
