#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/11-simd/",
  title: "SIMD Architectures",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/11-simd/")

= SIMD Architectures

#series-navbar("en", nav)

#doc-toc("en")

== SIMD and Other Execution Models

SIMD means *Single Instruction, Multiple Data*. It performs the same operation on many data elements, in time or in space.

#three-line-table(
  columns: (1.2fr, 2.2fr, 2.2fr),
  inset: 5pt,
  align: left,
)[
  | *Model* | *Instruction/data relationship* | *Examples* |
  | :------ | :------------------------------ | :-------- |
  | SISD | One instruction on one data element | Scalar processor |
  | SIMD | One instruction on multiple data elements | Array/vector processor |
  | MISD | Multiple instructions on one data element | Systolic/streaming processor |
  | MIMD | Multiple instruction streams on multiple data elements | Multiprocessor/multithreaded processor |
]

SIMD concurrency comes from applying one operation to different data, unlike dataflow concurrency (different operations in parallel) or thread parallelism (different control threads).

== Array and Vector Processors

Single-instruction multiple-data execution can be performed in time or space:
- Array processor: one instruction operates on multiple data elements in parallel PEs.
- Vector processor: one instruction operates on a vector through a pipelined vector functional unit.

A vector is a one-dimensional array of numbers. A vector processor requires vector registers, vector length control, and support for loading/storing vectors with a stride.

Each vector data register holds N M-bit values. A vector functional unit is pipelined; each stage operates on a different element. Vector instructions have no intra-vector dependencies and no control flow inside the vector, simplifying interlocking. A known stride makes address calculation easy.

== Vector Control State

#three-line-table(
  columns: (1.3fr, 2.3fr),
  inset: 5pt,
  align: left,
)[
  | *Register* | *Purpose* |
  | :--------- | :------- |
  | VLEN | Number of active elements in a vector instruction |
  | VSTR | Stride between elements in memory |
  | VMASK | Bit mask selecting which vector elements operate |
]

The maximum VLEN is the number of elements in a vector register. VMASK is set by vector test instructions and enables masked (predicated) operations.

== Amdahl's Law

Let `f` be the parallelizable fraction and `N` the number of processors. The maximum speedup is limited by the serial portion:

`speedup = 1 / ((1 - f) + f / N)`

All parallel machines suffer from this serial bottleneck. Performance improvement is limited by vectorizability: scalar operations limit a vector machine.

== Vector Memory Systems

Vector loads/stores require multiple elements, often separated by a constant stride. With unit stride, elements can be loaded in consecutive cycles and sustain one element per cycle if memory is banked.

Bank memory by interleaving consecutive elements across banks. With enough banks, multiple accesses can proceed in parallel. Strides greater than one can cause bank conflicts; the stride and bank count should be relatively prime when possible.

For `C[i] = (A[i] + B[i]) / 2`, a vectorized implementation uses vector loads, vector add, and vector store. In the slide example, a scalar implementation takes 2004 cycles without pipelined loads and 1504 cycles with pipelined loads; a 16-bank vector implementation takes 285 cycles before chaining and 79 cycles with chaining and multiple ports, a 19x improvement.

== Vector Chaining

Vector chaining forwards data from one vector functional unit to another before the entire vector register is complete. This overlaps dependent vector operations and reduces latency.

== Stripmining

If a data set has more elements than a vector register, break the loop so each iteration operates on the number of elements that fit in the vector register. This is *vector stripmining*.

== Scatter/Gather and Masked Operations

If data is not stored with a constant stride, use indirection to pack elements into a vector:
- Gather loads elements using an index vector.
- Scatter stores vector elements using an index vector.

Gather/scatter can avoid useless computation on irrelevant elements. Masked operations use VMASK to predicate each element, so only selected lanes execute.

== Matrix Access and Banking

Row-major storage places consecutive elements in a row next to each other; column-major storage does the reverse. A matrix row and column therefore use different strides. More banks, more ports per bank, better data layout, and better bank mapping can improve throughput. Randomized mapping is another option.

Array versus vector processor is a purist distinction; modern SIMD processors combine spatial and temporal data parallelism. GPUs are a prime example.

== SIMD Extensions and Accelerators

Vector/SIMD machines are good at regular data parallelism: the same operation on many elements. They improve performance and simplify control because there are no intra-vector branches.

Many ISAs include SIMD extensions, including Intel MMX/SSE/AVX/AMX, PowerPC AltiVec, and ARM Advanced SIMD.

The SIMD extension idea is to make one instruction operate on multiple packed data elements. For example, adding four 8-bit values requires modifying the ALU so carries do not cross the 8-bit lanes.

Modern ML accelerators combine SIMD, array, and systolic techniques. Cerebras wafer-scale engines map neural networks across hundreds of thousands of cores, while other accelerators combine SIMD processing with local SRAM.

== Vector Instruction Timing

A vector instruction has a *startup latency* before its first element emerges, followed by an initiation rate for later elements. A pipelined functional unit with one-element-per-cycle throughput can complete a vector of length `VL` in approximately

`startup + VL - 1` cycles.

Without chaining, a dependent vector instruction waits for the entire producer vector. With chaining, it can consume element 0 as soon as that element becomes available, then consume later elements in a pipeline. This converts whole-vector dependence into element-by-element forwarding.

A *convoy* is a set of vector instructions that can begin together without structural or data hazards. A *chime* is the time needed to execute one convoy, often normalized to one vector length when functional units sustain one element per cycle. Real time also includes startup latency and memory stalls.

Multiple vector instructions can overlap when they use different functional units or when chaining satisfies dependences. This is vector instruction-level parallelism layered on top of data-level parallelism within each instruction.

== Vectorization Legality

A compiler can vectorize a loop only when different iterations are independent or when dependences can be transformed safely.

#three-line-table(
  columns: (1.25fr, 2.25fr, 2.1fr),
  inset: 5pt,
  align: left,
)[
  | *Pattern* | *Dependence* | *Consequence* |
  | :-------- | :----------- | :------------ |
  | `C[i] = A[i] + B[i]` | No loop-carried dependence | Directly vectorizable |
  | `A[i] = A[i-1] + x` | Iteration `i` needs iteration `i-1` | Ordinary element-wise vectorization is illegal |
  | Reduction `sum += A[i]` | Associative recurrence | Use multiple partial sums and reduce them |
  | Conditional update | Control dependence per element | Use a mask if both paths are safe |
  | `A[index[i]]` | Indirect addresses | Gather/scatter if conflicts are handled |
]

Aliasing can hide a dependence: if the compiler cannot prove that `A` and `B` do not overlap, it may generate a runtime check, use language alias information, or keep the scalar loop.

== Vector Length, Stripmining, and Tails

The architectural maximum vector length need not divide the problem size. Stripmining repeatedly sets

`VL = min(elements remaining, maximum VL)`

and executes the vector body on that chunk. A final short vector handles the tail without scalar cleanup when the ISA supports a programmable vector length.

Vector-length-agnostic software expresses work in terms of the current `VL`, allowing the same binary to use different hardware vector lengths. Fixed-width packed SIMD ISAs more often need separate remainder handling or masks.

== Memory Banks and Conflict Conditions

For `B` memory banks with low-order interleaving, element address `a` maps to bank `a mod B`. A vector stride `S` visits only

`B / gcd(B, S)`

distinct banks before repeating. Full bank utilization therefore requires `gcd(B, S) = 1`. If the stride shares factors with the bank count, requests repeatedly collide in a subset of banks.

Examples for 16 banks:

#three-line-table(
  columns: (1fr, 1.35fr, 1.8fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Stride* | `gcd(16, S)` | *Banks visited* | *Effect* |
  | :------- | :----------- | :-------------- | :------- |
  | 1 | 1 | 16 | Ideal sequential interleaving |
  | 2 | 2 | 8 | Half the banks are unused |
  | 4 | 4 | 4 | Severe serialization |
  | 16 | 16 | 1 | Every element targets one bank |
  | 17 | 1 | 16 | All banks are reached despite large stride |
]

More banks, multiple ports, padding matrix rows, transposing data, and pseudo-random bank mappings reduce conflicts. They trade storage/layout complexity against sustained bandwidth.

== Mask Execution Strategies

A simple masked vector implementation spends one lane-time on every element and suppresses writes for false mask bits. Its execution time depends on vector length, not on mask density. A density-time implementation compresses or skips inactive elements and can finish sparse masks faster, but requires lane compaction, routing, and bookkeeping.

Masks preserve a single control stream and are effective for short conditionals. If most lanes are inactive for long regions, scalarization or a different data layout may be more efficient.

== Vector Machine Organization

A classic vector processor contains:

- Scalar registers and scalar functional units for loop/control work.
- Vector registers with many elements and multiple read/write ports.
- Pipelined vector arithmetic units.
- Vector load/store address generation with programmable stride.
- A heavily banked memory system.
- `VLEN`, stride, and mask control state.

The CRAY-1 used separate vector functional units and vector registers, enabling chaining between producer and consumer pipelines. The organization reduces instruction fetch and decode work because one vector instruction represents many scalar operations, but it shifts pressure to register-file bandwidth and memory banking.

== Vector Performance Checklist

Peak lane count alone does not determine performance. Check:

- Fraction of the program that is vectorizable, using Amdahl's law.
- Average active vector length relative to startup latency.
- Memory bandwidth and bank conflicts for the actual strides.
- Number of load/store ports and arithmetic pipelines.
- Chaining and overlap between dependent vector instructions.
- Mask density, gather/scatter latency, and data layout.
- Scalar-vector synchronization and tail overhead.

A regular loop with long vectors and unit-stride accesses can approach peak throughput; the same hardware can be mostly idle on short, irregular, or dependence-heavy code.

#series-navbar("en", nav)
