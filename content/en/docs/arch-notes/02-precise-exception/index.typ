#import "../../index.typ": *
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#import "../_diagrams/rob.typ": ooo-two-humps, rob-bypass-paths, rob-data-path
#show: series-chapter.with(
  arch-notes-series,
  route: "docs/arch-notes/02-precise-exception/",
  title: "Precise Exceptions",
)

Exception-causing  instruction: `DIV R4 <- R1, R2`(e.g., DIV by zero)

== Exceptions and Interrupts

#definition(title: "Exceptions && Interrupts")[
  - Exceptions: Due to *internal* problems in execution of the program
    - Divide by zero
    - Overflow
    - Undefined opcode
    - General protection (or access protection)
    - Page fault
    - ...
  - Interrupts: Due to *external* problems in execution of the program
    - I/O device needing service (e.g., keyboard input, video input)
    - (Periodic) system timer expiration
    - Power failure
    - Machine check
    - ...
]

Both exceptions and interrupts require
- stopping of the current program
- saving the architectural state
- handling the exception/interrupt à switch to handler
- (if possible and makes sense) returning back to program execution

- When to Handle
  - Exceptions: when detected (and known to be non-speculative)
  - Interrupts: when convenient, Except for very high priority ones(e.g., Power failure, Machine check (error))
- Priority: process (exception), depends (interrupt)
- Handling Context: process (exception), system (interrupt)

== Precise Exceptions/Interrupts

*The architectural state should be consistent (precise) when the exception/interrupt is ready to be handled*
+ All previous instructions should be completely retired
+ No later instruction should be retired

#tip[ Retire = commit = finish execution and update arch.state ]

When the oldest instruction ready-to-be-retired is detected to have caused an exception, the control logic
- Ensures architectural state is precise (register file, PC, memory)
- Flushes all younger instructions in the pipeline
- Saves PC and registers (as specified by the ISA)
- Redirects the fetch engine to the appropriate exception handling routine

Why Do We Want Precise Exceptions?
- Semantics of the von Neumann model ISA specifies it(von Neumann vs. Dataflow)
- Aids software debugging
- Enables (easy) recovery from exceptions
- Enables (easily) restartable processes
- Enables traps into software (e.g., software implemented opcodes)

=== Ensuring Precise Exceptions

- Single-cycle: Instruction boundary == Cycle boundary
  - An instruction is guaranteed to be finished in one cycle => no possibility of violating sequential execution semantics
- Multi-cycle
  + Add special states in the control FSM that lead to the exception or interrupt handlers. Switch to the handler only at a precise state => before fetching the next instruction

#figure(
  image(
    "imgs/14-precise-exception-in-multi-cycle-datapath.png",
    width: 80%,
  ),
  caption: [Precise Exception in Multi-Cycle Datapath],
) <fig-14-precise-exception-in-multi-cycle-datapath>

#figure(
  image(
    "imgs/14-precise-exception-in-multi-cycle-datapath2.png",
    width: 80%,
  ),
  caption: [],
) <fig-14-precise-exception-in-multi-cycle-datapath2>

#figure(
  image("imgs/14-precise-exception-in-multi-cycle-fsm.png", width: 80%),
  caption: [],
) <fig-14-precise-exception-in-multi-cycle-fsm>

Instructions can take different number of cycles in EXECUTE stage => This complicates exception/interrupt handling

== Solutions: Supporting Precise Exceptions

How do we support precise exceptions in the presence of instructions completing out of program order? *Reorder buffer*

=== Solution I: Reorder Buffer (ROB)

Idea: *Complete instructions out-of-order, but reorder them before making results visible to architectural state*
- When instruction is *decoded*, it reserves the next-sequential entry in a special buffer called the Reorder Buffer (ROB)
- When instruction *completes*, it writes result into ROB entry
- When instruction *oldest in ROB* and it has completed without exceptions, its result moved to reg. file or memory

ROB is implemented as a circular queue in hardware

A hardware structure that keeps information about all instructions that are decoded but not yet retired/committed

==== ROB Data Path

#figure(
  html.frame(rob-data-path()),
  caption: [ROB data path. Functional units may finish in any order; only the ready entry at the ROB head can commit architectural state.],
) <fig-rob-data-path>

==== ROB Circular Queue

#figure(
  table(
    columns: (1.2fr, 1fr, 2fr),
    inset: 5pt,
    align: center + horizon,
    stroke: 0.45pt,
    fill: (x, y) => if y == 0 { rgb("#E8F0FE") } else if y == 1 or y == 5 {
      rgb("#DFF4E8")
    },
    [*Pointer*], [*ROB entry*], [*Meaning*],
    [head ->], [E0], [oldest instruction; next candidate to retire],
    [], [E1], [older in-flight instruction],
    [], [E2], [older in-flight instruction],
    [], [...], [intermediate entries],
    [youngest ->], [E8], [most recently allocated instruction],
    [tail ->], [next free entry], [allocation continues after E8],
    [], [...], [free or in-flight entries],
    [], [E13], [near the physical end of the array],
    [], [E14], [near the physical end of the array],
    [], [E15], [wraps around to E0],
  ),
  caption: [A snapshot of the ROB as a circular queue. Head advances on retirement; tail advances on allocation, and the physical array wraps from E15 back to E0.],
) <fig-rob-circular-queue>

==== Fields in One ROB Entry

#figure(
  [
    #table(
      columns: (.35fr, 1.1fr, 1.1fr, 1fr, 1fr, .55fr, 1.75fr, 1.1fr),
      inset: 5pt,
      align: center + horizon,
      stroke: 0.55pt,
      table.cell(fill: rgb("#E6F4EA"))[#text(fill: rgb("#0B6B37"))[V]],
      table.cell(fill: rgb("#E8F0FE"))[#text(
        fill: rgb("#1A41AC"),
      )[DestReg\ ID]],
      table.cell(fill: rgb("#E8F0FE"))[#text(
        fill: rgb("#1A41AC"),
      )[DestReg\ Val]],
      table.cell(fill: rgb("#E8F0FE"))[#text(
        fill: rgb("#1A41AC"),
      )[Store\ Addr]],
      table.cell(fill: rgb("#E8F0FE"))[#text(
        fill: rgb("#1A41AC"),
      )[Store\ Data]],
      table.cell(fill: rgb("#FDECEC"))[#text(fill: rgb("#C5221F"))[PC]],
      table.cell(fill: rgb("#E6F4EA"))[#text(
        fill: rgb("#0B6B37"),
      )[Result/data\ valid bits +\ control bits]],
      table.cell(fill: rgb("#FDECEC"))[#text(fill: rgb("#C5221F"))[Exception?]],
    )
  ],
  caption: [Layout of one ROB entry. It holds the destination or store result, the status needed to decide readiness, and the information needed for precise recovery.],
) <tab-rob-entry-fields>

Everything required to:
- correctly reorder instructions back into the program order
- update the architectural state with the instruction’s result(s), if instruction can retire without any issues
- handle an exception/interrupt precisely, if an exception/interrupt needs to be handled before retiring the instruction

Need valid bits to keep track of readiness of the result(s) and find out if the instruction has completed execution

==== Reorder Buffer: How to Access?

What if a later instruction needs a value in the reorder buffer?

A register value can be in the register file, reorder buffer, (or bypass/forwarding paths)

#figure(
  html.frame(rob-bypass-paths()),
  caption: [Accessing a value through the register file, the ROB's content-addressable lookup, or bypass paths from completed functional units.],
) <fig-rob-bypass-paths>

===== Reorder Buffer (ROB) Example

#three-line-table(
  columns: (auto, 1fr, 1.25fr, 1fr),
  inset: 6pt,
  align: left,
)[
  | *Instruction* | *Operation* | *Dependence* | *ROB role* |
  | :------------ | :---------- | :---------------------- | :----------- |
  | I0 | MUL R1, R2 -> #text(fill: rgb("#1A41AC"), weight: "bold")[R3]  |                         | E0, old R3 version |
  | I1 | MUL #text(fill: rgb("#1A41AC"), weight: "bold")[R3], R4 -> R11 | RAW: reads R3 from I0 | E1, waits for E0 |
  | I2 | ADD R5, R6 -> #text(fill: rgb("#1A41AC"), weight: "bold")[R3]  | WAW: newer write to R3 | E2, new R3 version |
  | I3 | ADD #text(fill: rgb("#1A41AC"), weight: "bold")[R3], R8 -> R12 | RAW: reads R3 from I2 | E3, waits for E2 |
]

Initially, all registers are valid in the register file, and the ROB is empty.


    #figure(
      three-line-table(
        columns: (auto, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Register* | *Valid?* | *Value* |
        | :--------- | ------ | :------ |
        | R0 | 1 | -- |
        | R1 | 1 | -- |
        | R2 | 1 | -- |
        | .. | 1 | -- |
        | R31| 1 | -- |
      ],
      caption: [Register File (RF)],
      numbering: none,
    )
  


    #figure(
      three-line-table(
        columns: (auto, auto, 1fr, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Entry* | *Valid?* | *Dest reg ID* | *Dest reg value* | *Written?* |
        | :------ | ------ | :------------ | :--------------- | :--------- |
        | E0 (head) | 0      | --            | --               | 0 |
        | E1        | 0      | --            | --               | 0 |
        | ..        | 0      | --            | --               | 0 |
        | E15 (tail) | 0     | --            | --               | 0 |
      ],
      caption: [Reorder Buffer (ROB)],
      numbering: none,
    )
  

Decode I0:MUL R1, R2 -> R3(suppose R1=1, R2=2)

    #figure(
      three-line-table(
        columns: (auto, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Register* | *Valid?* | *Value* |
        | :--------- | ------ | :------ |
        | R0 | 1 | -- |
        | R1 | 1 | 1  |
        | R2 | 1 | 2  |
        | R3 | 0 | -- |
        | .. | 1 | -- |
        | R31| 1 | -- |
      ],
      caption: [Register File (RF)],
      numbering: none,
    )
  


    #figure(
      three-line-table(
        columns: (auto, auto, 1fr, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Entry* | *Valid?* | *Dest reg ID* | *Dest reg value* | *Written?* |
        | :------ | ------ | :------------ | :--------------- | :--------- |
        | E0 (head) | 1      | R3            | --               | 0 |
        | E1        | 0      | --            | --               | 0 |
        | ..        | ..     | --            | --               | 0 |
        | E15 (tail) | 0     | --            | --               | 0 |
      ],
      caption: [Reorder Buffer (ROB)],
      numbering: none,
    )
  

Decode I1: MUL R3, R4 -> R11

First check
- R3 is available? No!
- R4 is available? Yes, suppose R4=4


    #figure(
      three-line-table(
        columns: (auto, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Register* | *Valid?* | *Value* |
        | :--------- | ------ |   :------ |
        | R0 | 1 | -- |
        | R1 | 1 | 1  |
        | R2 | 1 | 2  |
        | R3 | 0 | -- |
        | R4 | 1 | 4  |
        | .. | 1 | -- |
        | R11| 0 | -- |
        | .. | 1 | -- |
        | R31| 1 | -- |
      ],
      caption: [Register File (RF)],
      numbering: none,
    )
  


    #figure(
      three-line-table(
        columns: (auto, auto, 1fr, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Entry* | *Valid?* | *Dest reg ID* | *Dest reg value* | *Written?* |
        | :------ | ------ | :------------ | :--------------- | :--------- |
        | E0 (head) | 1      | R3            | 1568             | 1 |
        | E1        | 1      | R11           | --               | 0 |
        | ..        | ..     | --            | --               | 0 |
        | E15 (tail) | 0     | --            | --               | 0 |
      ],
      caption: [Reorder Buffer (ROB)],
      numbering: none,
    )
  

Suppose there's a gap between I0 and I1. When I1 wants to get R3, where could R3 be?
- Not in the RF, cause valid bit is zero.
- Suppose R3 have written R3 in ROB.
  
    #figure(
      three-line-table(
        columns: (auto, auto, 1fr, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Entry* | *Valid?* | *Dest reg ID* | *Dest reg value* | *Written?* |
        | :------ | ------ | :------------ | :--------------- | :--------- |
        | E0 (head) | 1      | R3            | 1568             | 1 |
        | E1        | 1      | R11           | --               | 0 |
        | ..        | ..     | --            | --               | 0 |
        | E15 (tail) | 0     | --            | --               | 0 |
      ],
      caption: [Reorder Buffer (ROB)],
      numbering: none,
    )
  
  - We need search the content of the ROB under *Dest reg ID* and compare if there exists an content equals to R3. If exists, we need the latest one and get the value from that one.

Decode I2: ADD R5,R6->R3

    #figure(
      three-line-table(
        columns: (auto, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Register* | *Valid?* | *Value* |
        | :--------- | ------ |  :------ |
        | R0 | 1 | -- |
        | R1 | 1 | 1  |
        | R2 | 1 | 2  |
        | R3 | 0 | -- |
        | R4 | 1 | 4  |
        | R5 | 1 | 5  |
        | R6 | 1 | 6  |
        | .. | 1 | -- |
        | R11| 0 | -- |
        | .. | 1 | -- |
        | R31| 1 | -- |
      ],
      caption: [Register File (RF)],
      numbering: none,
    )
  


    #figure(
      three-line-table(
        columns: (auto, auto, 1fr, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Entry* | *Valid?* | *Dest reg ID* | *Dest reg value* | *Written?* |
        | :------ | ------ | :------------ | :--------------- | :--------- |
        | E0 (head) | 1      | R3            | 1568             | 1 |
        | E1        | 1      | R11           | --               | 0 |
        | E2        | 1      | R3           | --               | 0 |
        | ..        | ..     | --            | --               | 0 |
        | E15 (tail) | 0     | --            | --               | 0 |
      ],
      caption: [Reorder Buffer (ROB)],
      numbering: none,
    )
  

The only reason that these two instructions are writing to R3 is because there are not enought RF. The R3s in E0 and E2 are different. This is how a rob enables a renaming of registers.

Decode I3: ADD R3, R8 -> R12

    #figure(
      three-line-table(
        columns: (auto, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Register* | *Valid?* |  *Value* |
        | :--------- | ------ |    :------ |
        | R0 | 1 | -- |
        | R1 | 1 | 1  |
        | R2 | 1 | 2  |
        | R3 | 0 | -- |
        | R4 | 1 | 4  |
        | R5 | 1 | 5  |
        | R6 | 1 | 6  |
        | R7 | 1 | -- |
        | R8 | 1 | 8  |
        | .. | 1 | -- |
        | R11| 0 | -- |
        | R12| 0 | -- |
        | .. | 1 | -- |
        | R31| 1 | -- |
      ],
      caption: [Register File (RF)],
      numbering: none,
    )
  


    #figure(
      three-line-table(
        columns: (auto, auto, 1fr, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Entry* | *Valid?* | *Dest reg ID* | *Dest reg value* | *Written?* |
        | :------ | :-------:| :------------ | :--------------- | :--------- |
        | E0 (head) | 1      | R3            | 1568             | 1 |
        | E1        | 1      | R11           | --               | 0 |
        | E2        | 1      | R3            | --               | 0 |
        | E3        | 1      | R12           | --               | 0 |
        | ..        | ..     | --            | --               | 0 |
        | E15 (tail) | 0     | --            | --               | 0 |
      ],
      caption: [Reorder Buffer (ROB)],
      numbering: none,
    )
  

We want to get the value of R3.
+ not in the RF
+ in ROB, E0 and E2 match, but it should be E2(latest R3)

Content-addressable search is very hardware-intensive. Today, ROB size could be more than 1000. The search becomes even more expensive.

==== Simplifying Reorder Buffer Access

- Idea: Use indirection

+ Access register file first (check if the register is valid)
  - If register not valid, register file stores the ID of the reorder buffer entry that contains (or will contain) the value of the register
  - *Mapping of the register to a ROB entry*: Register file maps the register to a reorder buffer entry if there is an in-flight instruction writing to the register
+ Access reorder buffer next
+ Now, reorder buffer does not need to be content addressable

===== Simplifying Reorder Buffer (ROB) Example

Decode I0:MUL R1, R2 -> R3(suppose R1=1, R2=2)

    #figure(
      three-line-table(
        columns: (1.3fr, 1fr, .95fr, 2fr),
        inset: 3pt,
        align: center,
      )[
        | *Register* | *Valid?* | *Value* | *Tag (ROB ID)* |
        | :--------- | ------ | :------- | :------- |
        | R0 | 1 | -- | -- |
        | R1 | 1 | 1  | -- |
        | R2 | 1 | 2  | -- |
        | R3 | 0 | -- | E0 |
        | .. | 1 | -- | -- |
        | R31| 1 | -- | -- |
      ],
      caption: [Register File (RF)],
      numbering: none,
    )
  


    #figure(
      three-line-table(
        columns: (auto, auto, 1fr, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Entry* | *Valid?* | *Dest ID* | *Dest val* | *Written?* |
        | :------ | ------ | :------------ | :--------------- | :--------- |
        | E0 (head) | 1      | R3            | --               | 0 |
        | E1        | 1      | R11           | --               | 0 |
        | ..        | 0      | --            | --               | 0 |
        | E15 (tail) | 0     | --            | --               | 0 |
      ],
      caption: [Reorder Buffer (ROB)],
      numbering: none,
    )
  

No content-addressable search here.

Decode I1: MUL R3, R4 -> R11

    #figure(
      three-line-table(
        columns: (1.3fr, 1fr, .95fr, 2fr),
        inset: 3pt,
        align: center,
      )[
        | *Register* | *Valid?* | *Value* | *Tag (ROB ID)* |
        | :--------- | ------ | :------- | :------- |
        | R0 | 1 | -- | -- |
        | R1 | 1 | 1  | -- |
        | R2 | 1 | 2  | -- |
        | R3 | 0 | -- | E0 |
        | R4 | 1 | 4  | -- |
        | .. | 1 | -- | -- |
        | R11| 0 | -- | E1 |
        | .. | 1 | -- | -- |
        | R31| 1 | -- | -- |
      ],
      caption: [Register File (RF)],
      numbering: none,
    )
  


    #figure(
      three-line-table(
        columns: (auto, auto, 1fr, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Entry* | *Valid?* | *Dest ID* | *Dest val* | *Written?* |
        | :------ | ------ | :------------ | :--------------- | :--------- |
        | E0 (head) | 1      | R3            | --               | 0 |
        | E1        | 1      | R11           | --               | 0 |
        | ..        | 0      | --            | --               | 0 |
        | E15 (tail) | 0     | --            | --               | 0 |
      ],
      caption: [Reorder Buffer (ROB)],
      numbering: none,
    )
  

Decode I2: ADD R5,R6->R3


    #figure(
      three-line-table(
        columns: (1.3fr, 1fr, .95fr, 2fr),
        inset: 3pt,
        align: center,
      )[
        | *Register* | *Valid?* | *Value* | *Tag (ROB ID)* |
        | :--------- | ------ | :------- | :------- |
        | R0 | 1 | -- | -- |
        | R1 | 1 | 1  | -- |
        | R2 | 1 | 2  | -- |
        | R3 | 0 | -- | *E2* |
        | R4 | 1 | 4  | -- |
        | R5 | 1 | 5  | -- |
        | R6 | 1 | 6  | -- |
        | .. | 1 | -- | -- |
        | R11| 0 | -- | E1 |
        | .. | 1 | -- | -- |
        | R31| 1 | -- | -- |
      ],
      caption: [Register File (RF)],
      numbering: none,
    )
  


    #figure(
      three-line-table(
        columns: (auto, auto, 1fr, 1fr, auto),
        inset: 3pt,
        align: center,
      )[
        | *Entry* | *Valid?* | *Dest ID* | *Dest val* | *Written?* |
        | :------ | ------ | :------------ | :--------------- | :--------- |
        | E0 (head) | 1      | R3            | --               | 0 |
        | E1        | 1      | R11           | --               | 0 |
        | ..        | 0      | --            | --               | 0 |
        | E15 (tail) | 0     | --            | --               | 0 |
      ],
      caption: [Reorder Buffer (ROB)],
      numbering: none,
    )
  

==== Important: Register Renaming with a Reorde Buffer

WAW, WAR  are not true dependences:
The same register refers to values that have nothing to do with each other. They exist due to lack of register ID’s (i.e. names) in the ISA.

The register ID is renamed to the reorder buffer entry that will hold the register’s value
- Register ID -> ROB or RS entry ID
- Architectural register ID -> Physical register ID
- After renaming, ROB or RS entry ID used to refer to the register

This eliminates anti and output dependences: Gives the illusion that there are a large number of registers.

==== In-Order Pipeline with Reorder Buffer

- *Decode (D)*: Access regfile/ROB, allocate entry in ROB, check if instruction can execute, if so *dispatch* instruction
- *Execute (E)*: Instructions can complete out-of-order
- *Completion (R)*: Write result *to reorder buffer*
- *Retirement/Commit (W)*: Check oldest instruction for exceptions; if none, write result to architectural register file or memory; else, flush pipeline and start from exception handler

In-order dispatch/execution, out-of-order completion, in-order retirement

==== Reorder Buffer Tradeoff

- Advantages
  - Conceptually simple for supporting precise exceptions
  - Can eliminate false dependences
- Disadvantages
  - Reorder buffer needs to be accessed to get the results that are yet to be written to the register file
    - CAM or indirection à increased latency and complexity

- Other solutions aim to eliminate the disadvantages(not covered)
  - History buffer
  - Future file
  - Checkpointing

=== Solution II: History Buffer (HB)

Idea: update the register file when an instruction completes, but *undo updates when an exception occurs*.

- When an instruction is decoded, it reserves an HB entry.
- When the instruction completes, it stores the old value of its destination in the HB.
- When the instruction is oldest and there is no exception/interrupt, its HB entry is discarded.
- When the oldest instruction needs exception handling, old values in the HB are written back to architectural state from tail to head.

#three-line-table(
  columns: (1.2fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *History buffer* | *Role* |
  | :--------------- | :----- |
  | Register file | Updated immediately when execution completes |
  | HB entry | Saves the old destination value |
  | Normal retirement | Discard the entry |
  | Exception recovery | Unwind entries from tail to head |
]

Advantage: the register file contains up-to-date values for incoming instructions, so HB access is not on the critical path.

Disadvantages:
- The old value of the destination register must be read.
- The history buffer must be unwound on an exception, increasing exception/interrupt handling latency.

=== Comparison of Two Approaches

- *Reorder buffer*: pessimistic register-file update; update only with non-speculative values in program order. This makes access to new values more complex.
- *History buffer*: optimistic register-file update; update immediately, but log the old value for recovery. This makes logging old values more complex.

Can we get the best of both worlds? The principle is *heterogeneity*: have both types of register files.

=== Solution III: Future File (FF) + ROB

Idea: keep two register files (speculative and architectural).
- Architectural register file: updated in program order for precise exceptions; use a ROB to ensure in-order updates.
- Future register file: updated as soon as an instruction completes, if the instruction is the youngest one to write a register.
- The future file is used for fast access to latest register values (the speculative frontend state).
- The architectural file is used for state recovery on exceptions (the backend architectural state).

Advantages:
- No need to read new values from the ROB (no CAM or indirection).
- No need to read the old destination value.

Disadvantages:
- Requires multiple register files.
- On an exception, the architectural register file must be copied to the future file.

=== In-Order Pipeline with Future File and Reorder Buffer

- Decode (D): access future file, allocate an ROB entry, check whether the instruction can execute, and dispatch it if so.
- Execute (E): instructions can complete out-of-order.
- Completion (R): write the result to the ROB and future file.
- Retirement/Commit (W): check for exceptions; if none, write the result to the architectural register file or memory; otherwise flush the pipeline, copy architectural state to the future file, and start from the exception handler.

In-order dispatch/execution, out-of-order completion, in-order retirement.

=== Reducing the Overhead of Two Register Files

Use indirection: keep a single storage for register data values and two register maps, also called register alias tables (RATs).
- Future map: fast access to the latest register values (frontend register map).
- Architectural map: state recovery on exceptions (backend register map).

In Intel Pentium III/Pro and Pentium 4, a Register Alias Table (RAT) points to where each register's current value is (or will be). The Pentium 4 discussion is from Boggs et al., *The Microarchitecture of the Pentium 4 Processor*, Intel Technology Journal (2001). Modern processors use related designs, including MIPS R10K and Alpha 21264.

== Reorder Buffer vs. Future Map

#three-line-table(
  columns: (1.25fr, 1.7fr, 1.7fr),
  inset: 5pt,
  align: left,
)[
  | *Property* | *Reorder buffer* | *Future map / file* |
  | :--------- | :--------------- | :----------------- |
  | Speculative values | Kept in ROB until commit | Available immediately through the future map |
  | Architectural state | Updated in order | Kept in the architectural map/file |
  | Main recovery action | Flush younger instructions; retire/finish older ROB entries | Restore architectural map/file to the frontend |
  | Main cost | ROB lookup (CAM or indirection) | Extra map/file storage and management |
]

== Exceptions and Branch Mispredictions

When the oldest instruction ready to be retired is detected to have caused an exception, the control logic:
- Recovers architectural state (register file, instruction pointer, and memory).
- Flushes all younger instructions in the pipeline.
- Saves the IP and registers as specified by the ISA.
- Redirects the fetch engine to the exception handling routine (vectored exceptions).

A branch misprediction resembles an ``exception'', except it is not visible to software; it is microarchitectural. Recovery is similar to exception handling, but can begin before the branch is the oldest instruction. All three state-recovery methods can be used.

The difference is frequency: branch mispredictions are much more common, so state recovery must be fast to minimize performance impact.

=== How Fast Is State Recovery?

Recovery latency affects:
- Exception service latency.
- Interrupt service latency.
- The latency to supply correct data to instructions fetched after a branch misprediction.

For the three methods:
- ROB: flush instructions younger than the branch, then finish all instructions in the ROB.
- HB: flush younger instructions, then rewind the HB from its tail to the branch and restore old values one by one.
- Future file: wait until the branch is oldest, copy the architectural register file to the future file, and flush the entire pipeline.

=== Checkpointing

Goal: restore frontend state (future file/map) so that the correct next instruction after a branch can execute immediately after a misprediction is resolved.

Idea: checkpoint the frontend register state/map when a branch is decoded and keep each checkpoint updated with results from instructions older than that branch.

- When a branch is decoded, make a copy of the future file/map and associate it with the branch.
- When an instruction produces a register value, update all checkpoints younger than that instruction.
- When a branch misprediction is detected, restore the checkpoint associated with that branch, flush younger pipeline instructions, and deallocate younger checkpoints.

Advantages:
- Correct frontend register state is available immediately after restoration, giving low recovery latency.

Disadvantages:
- Storage overhead.
- Complexity in managing checkpoints.

Many modern processors use checkpointing, including MIPS R10000, Alpha 21264, and Pentium 4.

== Summary: Maintaining Precise State

- Reorder buffer
- History buffer
- Future register file
- Checkpointing

== Registers versus Memory

So far, we considered mainly registers as part of state. Memory differs fundamentally:
- Register dependences are known statically; memory dependences are determined dynamically.
- Register state is small; memory state is large.
- Register state is not visible to other threads/processors; memory state is shared between threads/processors in a shared-memory multiprocessor.

=== Maintaining Speculative Memory State: Stores

Undoing a memory write is more difficult than undoing a register write. One idea is to keep store address/data in the ROB. A load must then find its data among older stores.

A *store/write buffer* is similar to a ROB, but is used only for store instructions:
- It is a program-order list of uncommitted stores.
- When a store is decoded, allocate a store-buffer entry.
- When its address and data become available, record them in the entry.
- When the store is the oldest instruction in the pipeline, update the memory address (cache) with the store data.

Store-load handling will be covered later.


