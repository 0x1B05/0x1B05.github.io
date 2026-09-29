#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, tufted, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#import "../_diagrams/rob.typ": ooo-two-humps, rob-bypass-paths, rob-data-path
#import "../_diagrams/ooo-timelines.typ": (
  ooo-timeline-forwarding, ooo-timeline-no-forwarding,
  ooo-timeline-out-of-order,
)
#import "../_diagrams/ooo-simulation.typ": (
  ooo-cycle-snapshot, ooo-cycle8-broadcast, ooo-dataflow-graph,
)
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/03-out-of-order-execution/",
  title: "Out-of-Order Execution",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/03-out-of-order-execution/")

= Out-of-Order Execution

#series-navbar("en", nav)

#doc-toc("en")


== The Problem with In-Order Dispatch

Dispatch is the act of sending an instruction to a functional unit. Renaming with a ROB eliminates stalls due to false dependences, but *a non-ready instruction (which doesn't have any one of the values it needs) can still stall dispatch of all younger instructions into functional units*.

For example, in both sequences below the first ADD waits for R3, so later independent instructions cannot be dispatched:

#three-line-table(
  columns: (.55fr, 1.8fr, 1.8fr),
  inset: 5pt,
  align: left,
)[
  | ID  | *Sequence 1* | *Sequence 2* |
  | :-- | :----------- | :----------- |
  | I0  | MUL #text(fill: rgb("#1A41AC"))[R3] \<- R1, R2 | LD #text(fill: rgb("#1A41AC"))[R3] \<- R1(0) |
  | I1  | ADD R3 \<- #text(fill: rgb("#1A41AC"))[R3], R1 | ADD R3 \<- #text(fill: rgb("#1A41AC"))[R3], R1 |
  | I2  | ADD R4 \<- R6, R7 | ADD R4 \<- R6, R7 |
  | I3  | MUL R5 \<- R6, R8 | MUL R5 \<- R6, R8 |
  | I4  | ADD R7 \<- R9, R9 | ADD R7 \<- R9, R9 |
]

I1 has a dependency on I0, I2, I3, I4 are independent instructions.

First ADD stalls the whole pipeline because its souce reg R3 is unavailable. Later independent instructions cannnot get dispatched.

The sequences differ because load latency is variable and unknown until runtime. This affects both compiler scheduling and microarchitecture. So loads will cause a lot more headache.

=== Preventing Dispatch Stalls

Problem: in-order dispatch (scheduling/execution).

Solution: out-of-order dispatch (scheduling/execution). The basic idea is similar to dataflow: "fire" an instruction only when its inputs are ready, but do not expose dataflow execution in the ISA.

Other possible ways to prevent dispatch stalls:
1. Compile-time instruction scheduling/reordering.
2. Value prediction.
3. Fine-grained multithreading.(All instructions are independent from different threads, the pipeline never stalls. But this requires to have enough threads, and if we care about the performance of a single thread (we can't resort it to multithreading), this is useless.)

== Out-of-Order Execution (Dynamic Scheduling)

*Move non-ready instructions out of the way of independent ones*. The resting areas for non-ready instructions are *reservation stations*.

- Monitor the source values of each instruction in the waiting area.
- When all source values are available, "fire" (dispatch) the instruction.
- Instructions are dispatched in dataflow order, not control-flow order.

Benefit: *latency tolerance*. Independent instructions can execute and complete in the presence of a long-latency operation.

=== In-Order versus Out-of-Order Dispatch

In order dispatch + precise exceptions:
#three-line-table(
  columns: (2.2fr, 4.8fr),
  inset: 4pt,
  align: left,
)[
  | *Instruction* | *Pipeline* |
  | :------------ | :--------- |
  | MUL R3 \<- R1, R2 | F D E E E E R W |
  | ADD R3 \<- R3, R1 |   F D stall E R W |
  | ADD R4 \<- R6, R7 |     F stall D E R W |
  | MUL R5 \<- R6, R8 |             F D E E E E E R W |
  | ADD R7 \<- R9, R9 |               F D stall E R W |
]

Out-of-order dispatch + precise exceptions:
#three-line-table(
  columns: (2.2fr, 4.8fr),
  inset: 4pt,
  align: left,
)[
  | *Instruction* | *Pipeline* |
  | :------------ | :--------- |
  | MUL R3 \<- R1, R2 | F D E E E E R W |
  | ADD R3 \<- R3, R1 |   F D wait E R W |
  | ADD R4 \<- R6, R7 |     F D E R W |
  | MUL R5 \<- R6, R8 |       F D E E E E E R W |
  | ADD R7 \<- R9, R9 |         F D wait E R W |
]

With in-order dispatch, a dependent instruction stalls the whole front end. With out-of-order dispatch, it waits in a reservation station while independent instructions proceed. In the slide example, the same sequence takes 16 cycles with in-order dispatch and 12 cycles with out-of-order dispatch.

=== Enabling OoO Execution

1. Link the consumer of a value to the producer.
  - Register renaming associates a *tag* with each data value.
2. Buffer instructions until they are ready to execute.
  - Insert each renamed instruction into a reservation station.
3. Track readiness of source values.
  - Broadcast the tag when a value is produced.
  - Instructions compare source tags with the broadcast tag; a match makes the source ready.
4. Dispatch ready instructions to their functional units.
  - An instruction wakes up when all sources are ready.
  - If multiple instructions are awake, select one per functional unit.

== Tomasulo's Algorithm for OoO Execution

OoO execution with register renaming was invented by Robert Tomasulo for the IBM 360/91 floating-point units. The major difference in modern processors is *precise exceptions*, provided by the HPS work of Patt, Hwu, and Shebanow.

OoO variants are used in most high-performance processors, including Intel Pentium Pro, AMD K5, Alpha 21264, MIPS R10000, IBM POWER5, IBM z196, Oracle UltraSPARC T4, ARM Cortex A15, and Apple M1.

== Two Humps in a Modern Pipeline

#figure(
  html.frame(ooo-two-humps()),
  caption: [An OoO pipeline: instructions schedule and execute out of order, while the reorder buffer retires them in order.],
) <fig-ooo-two-humps>

#three-line-table(
  columns: (1.35fr, 1.8fr, 1.8fr),
  inset: 5pt,
  align: left,
)[
  | *Pipeline region* | *Structure* | *Order* |
  | :---------------- | :--------- | :----- |
  | Hump 1 | Reservation stations (scheduling window) | In-order dispatch into an out-of-order scheduling window |
  | Hump 2 | Reordering, using a ROB (instruction/active window) | Out-of-order completion, in-order retirement |
  | Communication | Tag and value broadcast bus | Producers wake consumers |
]

The scheduling window and the reorder window are the two "humps" of a modern pipeline.

== Register Rename Table

Here we rename reg ID to the reservation-station entry.

A register rename table (register alias table) stores a tag, value, and valid bit for each register.


  #three-line-table[
    | *Reg* | R1 | R2 | R3 | R4 | R5 | R6 | R7 | R8 | R9 | R10 | R11 |
    | *Valid* | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
    | *Value* | - | - | - | - | - | - | - | - | - | - | - |
    | *Tag* | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- |
  ]


- Valid bit set: the value in the table is correct
- Valid bit clear: tag identifies where the value will be produced. (The tag is a unique name for the value to be produced; it need not be the reservation-station entry ID.)

=== Tomasulo's Algorithm

- If a reservation station is avaiable before renaming, insert the instruction and its renamed operands into it; otherwise stall.
- While waiting(in reservation station), the instruction watches the common data bus for the tags of its sources.
  - When a tag is seen, capture the value in the reservation station.
  - When both operands are available, the instruction is ready to dispatch.
- After execution, arbitrate for the common data bus and put the tagged value on it.
  - The register file listens to the bus. If its tag matches the broadcast tag, write the value and set its valid bit.
  - Reclaim the rename tag when no valid copy remains in the system.

=== OoO Execution Example

This is the six-instruction exercise used in the slides. The pipeline stages are `F` (fetch), `D` (decode/dispatch), `E` (execute), `R` (write to the reorder buffer), and `W` (retire/write architectural state).

#three-line-table(
  columns: (1.0fr, 2.9fr, 2.7fr),
  inset: 5pt,
  align: left,
)[
  | *ID* | *Instruction* | *Dependence* |
  | :--- | :----------- | :----------- |
  | I0 | MUL R1, R2 -> R3 | independent |
  | I1 | ADD R3, R4 -> R5 | RAW on I0 through `R3` |
  | I2 | ADD R2, R6 -> R7 | independent |
  | I3 | ADD R8, R9 -> R10 | independent |
  | I4 | MUL R7, R10 -> R11 | RAW on I2 and I3 through `R7`, `R10` |
  | I5 | ADD R5, R11 -> R5 | RAW on I1 and I4 through `R5`, `R11` |
]

Assume `ADD` takes four execute cycles, `MUL` takes six execute cycles, and the machine has one adder and one multiplier. Initially, all reservation stations are empty and all registers are valid.

==== In-Order Dispatch without Forwarding (31 cycles)

Without forwarding, a dependent instruction cannot consume a result until the producer writes it back. Therefore I1 waits for I0's `W`, and the in-order dispatcher also holds younger instructions behind I1. I4 later waits for both I2 and I3, and I5 waits for I1 and I4.

#figure(
  html.frame(ooo-timeline-no-forwarding()),
  caption: [In-order dispatch without forwarding. Gray bands are real cycle intervals; matching colored arrows show when each consumer can start after its producer writes back.],
)

The resulting in-order-dispatch pipelined machine takes *31 cycles without forwarding*. The long gaps are caused by waiting for register-file writeback and by the fact that a blocked instruction prevents younger independent instructions from being dispatched.

==== In-Order Dispatch with Full Forwarding (25 cycles)

With full forwarding, a result can be consumed as soon as it is produced by the execute pipeline rather than waiting for the register-file writeback. The dispatch order is still I0, I1, I2, I3, I4, I5, so a not-yet-ready instruction can still block younger instructions.

#figure(
  html.frame(ooo-timeline-forwarding()),
  caption: [In-order dispatch with full forwarding. Dependences wake earlier, but a blocked instruction still delays younger dispatches.],
)

Forwarding shortens the stalls, but it does not remove the in-order-dispatch bottleneck. The total is *25 cycles*.

==== Out-of-Order Dispatch with Full Forwarding (20 cycles)

Tomasulo scheduling places waiting instructions in reservation stations. While I1 waits for I0's result, the independent I2 and I3 can execute. After their results are forwarded, I4 can execute; after I1 and I4 produce their values, I5 can execute.

#figure(
  html.frame(ooo-timeline-out-of-order()),
  caption: [Out-of-order dispatch with full forwarding. I2 and I3 execute while I1 waits, exposing the independent work that reduces the total to 20 cycles.],
)

The key difference is not a shorter functional-unit latency; it is that independent instructions are allowed to pass a blocked instruction. With full forwarding and out-of-order dispatch, the sequence completes in *20 cycles*.

#three-line-table(
  columns: (2.5fr, 1fr, 3.5fr),
  inset: 5pt,
  align: left,
)[
  | *Machine* | *Cycles* | *Reason for the result* |
  | :-------- | :------: | :--------------------- |
  | Non-pipelined | 50 | `4 * 7 + 2 * 11`; no overlap between instructions |
  | In-order dispatch, no forwarding | 31 | Dependency waits reach the front end and block younger instructions |
  | In-order dispatch, full forwarding | 25 | Forwarding shortens producer-consumer waits, but dispatch remains in order |
  | OoO dispatch, full forwarding | 20 | Reservation stations expose independent work and forwarding wakes consumers |
]

=== Machine Simulation

Initially:
1. Reservation Stations (RS’s) are all Invalid (Empty)
2. All Registers are Valid

#three-line-table(
  columns: (.6fr, 3.8fr, 2.3fr),
  inset: 5pt,
  align: left,
)[
  | *ID* | *Program* | *Renamed destination* |
  | :--- | :------- | :-------------------- |
  | I0 | MUL R1, R2 -> R3 | R3 -> x (MUL) |
  | I1 | ADD R3, R4 -> R5 | R5 -> a (ADD) |
  | I2 | ADD R2, R6 -> R7 | R7 -> b (ADD) |
  | I3 | ADD R8, R9 -> R10 | R10 -> c (ADD) |
  | I4 | MUL R7, R10 -> R11 | R11 -> y (MUL) |
  | I5 | ADD R5, R11 -> R5 | R5 -> d (ADD) |
]


  #text(fill: rgb("#B65C00"), weight: "bold")[Register Alias Table]
  #three-line-table(inset: 3pt)[
    | *Reg*   | R1 | R2 | R3 | R4 | R5 | R6 | R7 | R8 | R9 | R10 | R11 |
    | *Valid* | 1  | 1  | 1  | 1  | 1  | 1  | 1  | 1  | 1  | 1   | 1   |
    | *Value* | 1  | 2  | 3  | 4  | 5  | 6  | 7  | 8  | 9  | 10  | 11  |
    | *Tag*   | -- | -- | -- | -- | -- | -- | -- | -- | -- | --  | --  |
  ]


ADD and MUL Execution Units have separate Tag & Value buses(output).

#text(
  fill: rgb("#B65C00"),
  weight: "bold",
)[Reservation Stations]

    #text(size: 9pt, weight: "bold")[RS for ADD Unit]
    #three-line-table(
      columns: (auto, .7fr, .8fr, .8fr, .7fr, .8fr, .8fr),
      inset: 3pt,
    )[
      | *RS* | *V1* | *Tag1* | *Val1* | *V2* | *Tag2* | *Val2* |
      | ---  | --   | ---    | ---    | --   | ---    | --- |
      | a    | 0    | --     | --     | 0    | --     | -- |
      | b    | 0    | --     | --     | 0    | --     | -- |
      | c    | 0    | --     | --     | 0    | --     | -- |
      | d    | 0    | --     | --     | 0    | --     | -- |
    ]
  


    #text(size: 9pt, weight: "bold")[RS for MUL Unit]
    #three-line-table(
      columns: (auto, .7fr, .8fr, .8fr, .7fr, .8fr, .8fr),
      inset: 3pt,
    )[
      | *RS* | *V1* | *Tag1* | *Val1* | *V2* | *Tag2* | *Val2* |
      | ---  | --   | ---    | ---    | --   | ---    | --- |
      | x    | 0    | --     | --     | 0    | --     | -- |
      | y    | 0    | --     | --     | 0    | --     | -- |
      | z    | 0    | --     | --     | 0    | --     | -- |
      | t    | 0    | --     | --     | 0    | --     | -- |
    ]
  

==== Cycle 2

#figure(html.frame(ooo-cycle-snapshot(2)))

MUL gets decoded and allocated into RS x
+ Step 1: Check if reservation station available. Yes: x
+ Step 2: Access the Register Alias Table
+ Step 3: Put source registers into reservation station x
+ Step 4: Rename destination register R3 -> x

R3 is now renamed to x. Its new value will produced by the reservation station that is identified by tag x.

==== Cycle 3

#figure(html.frame(ooo-cycle-snapshot(3)))

==== Cycle 4

#figure(html.frame(ooo-cycle-snapshot(4)))

==== Cycle 5

#figure(html.frame(ooo-cycle-snapshot(5)))

==== Cycle 6

#figure(html.frame(ooo-cycle-snapshot(6)))

==== Cycle 7

#figure(html.frame(ooo-cycle-snapshot(7)))

==== Cycle 8

#figure(html.frame(ooo-cycle-snapshot(8)))

#v(8pt)

#figure(
  html.frame(ooo-cycle8-broadcast()),
  caption: [Cycle 8 broadcasts. Each result bus carries a tag and value to every RAT and reservation-station comparator; only matching invalid entries capture the value.],
)

==== Cycle 9

#figure(html.frame(ooo-cycle-snapshot(9)))

==== Cycle 10

#figure(html.frame(ooo-cycle-snapshot(10)))

==== Cycle 11

#figure(html.frame(ooo-cycle-snapshot(11)))

==== Cycle 12

#figure(html.frame(ooo-cycle-snapshot(12)))

==== Cycle 13

#figure(html.frame(ooo-cycle-snapshot(13)))

==== Cycle 14

#figure(html.frame(ooo-cycle-snapshot(14)))

==== Cycle 15

#figure(html.frame(ooo-cycle-snapshot(15)))

==== Cycle 16

#figure(html.frame(ooo-cycle-snapshot(16)))

==== Cycle 17

#figure(html.frame(ooo-cycle-snapshot(17)))

==== Cycle 18

#figure(html.frame(ooo-cycle-snapshot(18)))

==== Cycle 19

#figure(html.frame(ooo-cycle-snapshot(19)))

==== Cycle 20

#figure(html.frame(ooo-cycle-snapshot(20)))

==== Some Questions

+ What is needed in hardware to perform tag broadcast and value capture?
  - make a value valid
  - wake up an instruction
+ Does the tag have to be the ID of the Reservation Station Entry?
+ What can potentially become the critical path?
  - Tag broadcast => value capture => instruction wake up
+ How can you reduce the potential critical paths?
  - More pipelining and prediction

=== Dataflow Graph and Instruction Window

An OoO engine dynamically builds the dataflow graph of a piece of a program. The graph is limited to the *instruction window*: all decoded but not yet retired instructions.

The six-instruction example above has dependencies through R3, R5, R7, R10, and R11. Register renaming makes the two definitions of R5 distinct, allowing the independent operations to proceed.

#figure(
  html.frame(ooo-dataflow-graph()),
  caption: [Dynamic dataflow graph for the six-instruction window. Tags x, a, b, c, y, and d name produced values; a and d are distinct versions of R5 after renaming.],
)

=== Hardware Cost of Tag Broadcast

Tag broadcast and value capture require wires, comparators, and logic to make a value valid and wake up an instruction. The tag can be any unique name that links producer to consumer.

Potential critical path:

`tag broadcast -> value capture -> instruction wakeup`

More pipelining and prediction can reduce this path.

Design choices include:
- When a reservation-station entry is deallocated.
  - Usually after result broadcast/writeback.
  - Speculatively in modern CPUs
- Dedicated reservation stations per functional unit versus a centralized pool.
  - Centralized: huge buffer, the dynamic utilization of the buffer may be good
  - Distributed: smaller buffers, energy may be lower, latency may be easier to handle. *Load Balance* is the problem.
  - specialize buffer to the func unit: load requires addr, add doesn't require=>don't need addr inside the buffer for add
- Storing values in reservation stations/ROB versus a centralized physical register file.
  - Tradeoffs?
- Timing: Exactly when does an instruction broadcasts its tag.
  - When broadcast tag and when value? Concurrently or in a serial manner?
- Many other design choices for OoO engines...

== OoO Execution with Precise Exceptions

Use a reorder buffer to reorder instructions before committing them to architectural state.

+ An instruction updates the RAT(Also called frontend register file) when it completes execution
+ An instruction updates a separate architectural register file when it retires
  - i.e., when it is the oldest in the machine and has completed execution(the architectural register file is always updated in program order)

But *values everywhere* in reservation stations, ROB entries, and frontend register file. Modern processors commonly consolidates the values in *a single physical register* file(also it's the rename space) for speculative and architectural registers, they can centralize the value storage(integer and floating-point files may remain separate). Everything else holds pointers.
- Two register maps store poiters to the physical register file:
  - Future/frontend register map for renaming.
  - Architectural/backend register map for maintaining precise state.

+ At Decode/Rename: Allocate DestPR to Dest Reg, Read and Update Frontend Register Map
+ Before Execution: Access Physical Register File to Get Source Values
+ After Execution: Access Physical Register File to Write Result Values
+ At Retirement : Update Architectural Register Map with DestPR

On an exception, flush the pipeline and copy the architectural register file/map into the frontend state.

Boggs et al., “The Microarchitecture of the Pentium 4 Processor,” ntel Technology Journal, 2001.

== Enabling OoO Execution

1. *Link* the consumer of a value to the producer
  - *Register renaming*: Associate a “tag” with each data value
2. *Buffer* instructions until they are ready
  - Insert instruction into *reservation stations* after renaming
3. Keep *track* of *readiness* of source values of an instruction
  - *Broadcast the “tag”* when the value is produced
  - Instructions *compare their “source tags”* to the broadcast tag => if match, source value becomes ready
4. When all source values of an instruction are ready, *dispatch* the instruction to functional unit (FU)
  - Wakeup and select/schedule the instruction


#series-navbar("en", nav)
