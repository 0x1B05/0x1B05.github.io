#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/23-prefetching/",
  title: "Prefetching",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/23-prefetching/")

= Prefetching

#series-navbar("en", nav)

#doc-toc("en")

== Prefetching Basics

Prefetching predicts future memory accesses and brings data into a cache before demand. It converts predictable memory latency into overlapped work.

Questions for every prefetcher:
- What addresses should be prefetched?
- When should requests be issued?
- Which cache level should receive them?
- How much bandwidth and storage should they consume?
- How should incorrect or useless prefetches be throttled?

The prefetch mechanism must answer four concrete questions:

1. *What*: which addresses to fetch, using an address-prediction algorithm.
2. *When*: when to issue the request, early, late, or on time.
3. *Where*: which cache level and which cache position should receive the data?
4. *How*: should software, hardware, an execution-based thread, or a hybrid operate the prefetcher?

Prefetching is correct even when its prediction is wrong: a block fetched for an unused address is simply discarded or evicted; it does not change architectural state.

== Software Prefetching

The compiler or programmer inserts prefetch instructions based on loop structure and known access patterns.

Advantages:
- Uses program semantics and can be precise.
- Simple hardware.

Disadvantages:
- Requires recompilation and robust program analysis.
- Hard to adapt to input-dependent behavior, pointers, and changing system load.

=== Software Prefetch Distance

For a loop, a compiler often inserts a prefetch `D` iterations before the corresponding demand access. A first-order estimate is

`D >= memory latency / cycles per loop iteration`.

This estimate is fragile. Out-of-order overlap changes the effective iteration time, cache hierarchy and memory latency differ across machines, and a larger `D` crosses more branches and increases the chance that the prefetched block is never used.

Software prefetching also consumes fetch, decode, issue, and address-generation bandwidth. Prefetching every load is therefore counterproductive. A compiler can use locality analysis or profiles to select likely misses, but profile behavior may not represent the deployed input.

Regular arrays can be prefetched several iterations ahead. Pointer chains are harder because the address of a future node depends on the current load. Fetching `p->next` may be too late; fetching `p->next->next` requires dereferencing a value that may not yet be available and can fault if performed as an ordinary load. This motivates nonfaulting prefetch instructions and execution-based mechanisms.

=== ISA Semantics for Prefetch

A prefetch instruction is normally a performance hint:

- It must not change architectural register or memory state.
- A bad address should generally not cause an architecturally visible fault.
- The implementation may ignore the hint.
- Hints can indicate intended use, such as read/write or temporal/non-temporal placement.

x86 provides `PREFETCH` variants; PowerPC provides data-cache-block-touch operations. Some ISAs can encode a prefetch through an ordinary-looking load whose destination discards the result. The semantic contract must allow implementation freedom while preserving protection and coherence rules.

== Hardware Prefetching

Hardware observes access history and generates requests automatically. Common algorithms detect:
- Sequential streams.
- Constant strides.
- Linked data structures and pointer patterns.
- Correlations between PCs and future addresses.

Hardware prefetching works without software changes but consumes bandwidth, cache space, energy, and controller resources when inaccurate.

=== Next-Line Prefetcher

The simplest hardware algorithm prefetches the next `N` cache lines after a demand access or miss. It requires almost no pattern-detection state and works well for sequential instruction and data streams.

Its limitations expose why address prediction matters:

- With stride two and degree one, every prefetched intervening line can be useless.
- A descending stream needs previous-line rather than next-line prediction.
- Irregular accesses waste bandwidth and pollute caches.
- A demand miss may be too late a trigger for very long memory latency.

Triggering on every access provides more lookahead but also more traffic. Triggering only on misses filters requests but observes an incomplete stream.

=== Region Tracking State Machine

A locality/stream prefetcher can maintain several tracking entries for nearby address ranges. A representative entry progresses through these states:

#three-line-table(
  columns: (1.2fr, 2.2fr, 2.2fr),
  inset: 5pt,
  align: left,
)[
  | *State* | *Meaning* | *Transition* |
  | :------ | :-------- | :----------- |
  | Invalid | Entry tracks no region | A qualifying demand miss allocates it |
  | Allocated | First address is known | Nearby misses provide evidence |
  | Training | Infer ascending/descending direction or stride | Confidence crosses a threshold |
  | Monitor/request | Track demand progress and issue lookahead requests | Accuracy falls, region ends, or entry is replaced |
]

The *prefetch distance* is how far ahead of current demand progress requests may be sent; the *prefetch degree* is how many blocks are requested at one trigger. Increasing either can improve timeliness and coverage but consumes more bandwidth and cache capacity.

=== Stride and Stream Prefetchers

A strided stream has block addresses
`A, A + N, A + 2N, A + 3N, ...`, where `N` is the stride. A stride prefetcher records the difference between consecutive accesses and, when the stride is stable, predicts the next `M` accesses.

An instruction-based stride prefetcher keeps a table indexed by load-PC. Each entry records the last address, the current stride, and a confidence value. It can distinguish different strides generated by different load instructions, but it may discover the pattern too late. Looking ahead in the instruction stream improves timeliness.

A memory-region-based stride prefetcher records a region tag, stride, and confidence. It can detect a strided pattern produced by multiple instructions. Stream prefetching is the special case `N = 1`, commonly implemented with stream buffers.

Simple stride prefetchers work well for regular accesses but can fail with multiple interleaved strides, pointer-based accesses, or irregular structures. Modern designs may track several strides or learn a sequence of stride signatures with confidence-based lookahead.

=== Spatial and Pattern Prefetching

When strides do not repeat, the access pattern can be represented as a bit pattern over a larger spatial region such as a physical page. A spatial prefetcher records the lines accessed in one region and reuses the learned pattern when a similar region is encountered.

A spatial-pattern entry typically contains a region tag, a trigger PC or offset, and one bit per cache line in the region. On the first access to a new region, the prefetcher looks up the learned pattern associated with the trigger and requests the marked offsets. When the region is evicted from the pattern-collection table, its observed footprint trains the history table.

This captures `+1, +3, +4, +9`-style footprints even when there is no constant stride. The storage cost grows with region size, and a pattern learned for one object can be wrong for another object reached by the same PC.

== Instruction Prefetching

Instruction prefetching predicts instruction-cache blocks and fetches them before the front end needs them. Unlike data, instructions are usually accessed sequentially along a straight-line path; conditional, indirect, and return branches create *branch gaps* between sequential runs. The same four questions still apply (what, when, where, and how), but branch prediction is part of the address-generation problem.

=== Next-N Sequential Instruction Prefetching

The next-N instruction prefetcher requests the next `N` instruction bytes or cache blocks after a demanded block. It is almost free to implement and works well for straight-line code and tight loops. A larger `N` can hide a longer instruction-cache miss, but it also fetches blocks past a taken branch, across a cold function path, or beyond a page boundary. Thus, the sequential stream is a strong baseline, not a complete solution for branch-heavy code.

=== Selective Next-4-Line (SN4L)

SN4L limits overfetch by prefetching only those blocks among the next four that were useful when prefetched on the previous traversal. Each cache line carries a prefetch-use bit (set when the prefetch fills and cleared when a demand uses it), and a small direct-mapped metadata table records the usefulness history. SN4L trades the bandwidth and instruction-cache pollution of a naive next-four-line policy for metadata lookups, training latency, and possible aliasing when different paths share a table entry.

=== Entangling Instruction Prefetcher

The next-N policy can still be late when an instruction miss has a long latency: the processor may demand the block before the sequential prefetch completes. The Entangling prefetcher measures the latency of an I-cache miss, correlates the missed address with an earlier I-cache access, and triggers the correlated prefetch when that earlier access is encountered. It moves the trigger earlier in the path, at the cost of correlation storage, replacement/aliasing decisions, and possible phase-dependent overfetch.

=== Fetch-Directed Instruction Prefetching (FDIP)

FDIP treats the instruction stream as sequential runs separated by branch gaps and uses the branch predictor to bridge each gap. Starting from the current instruction, the fetch engine walks sequentially; when it encounters a branch, it predicts the target and resumes sequential prefetching at that target. The fetch engine can run far ahead of the execution units and place predicted instruction addresses in a *Fetch Target Queue (FTQ)*.

The FTQ decouples the front-end producers and consumers:

- *Instruction Address Generation (IAG)* walks the predicted path and emits target addresses into the FTQ.
- The *Instruction Fetch Unit (IFU)* consumes FTQ entries, checks the instruction cache, and requests missing blocks from lower cache levels.
- Decode and execution consume instructions after the IFU, so a long instruction miss need not stop address generation immediately.

FDIP improves timeliness for taken branches and non-sequential instruction streams, but it inherits branch-predictor errors. A wrong-path target can consume fetch bandwidth, occupy the FTQ, and pollute the instruction cache; a branch misprediction can also make otherwise accurate prefetches useless. IAG/IFU decoupling needs extra queues and control logic, and the design must still respect page permissions, instruction-cache coherence for self-modifying code, and competition with data requests.

With a sufficiently large FTQ and accurate branch prediction, the decoupled
IAG can run far enough ahead that FDIP subsumes much of the role of a separate
instruction prefetcher: predicted fetch targets themselves become the prefetch
stream. The condition matters. A small FTQ, frequent mispredictions, or an IFU
that cannot drain requests quickly restores the timeliness gap and makes an
additional sequential or correlation prefetcher useful.

Instruction-prefetch aggressiveness is therefore a three-way tradeoff: next-N gives simple coverage on straight-line code, SN4L and Entangling spend metadata to improve accuracy or timeliness, and FDIP spends predictor/FTQ resources to cross branch gaps. The useful policy is the one that hides instruction-fetch latency without starving demand data or filling the cache with instructions from paths that will not execute.

== Prefetch Accuracy and Timeliness

Useful prefetches arrive before demand and are later used. A prefetcher should maximize coverage and accuracy while minimizing lateness and pollution.

#three-line-table(
  columns: (1.4fr, 2fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Metric* | *Meaning* | *Failure mode* |
  | :------ | :------- | :----------- |
  | Coverage | Fraction of demand misses prefetched | Missed opportunities |
  | Accuracy | Fraction of prefetches later used | Bandwidth/cache pollution |
  | Timeliness | Prefetch arrives before demand | Late prefetch has no benefit |
  | Pollution | Useful blocks displaced by prefetches | Increased demand misses |
]

Accuracy is `used prefetches / sent prefetches`; coverage is `prefetched misses / all misses`; timeliness is `on-time prefetches / used prefetches`. Bandwidth consumption compares memory bandwidth with and without prefetching. Cache pollution is the number of extra demand misses caused by putting unneeded prefetched blocks in the cache.

Prefetching too early can let a prefetched block be evicted before use. Prefetching too late cannot hide the full memory latency. More aggressive hardware lookahead or moving a software prefetch earlier can improve timeliness.

These metrics can move in opposite directions. Raising degree often increases coverage but lowers accuracy. Raising distance can convert late prefetches into timely ones, but can also evict them before demand. A prefetcher with high standalone accuracy can still slow a multicore system by delaying another core's demand misses.

Useful classification at demand time:

- *Timely useful*: the prefetched block is present before demand and avoids a miss.
- *Late useful*: demand merges with an outstanding prefetch; only part of latency is hidden.
- *Useless*: the block is evicted or invalidated without demand use.
- *Harmful*: in addition to being useless, the request delays demand traffic or evicts a useful line.

Marking prefetched lines and recording whether demand later touches them lets hardware estimate these categories online.

=== Placement and Visibility

A prefetch can be issued from memory to L3/L2/L1, or between cache levels (for example, L3 to L2 or L2 to L1). A demand-fetched block normally enters the MRU position, but a prefetched block is not known to be needed; inserting it near the LRU position or using a separate prefetch buffer reduces pollution.

The hardware prefetcher may observe all L1 references, L1 misses, or only L2 misses. Seeing a more complete stream can improve accuracy and coverage, but requires more bandwidth and more ports into the prefetcher.

#three-line-table(
  columns: (1.25fr, 2.15fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Destination* | *Advantage* | *Cost* |
  | :------------ | :---------- | :----- |
  | L1 cache | Lowest demand-hit latency | Greatest pollution and port pressure |
  | L2/L3 cache | More capacity, less L1 disruption | Demand still pays an upper-level miss |
  | Prefetch buffer | Protects demand cache lines | Extra lookup, coherence, sizing, and movement logic |
  | Memory-controller queue | Can prepare DRAM rows without allocating cache data early | Does not hide upper-cache fill latency |
]

A separate prefetch buffer can be probed in parallel with the cache or after a miss. Parallel lookup is fast but consumes energy; serial lookup adds latency. Moving a useful entry into the cache also needs a replacement and coherence policy.

== Throttling

Prefetch degree and distance should adapt to accuracy, cache occupancy, memory bandwidth, queueing, and co-running threads. Throttling protects demand requests and quality of service.

A feedback-directed controller can divide time into intervals, measure accuracy, lateness, and pollution, then select among aggressiveness levels. A common policy increases distance/degree when accuracy is high and many prefetches are late, but decreases them when accuracy is low or bandwidth is saturated.

Throttling must include hysteresis. Reacting to one short interval can oscillate between overly aggressive and disabled states. Per-PC or per-stream control is more precise than one global setting but requires more counters.

Hybrid prefetchers combine several algorithms to cover more patterns and improve timeliness. Their costs are extra design complexity, bandwidth, and interference between prefetchers. A coordinated controller must manage per-prefetcher accesses and shared cache, bus, DRAM-bank, rank, channel, and row-buffer contention.

== Multi-Core and Shared-Memory Prefetching

Prefetching shared data can help one core but interfere with other cores. A shared memory controller must distinguish demand from prefetch requests, allocate bandwidth fairly, and avoid evicting useful data from other threads.

Coherence adds another complication. A prefetched shared line can be invalidated before use, and a write-oriented prefetch can create coherence traffic or ownership changes. Shared-cache replacement should account for which core generated a prefetch and whether it was later used by the same or another core.

== Multiple Prefetchers

No single prefetcher covers all access patterns. Multiple prefetchers can target streams, strides, spatial regions, pointer chains, and instruction correlations. A coordinator chooses which prefetches to issue and controls bandwidth.

Running every component at maximum degree is not a valid hybrid policy. Different prefetchers can request the same block, train each other on prefetched accesses, evict one another's data, and compete for miss-status registers and DRAM queues. Requests therefore need a source identifier and a coordinator that can suppress duplicates, attribute usefulness, and set per-prefetcher aggressiveness.

== Self-Optimizing Prefetching

Fixed heuristics assume a particular workload and memory system. A self-optimizing prefetcher instead treats address generation as an online decision problem and adapts to feedback.

Pythia maps reinforcement-learning terminology to prefetching as follows:

#three-line-table(
  columns: (1.1fr, 2.15fr, 2.35fr),
  inset: 5pt,
  align: left,
)[
  | *RL concept* | *Prefetch interpretation* | *Examples* |
  | :----------- | :------------------------ | :--------- |
  | State | Features describing the current request and recent behavior | Load PC, branch PC, page, current delta, sequence of deltas |
  | Action | Offset relative to demand address `A` | Prefetch `A + O`; offset zero means no prefetch |
  | Reward | Delayed evaluation of the action | Timely/late use, useless request, page crossing, pollution, bandwidth pressure |
]

For a 4KB page and 64B lines, all in-page offsets lie roughly in `[-63, +63]`, but a practical implementation prunes the action space. The example configuration uses features combining PC/delta history, a smaller set of candidate offsets, and rewards that distinguish useful, late, inaccurate, and bandwidth-sensitive outcomes.

=== Q-Value and Evaluation State

The prefetcher stores an estimated value for state-action pairs. On a demand request:

1. Construct a state vector from control-flow and address features.
2. Read candidate action values and choose an offset, sometimes exploring a nonmaximal action.
3. Issue the prefetch unless the selected action is zero or fails a resource check.
4. Place the state/action record in an evaluation queue.
5. Observe later fill, use, lateness, eviction, and system pressure.
6. Assign a reward and update the corresponding Q-value.

The evaluation queue is essential because the consequence of a prefetch is delayed. A finite queue can lose attribution for very late outcomes, and table aliasing makes unrelated state/action pairs share learning state.

Self-optimization does not remove policy choices: designers still define features, actions, rewards, exploration, storage, and learning rate. Its advantage is adapting those choices online to program phase and system bandwidth instead of fixing one confidence threshold for all conditions.

== Coordinating Shared Resources

Prefetch-aware control extends beyond the prefetcher itself:

- *Cache*: insert speculative blocks with lower priority, protect repeatedly reused demand data, and promote a prefetched line after demand use.
- *Miss queues*: reserve entries for demand misses so prefetches cannot block forward progress.
- *Interconnect*: deprioritize inaccurate sources under congestion while preserving useful timely streams.
- *DRAM*: distinguish demand and prefetch requests, consider row-buffer locality without allowing prefetch row hits to starve demand misses, and avoid reducing bank-level parallelism.
- *Multicore QoS*: throttle the prefetcher causing system-wide slowdown, not merely the one with low local accuracy.

Dropping an unissued prefetch is cheap; delaying an already critical demand request is expensive. Most controllers therefore give demand traffic priority under high load, while still allowing high-confidence prefetches to use otherwise idle bandwidth.

=== Demand-Prefetch Interaction at DRAM

A naive first-ready/first-come-first-served scheduler may prioritize a prefetch row hit over an older demand row conflict. This improves immediate row-buffer hit rate but can lengthen critical demand latency. Conversely, always placing prefetches last can make every prefetch late.

A better policy considers:

- Whether demand is already waiting for the same block.
- Prefetch confidence and estimated deadline.
- Bank occupancy and whether the prefetch creates or destroys useful row locality.
- Per-core slowdown and queue age.
- Whether delaying the request will turn a timely prefetch into a late one.

Prefetch-aware memory scheduling is thus a deadline and interference problem, not simply a separate low-priority queue.

== Execution-Based Prefetching

Idea: pre-execute a piece of the program solely to generate memory addresses. The speculative thread can run on another core, another hardware context, or the same context during idle cache-miss cycles.

Advantages:
- Follows complex control and pointer behavior.
- Generates addresses that static stream/stride detectors cannot see.

Costs:
- Uses compute, cache, and memory bandwidth.
- Requires dependence and control-flow handling.

The execution thread may be generated in software or hardware. It can run on another core, in another hardware context, or by reusing the main context during an otherwise stalled period.

== Runahead Execution

Long-latency cache misses are responsible for much performance loss, while OoO execution requires large instruction windows. As memory latency grows, the instruction window can fill before the miss returns.

When the oldest instruction is an unresolved long-latency miss, the processor enters runahead mode:
- The miss-dependent instruction is treated as invalid.
- The processor continues speculative execution past the miss.
- Independent loads are issued and their data is prefetched.
- Hardware prefetcher and branch-predictor tables are trained.
- No speculative result becomes architecturally visible.

When the original miss returns, the processor exits runahead, discards speculative state, and resumes normal execution. Runahead increases memory-level parallelism without requiring a very large instruction window.

=== Runahead Mechanism

On entry, the processor checkpoints architectural register state. In runahead mode, instruction processing is otherwise like normal processing, but architectural register and memory state is never updated. The oldest instruction is pseudo-retired to free window resources: an `INV` instruction is removed immediately, while a `VALID` instruction is removed after it completes.

Results are marked `INV` when dependent on an L2 miss and `VALID` otherwise. `INV` values are not trusted for prefetching or branch resolution. A pseudo-retired store writes its value and `INV` status to a small runahead cache; a dependent load can read from that cache for communication during speculative execution.

An `INV` branch cannot be resolved, so a mispredicted `INV` branch leaves execution on the wrong path until runahead ends. A `VALID` branch can be resolved and can trigger recovery. On exit, the checkpointed architectural state is restored.

#three-line-table(
  columns: (1.15fr, 2.25fr, 2.2fr),
  inset: 5pt,
  align: left,
)[
  | *Event* | *Normal execution* | *Runahead execution* |
  | :------ | :----------------- | :------------------- |
  | Oldest long miss | Window eventually fills and retirement stops | Checkpoint state and enter runahead |
  | Miss-dependent result | Wait for correct value | Mark `INV` and propagate invalidity |
  | Independent load | May be blocked behind full window | Execute and send a cache prefetch |
  | Completed instruction | Retire architecturally in order | Pseudo-retire only to free resources |
  | Store | Update memory only when safe | Place speculative value/validity in runahead cache |
  | Triggering miss returns | Resume blocked execution | Restore checkpoint and reexecute normally |
]

Runahead does not make speculative results architecturally correct. It uses execution only as an address generator and microarchitectural trainer. Every architecturally visible instruction after the checkpoint is executed again in normal mode.

Advantages:
- Prefetches dependent and control-flow-driven accesses.
- Uses otherwise stalled execution resources.

Limitations:
- Speculative work consumes energy and bandwidth.
- Pointer-intensive applications may expose little independent address generation.
- Wrong-path execution and unresolved branch mispredictions limit usefulness.

Baseline runahead has three recurring inefficiencies: short periods caused by an already in-flight miss, overlapping periods that execute the same instructions, and useless periods that generate no useful miss. Efficient runahead predicts and suppresses these cases.

=== Efficient Runahead

*Short periods* begin on a miss that is already in flight due to a hardware prefetch, wrong-path reference, or previous runahead period. The miss returns soon, so entry/exit flushing costs more than the limited lookahead can save.

*Overlapping periods* traverse many of the same dynamic instructions. A later period repeats address generation already performed by an earlier period and adds energy without discovering new misses.

*Useless periods* contain no independent miss that escapes the ordinary instruction-window reach. They expose little memory-level parallelism and generate no useful prefetch.

Efficient runahead records signatures of trigger loads and period outcomes. It can decline entry when a period is predicted short, overlapping, or useless, and can terminate early after prolonged lack of useful address generation. The slide results illustrate why efficiency matters: baseline runahead can execute substantially more instructions than its IPC improvement, while selective suppression retains most of the speedup with much less extra work.

=== Wrong-Path Effects

Wrong-path memory references are not uniformly bad. They can prefetch blocks later used on the correct path, but they can also consume bandwidth, pollute caches, and train prefetchers incorrectly. An `INV` branch in runahead is especially problematic because the missing value prevents resolution until runahead exits.

Early wrong-path detection can look for unusual or illegal events that cannot occur on a correct path, but recovery must not convert speculative anomalies into architectural exceptions. As with ordinary speculation, wrong-path memory activity is a performance/security concern even though architectural state is restored.

=== Dependent Misses and AVD

Runahead cannot normally parallelize dependent L2 misses: if `Load 2` needs the pointer value returned by a missing `Load 1`, its address cannot be computed while `Load 1` is `INV`. Address-Value Delta (AVD) prediction predicts the values of address loads, allowing the dependent address to be generated and prefetched. This is especially useful for pointer-intensive applications.

An *address load* produces a value later used to form another memory address. Allocators and linked structures often create regular deltas between successive pointer values even when the absolute values vary. AVD prediction learns such a delta and predicts the missing pointer only for speculative address generation.

If the prediction is wrong, normal execution still reexecutes after the original miss returns, so correctness is preserved; the cost is a useless or wrong-path prefetch. Confidence is therefore critical to prevent arbitrary predicted values from overwhelming the memory system.

=== Spatial Memory Streaming

Spatial Memory Streaming (SMS) handles out-of-order accesses and linked structures for which consecutive strides do not repeat. It records accesses as a bit pattern over a large spatial region, such as a physical page, associates the pattern with a program counter, and reuses it when the same pattern appears in another region.

SMS separates *pattern generation* from *pattern replay*. A generation table observes all offsets touched within an active region. When the region is replaced, its footprint is stored under a trigger signature. A later region reached by the same trigger replays that footprint relative to its own base address.

Because the bit pattern ignores exact access order, SMS tolerates out-of-order execution and several interleaved loads. It can nevertheless overfetch when objects reached by the same PC have different layouts, and a large spatial region increases metadata and degree.

== Prefetching in the Memory System

Effective advanced prefetching combines address prediction, execution-based generation, MLP-aware scheduling, cache placement, and adaptive throttling. The best policy depends on workload, core count, memory technology, and QoS goals.

A complete design should specify:

- Trigger stream and table indexing.
- Prediction state, confidence, degree, and distance.
- Page/boundary and duplicate filtering.
- Destination level and insertion/replacement policy.
- Demand merging, coherence, and cancellation.
- Per-source usefulness attribution.
- Bandwidth, queue, cache, and DRAM throttling.
- Training behavior on prefetched and wrong-path accesses.

Prefetching succeeds only when it moves latency off the critical path without moving a larger amount of interference onto someone else's critical path.

#series-navbar("en", nav)
