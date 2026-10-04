#import "../../index.typ": *
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: series-chapter.with(
  arch-notes-series,
  route: "docs/arch-notes/06-branch-prediction/",
  title: "Branch Prediction",
)

== Control Dependence

Question: what should the fetch PC be in the next cycle? The address of the next instruction.

If the fetched instruction is not a control-flow instruction, the next fetch PC is the next-sequential address, which is easy to determine if the instruction size is known. If the fetched instruction is a control-flow instruction, the next fetch PC depends on the branch type and its operands. We may not even know whether the fetched instruction is a control-flow instruction until decode.

== Branch Types

#three-line-table(
  columns: (1.25fr, 1.2fr, 1.25fr, 2.1fr),
  inset: 5pt,
  align: left,
)[
  | *Type* | *Direction at fetch* | *Possible next addresses* | *When resolved* |
  | :----- | :------------------- | :----------------------- | :-------------- |
  | Conditional | Unknown | 2 | Execute; often register-dependent |
  | Unconditional | Always taken | 1 | Decode, using PC + offset |
  | Call | Always taken | 1 | Decode, using PC + offset |
  | Return | Always taken | Many | Execute; register-dependent |
  | Indirect | Always taken | Many | Execute; register-dependent |
]

Different branch types are handled differently.

== How to Handle Control Dependences

The goal is to keep the pipeline full with the correct sequence of dynamic instructions. Possible solutions for a control-flow instruction:
- Stall the pipeline until the next fetch address is known.
- Guess the next fetch address with branch prediction.
- Employ delayed branching (a branch delay slot).
- Use fine-grained multithreading.
- Eliminate control-flow instructions with predicated execution.
- Fetch from both possible paths when both addresses are known (multipath execution).

Stalling fetch until the next PC is known can stall about half the cycles even for non-control-flow and unconditional branches, and conditional branches can be worse.

== Fine-Grained Multithreading

In fine-grained multithreading, each pipeline stage contains an instruction from a different, completely independent thread. There is no need to perform control- or data-dependence handling between those threads.

== The Branch Problem

Control-flow instructions are frequent: branches are about 15--25% of all instructions.

The next fetch address after a control-flow instruction is not determined until the branch resolution latency, N, cycles later. If the processor fetches W instructions per cycle, a branch misprediction wastes N times W instruction slots.

Example: N = 20 pipeline stages, W = 5-wide fetch, one branch per five instructions, and 500 instructions:

#three-line-table(
  columns: (1.25fr, 1.8fr, 1.7fr, 1.7fr),
  inset: 5pt,
  align: left,
)[
  | *Accuracy* | *Cycles* | *Extra work* | *IPC* |
  | :--------- | :------- | :----------- | :--- |
  | 100% | 100 | none | 500/100 |
  | 99% | `100 + 20 * 1 = 120` | 20% | `500/120` |
  | 90% | `100 + 20 * 10 = 300` | 200% | `500/300` |
  | 60% | `100 + 20 * 40 = 900` | 800% | `500/900` |
]

== Branch Prediction

Branch prediction guesses the next instruction to fetch. A fetch stage needs three predictions:
1. Whether the current instruction is a branch.
2. The branch direction (taken or not-taken).
3. The target address if it is taken.

The target address tends to remain the same for a given branch. A *branch target buffer (BTB)* caches target addresses. A direction predictor supplies taken/not-taken information; the target and direction are combined to form the next fetch address.

== Static Branch Prediction

=== Always Not-Taken

- Simple to implement; no BTB or direction predictor is needed.
- Accuracy is only about 30--40% for conditional branches.
- The compiler can lay out code so the likely path is the not-taken path.

=== Always Taken

- No direction predictor is needed.
- Accuracy is about 60--70% for conditional branches.
- Backward branches, such as loop branches, are usually taken; a backward branch has a target address lower than the branch PC.

=== Backward Taken, Forward Not-Taken (BTFN)

Predict backward loop branches as taken and forward branches as not-taken.

=== Profile-Based Prediction

The compiler runs a profile, determines the likely direction of each branch, and encodes that direction as a hint bit in the branch instruction.

Advantages:
- Per-branch prediction can be more accurate than always-taken/not-taken if the profile is representative.

Disadvantages:
- Requires hint bits in the instruction format.
- Accuracy depends on dynamic behavior and on the representativeness of the profile input set.

=== Program-Based Prediction

Use heuristics from program analysis to choose a statically predicted direction. Examples:
- Predict BLEZ as not-taken because negative integers often represent error values.
- Predict a branch guarding loop execution as taken.
- Predict pointer and floating-point comparisons as not-equal.

This does not require profiling, but heuristics may be poor or unrepresentative and require compiler/ISA support. Ball and Larus reported about a 20% misprediction rate for such heuristics.

=== Programmer-Based Prediction

The programmer supplies a prediction through language pragmas that qualify branches as likely-taken or likely-not-taken:

```c
if (likely(x)) { ... }
if (unlikely(error)) { ... }
```

Pragmas can also convey other optimization hints, such as whether a loop can be parallelized. The approach avoids profiling and program analysis, but requires programming-language, compiler, and ISA support and burdens the programmer.

== Combining Static Techniques

Static techniques can be combined. Their common disadvantage is that they cannot adapt at run time; a dynamic compiler can mitigate this, but not at fine granularity.

== Dynamic Branch Prediction

Idea: predict branches based on dynamic information.

Advantages:
- Adapts to the actual runtime behavior of a program.

Disadvantages:
- Requires hardware tables, update logic, and prediction state.
- Prediction structures consume area and energy and can become a critical-path component.

The simplest dynamic predictor is last-time prediction: remember the direction taken the last time a branch executed and predict the same direction next time.

