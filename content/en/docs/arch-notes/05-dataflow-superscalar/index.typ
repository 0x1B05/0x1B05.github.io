#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, tufted, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/05-dataflow-superscalar/",
  title: "Dataflow and Superscalar Execution",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/05-dataflow-superscalar/")

= Dataflow and Superscalar Execution

#series-navbar("en", nav)

#doc-toc("en")


== Enabling OoO Execution, Revisited

1. Link the consumer of a value to the producer.
  - Register renaming associates a tag with each data value.
2. Buffer instructions until they are ready.
  - Insert the instruction into a reservation station after renaming.
3. Keep track of source-value readiness.
  - Broadcast the tag when the value is produced.
  - Instructions compare their source tags with the broadcast tag; a match makes the source ready.
4. When all source values are ready, dispatch the instruction to its functional unit.
  - Wake up and select/schedule the instruction.

== Summary of OoO Execution Concepts

- Register renaming eliminates false dependences and links producers to consumers.
- Reservation stations buffer instructions and let the pipeline move for independent ready instructions.
- Tag and value broadcast communicates readiness and values between instructions.
- Wakeup and select enables out-of-order dispatch into functional units.

== Restricted Dataflow

An out-of-order engine dynamically builds the dataflow graph of a piece of a program. The graph is limited to the *instruction window*: all decoded but not yet retired instructions.

The state of a register alias table and reservation stations exposes the dataflow graph. A useful exercise is to draw the dataflow graph for the executing code and provide the executing code in sequential order.

== OoO Execution with Precise Exceptions

Most modern processors use:
- A reorder buffer to support in-order retirement.
- A single physical register file to store all registers (integer and floating-point files may still be separate).
- Two register maps pointing to the physical register file:
  - Future/frontend register map for renaming.
  - Architectural register map for maintaining precise state.

This design avoids replicating values in reservation stations, ROB entries, and other structures.

At decode/rename:
- Allocate a destination physical register to the architectural destination register.
- Read and update the frontend register map.

Before execution, access the physical register file to get source values. After execution, access the physical register file to write result values. At retirement, update the architectural register map with the destination physical register.

== Examples of Modern Processors

The same general organization appears in the Intel Pentium Pro and Pentium 4, Alpha 21264, MIPS R10000, IBM POWER4/POWER5, AMD Zen/Zen2, and Apple M1 Firestorm.

The IBM POWER4 example in the slides has:
- Two cores with out-of-order execution.
- A 100-entry instruction window in each core.
- 8-wide instruction fetch, issue, and execute.
- A large local/global hybrid branch predictor.
- A 1.5 MB, 8-way L2 cache.
- Aggressive stream-based prefetching.

== Why Is OoO Execution Beneficial?

OoO execution provides latency tolerance: it tolerates the latency of multi-cycle operations by executing independent operations concurrently. If all operations take one cycle, this benefit is much smaller.

If an instruction takes 1000 cycles:
- How large of an instruction window is needed to continue decoding without stalling?
- How many cycles of latency can OoO tolerate?
- What limits the latency-tolerance scalability of Tomasulo's algorithm?

The instruction-window size limits scalability: it determines how many decoded but not yet retired instructions can be kept in the machine.

== Out-of-Order Execution Tradeoffs

Advantages:
- Latency tolerance: independent instructions can execute and complete in the presence of long-latency operations, giving higher performance than in-order execution.
- Irregular parallelism: the hardware dynamically finds and exploits parallel operations that are difficult to find or exploit statically in irregular code.

Disadvantages:
- Higher complexity, potentially lengthening critical-path delay and clock-cycle time.
- More hardware resources are needed.

Recall:

`execution time = number of instructions * average CPI * clock cycle time`

== Other Approaches to Instruction-Level Concurrency

- Pipelining.
- Fine-grained multithreading.
- Out-of-order execution.
- Dataflow at the ISA level.
- Superscalar execution.
- VLIW.
- SIMD processing (vector and array processors, GPUs).
- Decoupled Access Execute.
- Systolic arrays.

== Dataflow: Exploiting Irregular Parallelism

Dataflow execution is availability-driven:
- Availability of data determines the order of execution.
- A dataflow node fires when its sources are ready.
- Programs are represented as dataflow graphs of nodes.

Dataflow at the ISA level has not been as successful. Dataflow implementations at the microarchitecture level, while preserving von Neumann model semantics, have been very successful; out-of-order execution is the prime example. Mapping dataflow graphs to reconfigurable hardware such as FPGAs has also been successful.

== ISA-Level Tradeoff: Program Counter

Do we want a program counter (PC or IP) in the ISA?

- *Yes: control-driven, sequential execution.* An instruction executes when the PC points to it, and the PC changes sequentially except for control-flow instructions.
- *No: data-driven, parallel execution.* An instruction executes when all operand values are available.

Tradeoffs include ease of programming, ease of compilation, performance and parallelism extraction, and hardware complexity.

=== ISA-Level Dataflow Tradeoffs

Advantages:
- Very good at exploiting irregular parallelism.
- Only real dependences constrain processing.
- More parallelism can be exposed than in the von Neumann model.

Disadvantages:
- No precise state semantics, making debugging and interrupt/exception handling difficult.
- Large hardware overhead for tag matching and data/tag storage.
- Too much parallelism may require explicit parallelism control.
- Mutable data structures are difficult to support.

== ISA versus Microarchitecture

The control-driven versus data-driven tradeoff can be made at two levels:

- *ISA*: specifies how the programmer sees instructions: sequential control-flow order or dataflow order.
- *Microarchitecture*: specifies how the implementation executes instructions. It may execute instructions in any order as long as it obeys the ISA semantics when results become visible to software.

The programmer should see the order specified by the ISA even when the implementation executes out-of-order.

== Superscalar Execution

Idea: fetch, decode, execute, and retire multiple instructions per cycle. An N-wide superscalar processor handles N instructions per cycle in the ideal case.

Superscalar execution requires additional hardware resources. The hardware performs dependence checking between concurrently fetched instructions.

Superscalar execution and out-of-order execution are orthogonal. All four combinations are possible:

#three-line-table(
  columns: (1.4fr, 1.5fr, 1.8fr),
  inset: 5pt,
  align: left,
)[
  | *Processor* | *Instruction issue* | *Description* |
  | :---------- | :------------------ | :----------- |
  | Scalar in-order | one, in order | Simple pipeline |
  | Scalar OoO | one, out of order | Dynamic scheduling without multiple issue |
  | Superscalar in-order | multiple, in order | Multiple datapaths with same-cycle dependence checking |
  | Superscalar OoO | multiple, out of order | Multiple datapaths plus dynamic scheduling |
]

=== Superscalar Performance

In an in-order superscalar processor, multiple copies of the datapath fetch/decode/execute multiple instructions per cycle. Dependences make same-cycle dispatch tricky, so the processor needs dependence detection between concurrently fetched instructions.

The ideal IPC of a two-wide processor is 2. Independent instructions can achieve this rate, while dependent code may reduce the actual IPC to 1.2 or lower. Reordering instructions can sometimes recover the ideal throughput.

== Handling Data Dependences in Superscalar Processors

Six fundamental approaches to flow dependences can all be used:
1. Detect and wait until the value is available in the register file.
2. Detect and forward/bypass data to the dependent instruction.
3. Detect and eliminate the dependence at the software level; then hardware need not detect it.
4. Detect and move the dependent instruction out of the way for independent instructions.
5. Predict the needed value, execute speculatively, and verify.
6. Use fine-grained multithreading; dependence detection is not needed between threads.

== Superscalar Execution Tradeoffs

Advantages:
- Higher instruction throughput and IPC (lower CPI).

Disadvantages:
- Dependence checking between concurrent instructions is complex.
- Register renaming is more complex in an OoO processor.
- Dependence checking can lengthen the critical path and clock cycle time.
- More hardware resources are needed.

#series-navbar("en", nav)
