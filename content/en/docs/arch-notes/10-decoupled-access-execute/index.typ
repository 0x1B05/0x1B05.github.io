#import "../../index.typ": *
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: series-chapter.with(
  arch-notes-series,
  route: "docs/arch-notes/10-decoupled-access-execute/",
  title: "Decoupled Access-Execute",
)

== Decoupled Access/Execute (DAE)

Motivation: Tomasulo's algorithm was too complex to implement in the 1980s, before the Pentium Pro.

Idea: decouple operand access and execution with two separate instruction streams that communicate through ISA-visible queues.

The compiler generates two streams:
- *A stream*: accesses operands and memory.
- *E stream*: executes operations.

The streams synchronize at control-flow instructions using branch queues.

Advantages:
- The execute stream can run ahead of the access stream and vice versa.
- If A waits for memory, E can perform useful work.
- If A hits in cache, it can supply data to a lagging E stream.
- Queues reduce the number of required registers.
- Limited out-of-order execution is achieved without wakeup/select complexity.

Disadvantages:
- The compiler must partition the program and manage queues; this determines the amount of decoupling.
- Branch instructions require synchronization between A and E.
- Multiple instruction streams must be managed, although one stream can be steered into separate pipelines.

The Astronautics ZS-1 used a single stream steered into A and X pipelines, with each pipeline operating in order.

== Loop Unrolling

Loop unrolling replicates the loop body multiple times in one iteration:

```c
for (int i = 0; i < N; i += 4) {
  A[i]   = A[i]   + B[i];
  A[i+1] = A[i+1] + B[i+1];
  A[i+2] = A[i+2] + B[i+2];
  A[i+3] = A[i+3] + B[i+3];
}
```

Benefits:
- Reduces loop-maintenance overhead, such as induction-variable updates and loop-condition tests.
- Enlarges the basic block and the compiler's analysis scope, enabling more optimization and scheduling.

Costs:
- An iteration count not divisible by the unroll factor requires extra handling.
- Code size increases.

== Communication Queues and Synchronization

Decoupling works only if the streams communicate without reintroducing a shared centralized scheduler. FIFO queues carry values and enforce producer-consumer order:

- The access stream computes an address, performs a load, and enqueues the value for the execute stream.
- The execute stream dequeues operands, computes results, and may enqueue store data back to the access stream.
- A full queue applies backpressure to its producer; an empty queue stalls its consumer.

Queue depth determines how far one stream can run ahead. Shallow queues are cheap but quickly recouple the streams. Deep queues tolerate longer latency variation but consume storage and make exception recovery more difficult.

Control flow must remain consistent across both streams. Branch queues communicate branch outcomes or synchronize corresponding control points. If one stream follows a different path, queued values would no longer correspond to the same dynamic operations.

== How DAE Tolerates Latency

Suppose the access stream encounters a cache miss. If the execute queue already contains operands, the execute stream continues working until it exhausts them. Conversely, if arithmetic takes longer than address generation, the access stream can run ahead and create future memory requests until an output queue fills.

This produces a restricted form of out-of-order overlap:

- Operations remain ordered within each stream.
- The streams progress independently relative to each other.
- FIFO order substitutes for general tag matching and associative wakeup.

DAE works well when a compiler can separate address generation from value computation and when their rates vary enough for queues to absorb the difference. It works poorly when every address immediately depends on an execute result, when control flow is irregular, or when the two streams repeatedly synchronize.

== Implementations and Descendants

The Astronautics ZS-1 steered one instruction stream into separate access and execute pipelines. Each pipeline operated in order, but their relative progress was decoupled by queues.

Modern processors use the same principle internally even without a DAE ISA. Intel Pentium 4 separated memory operations from arithmetic scheduling; contemporary out-of-order cores use load/store queues, address-generation units, and separate integer/floating-point schedulers. These designs are not classic compiler-visible DAE, but they preserve its central idea: partition the machine so latency in one subsystem does not immediately stop every other subsystem.

== DAE Design Checklist

#three-line-table(
  columns: (1.3fr, 2.15fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Question* | *Why it matters* | *Failure mode* |
  | :--------- | :--------------- | :------------- |
  | How are instructions partitioned? | Determines available decoupling | Frequent cross-stream dependences |
  | What crosses each queue? | Defines communication bandwidth | Queue traffic exceeds computation benefit |
  | How deep are queues? | Controls runahead distance | Full/empty stalls or excessive storage |
  | How are branches synchronized? | Keeps streams on matching dynamic paths | Values from different paths are paired |
  | How are faults recovered? | Preserves precise architectural state | One stream has consumed speculative values |
  | How are rates balanced? | Keeps both streams productive | One stream permanently backpressures the other |
]

