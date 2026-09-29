#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, tufted, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/12-gpu/",
  title: "Graphics Processing Units",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/12-gpu/")

= Graphics Processing Units

#series-navbar("en", nav)

#doc-toc("en")

== GPUs are SIMD Engines Underneath

The instruction pipeline of a GPU behaves like a SIMD pipeline or array processor, but programmers use threads rather than SIMD instructions.

Distinguish:
- *Programming model*: how software expresses code, such as sequential, data-parallel, dataflow, or multithreaded (MIMD/SPMD).
- *Execution model*: how hardware executes code, such as out-of-order, vector, array, dataflow, multiprocessor, or multithreaded execution.

The models can differ substantially: a von Neumann program can run on an OoO processor, and an SPMD program can run on a SIMD GPU.

== Three Ways to Exploit Loop Parallelism

For `for (i = 0; i < N; i++) C[i] = A[i] + B[i];`:

#three-line-table(
  columns: (1.45fr, 2.1fr, 2.1fr),
  inset: 5pt,
  align: left,
)[
  | *Programming model* | *Expression* | *Typical execution* |
  | :------------------ | :--------- | :----------------- |
  | Sequential (SISD) | scalar loads, add, store per iteration | Pipeline, OoO, superscalar, or VLIW; hardware exposes independent iterations |
  | Data parallel (SIMD) | `VLD A -> V1`; `VLD B -> V2`; `VADD V1,V2 -> V3`; `VST V3 -> C` | Vector/array processor |
  | Multithreaded (MIMD/SPMD) | one thread per iteration, same code and different data | MIMD or SIMT machine |
]

== SIMT

A GPU is a SIMD machine underneath, but it is programmed with threads using an SPMD model. Each thread executes the same code on a different piece of data and has its own context.

The hardware dynamically groups threads executing the same instruction (at the same PC) into a *warp* or wavefront. A warp is effectively a SIMD operation formed by hardware.

== SIMD versus SIMT

#three-line-table(
  columns: (1.4fr, 2.3fr, 2.3fr),
  inset: 5pt,
  align: left,
)[
  | *Property* | *SIMD* | *SIMT* |
  | :--------- | :----- | :----- |
  | Instruction stream | One sequential stream of vector instructions | Multiple scalar instruction streams |
  | Example | `[VLD, VLD, VADD, VST], VLEN` | `[LD, LD, ADD, ST], NumThreads` |
  | Programmer view | Explicit vector/SIMD instructions | Threads / SPMD |
  | Hardware grouping | Fixed by instruction | Threads dynamically grouped into warps |
]

SIMT advantages:
- Each thread can be treated independently and can execute on a scalar pipeline.
- Threads can be grouped flexibly, dynamically obtaining SIMD benefits for threads that truly execute the same instruction.

== Fine-Grained Multithreading of Warps

If a warp has 32 threads and there are 32K iterations with one iteration per thread, there are 1K warps. Warps can be interleaved on one pipeline using fine-grained multithreading, hiding latency by switching to another warp each cycle.

== Warp Divergence

Threads in a warp that take different control-flow paths cannot all use the SIMD lanes efficiently. Divergence lowers SIMD utilization, defined as the fraction of SIMD lanes executing useful work.

Dynamic warp formation can merge threads currently at the same PC into a new warp. When enough threads branch to each path, forming new warps from waiting threads reduces divergence and improves utilization.

== GPU Organization

#three-line-table(
  columns: (1.4fr, 2fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Component* | *Role* | *Typical organization* |
  | :---------- | :---- | :-------------------- |
  | Streaming multiprocessor | Executes warps | Many SIMD processors / scalar lanes |
  | Warp scheduler | Selects a ready warp | Fine-grained interleaving |
  | Streaming processor | SIMD lane / arithmetic unit | Many per multiprocessor |
  | Local/shared memory | Fast data reuse | Per block or per multiprocessor |
  | Tensor core | Matrix multiply-accumulate | Specialized ML throughput |
]

Blocks are divided into warps, typically 32 threads per warp. Multiple warps are interleaved to tolerate long-latency operations.

== GPU Execution Hierarchy and Terminology

GPU vendors use different names for similar structures. The exact dimensions vary by generation, but the hierarchy is stable:

#three-line-table(
  columns: (1.2fr, 1.45fr, 1.35fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Generic* | *NVIDIA* | *AMD* | *Meaning* |
  | :-------- | :------- | :---- | :-------- |
  | Device | GPU | GPU | All compute and memory resources |
  | Compute core | Streaming multiprocessor (SM) | Compute unit (CU) | Schedules resident thread groups/warps |
  | Thread group | Thread block / CTA | Work-group | Threads that can share local memory and synchronize |
  | SIMD group | Warp | Wavefront | Threads issued together on SIMD lanes |
  | Lane | CUDA core / lane | SIMD lane | Executes one thread's scalar operation |
  | On-chip shared SRAM | Shared memory | Local data share | Programmer-managed reuse within a group |
]

The programming model exposes threads and blocks, not the warp as an independent semantic object. Hardware partitions a block into warps and schedules them. Software nevertheless needs the warp size to reason about coalescing and divergence performance.

== Warp Scheduling and Latency Hiding

Each resident warp has a PC, active mask, and register context. A scheduler selects a ready warp every cycle and issues its next instruction to a SIMD execution unit. When a warp waits for a memory access or dependency, another ready warp can issue without saving and restoring a heavyweight operating-system thread context.

Latency is hidden only when enough independent warps are resident and ready. If every warp waits for the same memory bottleneck, fine-grained multithreading cannot create bandwidth. It converts exposed latency into a demand for thread-level parallelism and context storage.

Some GPUs overlap multiple instructions from one or more warps across distinct functional units, providing warp-level instruction-level parallelism in addition to warp-level multithreading.

== Memory Coalescing

A SIMT load contains one address per active thread. The coalescer combines those addresses into the smallest practical set of cache-line or memory transactions.

- Consecutive lane addresses within an aligned segment can become one or a few transactions.
- A large stride may require one transaction per lane and waste most transferred bytes.
- Divergence reduces the active addresses but does not necessarily reduce transaction granularity.
- Structure-of-arrays layouts often coalesce better than array-of-structures layouts when all threads read the same field.

Coalescing is the GPU analogue of unit-stride vector access. It is distinct from caching: a poorly coalesced access can still hit in cache but consumes more ports and transactions; a well-coalesced access can still miss and wait for DRAM.

Shared memory is banked. Threads accessing different banks proceed together; multiple addresses in one bank can serialize unless the hardware supports broadcast for identical addresses. Data layout must therefore consider both global-memory coalescing and shared-memory bank conflicts.

== Divergence and Reconvergence

For a conditional branch, hardware records an active mask for each path. It executes one path with its participating lanes enabled, then the other path, and reconverges at a compiler- or hardware-identified point. Lanes not on the current path remain idle.

If a warp of `W` lanes executes path A with `a` active lanes for `t_A` cycles and path B with `b` lanes for `t_B` cycles, its useful lane utilization over the branch region is

`(a * t_A + b * t_B) / (W * (t_A + t_B))`.

Even a 50/50 branch can be efficient if each whole warp chooses one path; divergence is specifically variation *within* a warp. Grouping adjacent data with similar control behavior can therefore improve utilization without changing the algorithm.

Dynamic warp formation collects threads at the same PC into new warps. It can recover utilization across original warp boundaries, but requires flexible lane-to-context mapping, register access, and reconvergence bookkeeping.

== Occupancy and Resource Limits

*Occupancy* is the fraction of a core's maximum warps or threads that are resident. A block can start only if the core has enough registers, shared memory, warp slots, and block slots for the whole block.

For each resource, compute a separate block limit and take the minimum. Conceptually:

`resident blocks = min(register limit, shared-memory limit, warp limit, block-slot limit)`.

High register use per thread or shared-memory use per block can sharply reduce resident warps. More occupancy often improves latency tolerance, but maximum occupancy is not automatically maximum performance: spilling registers, shrinking useful tiles, or increasing contention can cost more than the extra warps help.

== Two-Level Warp Scheduling

Large warps improve SIMD efficiency when control is uniform, but one long-latency operation can block many lanes. Two-level scheduling divides a large logical warp into smaller groups:

- A large group shares control and reduces divergence overhead.
- Smaller subwarps are scheduled independently around long-latency operations.

This separates the granularity used for control convergence from the granularity used for latency tolerance. The tradeoff is more scheduling and state-management complexity.

== GPU versus Systolic Array

#three-line-table(
  columns: (1.35fr, 2.15fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Property* | *GPU/SIMT* | *Systolic array* |
  | :--------- | :--------- | :--------------- |
  | Control | Programmable threads and warps | Regular orchestrated dataflow |
  | Data movement | Register/shared/cache hierarchy plus coalescing | Mostly nearest-neighbor forwarding |
  | Irregularity | Handles branches and varied kernels, with efficiency loss | Best for fixed regular kernels |
  | Latency tolerance | Many resident warps | Pipeline fill and streaming |
  | Reuse | Software-managed tiling and caches | Spatial reuse across PEs |
  | Efficiency | General but higher control/storage overhead | Higher efficiency in its mapped domain |
]

Tensor cores place a systolic- or matrix-style unit inside a programmable GPU. Warps load and arrange tiles, invoke matrix multiply-accumulate operations, and use ordinary SIMD instructions for surrounding computation. Modern accelerators are therefore heterogeneous combinations rather than pure examples of one execution model.

== GPU Underutilization

Two major reasons GPU resources are underutilized:
- Branch divergence.
- Long-latency operations.

Smaller warp groups can reduce stalls from long-latency operations. Larger warps can reduce branch divergence when control flow is uniform; dynamically breaking large warps into subwarps can combine both goals.

== Modern GPU and Wafer-Scale Examples

The NVIDIA GTX 285 illustrates an earlier many-SM organization with scalar lanes, texture units, and on-chip storage. Volta V100 added tensor cores and a more capable cache/shared-memory hierarchy. Ampere A100 and Hopper H100 increased matrix throughput, data-type support, and scheduling/memory-system capability.

Peak TFLOPS values are not directly comparable without specifying precision, sparsity assumptions, and whether tensor operations or ordinary scalar/vector operations are counted. Sustained performance also depends on coalescing, occupancy, arithmetic intensity, and synchronization.

Wafer-scale engines combine MIMD organization across tiles with SIMD processors inside each tile, local memory, and a two-dimensional mesh network. Keeping most traffic on the wafer provides enormous internal bandwidth, but placement, routing, fault tolerance, and distributed synchronization become first-class architectural problems.

== Summary

SIMD exposes data parallelism as vector instructions. SIMT exposes scalar threads and forms SIMD groups dynamically. GPUs use SIMT programming on SIMD hardware, combining flexible per-thread execution with efficient warp-level data parallelism.

#series-navbar("en", nav)
