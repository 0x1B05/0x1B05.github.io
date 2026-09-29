#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, tufted, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/08-vliw/",
  title: "VLIW Architectures",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/08-vliw/")

= VLIW Architectures

#series-navbar("en", nav)

#doc-toc("en")

== VLIW Concept

_This concept may arise into the future maybe 10 years underdown the road again because of some developments in ML. Compilers may not be as strong today to enable VLIW. If compilers are equipped with much stronger ML techniques, this discovery of parallelism can be much stronger._

- In a superscalar processor, *hardware* fetches multiple instructions and checks dependencies between them.
- In a VLIW (Very Long Instruction Word) processor, *the compiler packs independent instructions* into a larger instruction bundle; hardware fetches and executes the bundle concurrently.

VLIW *removes hardware dependency checking* between concurrently fetched instructions: simple hardware, complex compiler.

A VLIW word consists of multiple independent, potentially logically unrelated instructions. *The compiler finds independent instructions and statically schedules them into one bundle.*

```
PC    => add r1,r2,r3 | load r4,r5+4 | mov r6,r2 | mul r7,r8,r9
              ↓               ↓             ↓           ↓
EXEC          PE              PE            PE          PE
```

Traditional characteristics:
1. *Multiple instruction fetch/execute* and multiple functional units.
2. All instructions in a bundle execute in *lock step(all or none)*.
3. *Instructions* in a bundle are *statically aligned* with their functional units.

=== VLIW Performance Example(2-wide bundles)

Ideal IPC=2(6 instructions issued in 3 cycles)

```asm
bundle1: lw  $t0, 40($s0)    add $t1, $s1, $s2
bundle2: sub $t2, $s1, $s3   and $t3, $s3, $s4
bundle3: or  $t4, $s1, $s5   sw  $s5, 80($s0)
```

== Lock-Step Execution

If any operation in a VLIW instruction stalls, all concurrent operations stall. *The compiler handles dependency-related stalls*; hardware performs no dependency checking. Variable latency operations(like `mul`, operands known in runtime) and memory stalls are therefore difficult.

Pure VLIW is almost impossible in real hardware. We have to have some stall signal(means this op is taking longer than expected, so stall the entire bundle, stall the pipeline). That's why VLIW has not been successful, it doesn't have this tolerance to variable latency.

== VLIW Philosophy

VLIW follows the RISC philosophy of simple instructions and hardware, but issues multiple instructions in parallel. The compiler performs the hard work of finding instruction-level parallelism and reordering simple instructions. Hardware executes each bundle in lock step, enabling higher frequency, easier design, and lower power.

== Commercial VLIW Machines

- Multiflow TRACE (7-wide and 28-wide).
- Cydrome Cydra 5.
- Transmeta Crusoe (x86 binary translated to internal VLIW).
- TI C6000, Trimedia, STMicro DSP/embedded processors, and some GPUs.
- Intel IA-64, which is not fully VLIW but follows VLIW principles and is also called EPIC(Explicitly Parallel Instruction Computing). Instruction bundles can have dependent instructions. A few bits in the instruction format specify explicitly which instructions in the bundle are dependent on which other ones.

== VLIW Tradeoffs

Advantages:
- No dynamic scheduling hardware.
- No dependency checking within a bundle and no renaming for same-bundle issue.
- No hardware alignment/distribution after fetch.

Disadvantages:
- The compiler must find N independent operations per cycle. Otherwise NOPs increase code size and lose parallelism.
- Recompilation is required when width, instruction latencies, or functional units change.
- Lock-step execution makes independent operations wait for the longest-latency operation.

== VLIW Summary

*VLIW simplifies hardware but requires sophisticated compiler techniques.*

A compiler-only approach has poor tolerance for variable or long-latency operations, may generate many NOPs, and ties the static schedule to the microarchitecture. Code optimized for one generation can perform poorly on the next.

Many compiler optimizations developed for VLIW are useful in superscalar compilers. VLIW is most successful where the compiler can find parallelism easily, including embedded processors, DSPs, and GPUs.

== Basic Block Reordering

Likely-taken branches hurt always-not-taken prediction and make static scheduling difficult. Profile-guided code positioning can reorder basic blocks so the likely path is laid out sequentially.

A basic block has a single entry and a single exit. Reordering the blocks after profiling can reduce branch mispredictions.

== Superblocks

*Combine frequently executed basic blocks* into a single-entry, multiple-exit *superblock* that behaves like straight-line code.

Advantages:
- Fewer branch mispredictions.
- Aggressive compiler optimization and code reordering inside the superblock.

Disadvantages:
- Increased code size from tail duplication.
- Recompilation and profile dependence.

== ISA Translation

An implementation can translate one ISA into another internal ISA to reach a better tradeoff space:
- Programmer-visible ISA -> implementation ISA.
- CISC -> RISC.
- Scalar ISA -> VLIW ISA.

Intel and AMD translate x86 instructions into microoperations in hardware. Transmeta translated x86 into proprietary VLIW instructions in software using code-morphing software.

Translation changes the semantic-gap tradeoff: software, hardware, and the translator can all reorder operations.

== VLIW Scheduling Example

Consider a two-wide VLIW machine with one memory slot and one arithmetic slot. The compiler cannot simply place consecutive scalar instructions in the same bundle. It must construct a dependence graph, honor operation latency, and assign each operation to a compatible functional-unit slot.

#three-line-table(
  columns: (.8fr, 1.6fr, 1.6fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Bundle* | *Memory slot* | *ALU slot* | *Why this pairing is legal* |
  | :------- | :------------ | :--------- | :------------------------- |
  | 1 | Load `A[i]` | independent pointer update | No dependence between the two operations |
  | 2 | Load `B[i]` | independent loop preparation | First load is still in flight |
  | 3 | NOP | Add loaded values | Both load results are now available |
  | 4 | Store result | loop comparison | Store consumes the add result; comparison is independent |
]

If the compiler cannot fill a slot, the encoded NOP still consumes instruction-cache and fetch bandwidth. A two-wide machine achieves its ideal IPC of two only when both slots contain useful operations every cycle. Wider machines amplify the scheduling and code-size problem.

=== Static Schedule versus Dynamic Events

The static schedule assumes particular operation latencies. A cache miss, bank conflict, variable-latency divide, or implementation change can violate those assumptions. Lock-step VLIW hardware can stall the entire bundle, even when the other slots are independent.

Architectures can weaken pure VLIW semantics with interlocks, replay, scoreboarding, or explicit stop bits, but each mechanism moves complexity back into hardware. EPIC designs use compiler-exposed dependence information while retaining more hardware support than a classic all-or-none VLIW machine.

== Trace Scheduling and Region Formation

A basic block is often too small to contain enough independent operations for a wide VLIW machine. *Trace scheduling* profiles the program, chooses a likely path through several basic blocks, schedules that path as one region, and adds compensation code for side entrances or exits.

A *trace* can have multiple entrances. A *superblock* removes side entrances through tail duplication and therefore has one entrance but multiple exits. A *hyperblock* additionally uses predication to combine control-flow paths into a larger single-entry region.

#three-line-table(
  columns: (1.1fr, 1.8fr, 2.5fr),
  inset: 5pt,
  align: left,
)[
  | *Region* | *Control property* | *Compiler consequence* |
  | :------- | :----------------- | :--------------------- |
  | Basic block | Single entry, single exit | Easy analysis but limited scheduling scope |
  | Trace | Likely dynamic path; may have side entrances | Compensation code preserves off-trace behavior |
  | Superblock | Single entry, multiple exits | Tail duplication enables aggressive motion |
  | Hyperblock | Predicated single-entry region | More scope, but nullified work and predicate pressure |
]

The core tradeoff is scheduling scope versus code growth and profile dependence. The most aggressive schedule is valuable only if the chosen path remains frequent at runtime.

== Binary Translation and Compatibility

Static VLIW encodings expose machine width, slot types, and assumed latency. A binary built for one implementation is therefore difficult to run efficiently on a different implementation. Dynamic binary translation places a compatibility layer between the architectural ISA and the internal VLIW machine:

1. Decode a source-ISA region.
2. Translate it into internal operations.
3. Profile and optimize frequently executed regions.
4. Schedule independent operations into VLIW bundles.
5. Cache the translated code and preserve precise source-ISA state at exits or faults.

Transmeta used software code morphing to translate x86 into a proprietary VLIW ISA. NVIDIA Denver similarly combined an ARM-compatible interface with dynamic optimization. The approach restores implementation freedom, but translation time, code-cache capacity, exception mapping, self-modifying code, and memory ordering become part of the design.

#series-navbar("en", nav)
