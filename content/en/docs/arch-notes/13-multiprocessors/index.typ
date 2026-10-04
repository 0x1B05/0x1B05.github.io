#import "../../index.typ": *
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: series-chapter.with(
  arch-notes-series,
  route: "docs/arch-notes/13-multiprocessors/",
  title: "Multiprocessors, Memory Ordering, and Cache Coherence",
)

This chapter collects the parallelism, heterogeneity, bottleneck-acceleration,
memory-ordering, and cache-coherence ideas needed to reason about a modern
shared-memory multiprocessor. The central theme is that parallel hardware is a
contract: software exposes independent work and synchronization, while the
machine decides where to run it, how to move its data, and which order of
memory operations is visible.

== Multiprocessor Fundamentals

=== What Is Parallelism?

Parallelism means doing more than one useful thing at a time. The useful things
may be instructions from one thread, elements of one data set, or independent
tasks from several threads. The level of parallelism determines the hardware
and software interface:

#three-line-table(
  columns: (1.35fr, 2.15fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *Level* | *What is independent?* | *Typical mechanisms* |
  | :------ | :---------------------- | :------------------ |
  | Instruction-level parallelism (ILP) | Instructions in one sequential stream | Pipelining, out-of-order issue, speculation, VLIW, dataflow |
  | Data-level parallelism (DLP) | Elements receiving the same operation | SIMD, vector and array processors, systolic arrays |
  | Thread/task-level parallelism (TLP) | Threads or tasks with separate control state | Multithreading, multicore and multiprocessor execution |
]

Parallel execution can improve single-program latency, aggregate throughput,
energy efficiency, cost efficiency, scalability, or dependability through
redundant execution. These goals can conflict. For example, duplicating a
computation can detect a fault but does not improve useful throughput, and a
large core can reduce latency while consuming the area of several small cores.

=== Flynn's Taxonomy

Flynn classifies machines by the number of instruction streams and data streams
active in the execution model:

#three-line-table(
  columns: (1.05fr, 2.2fr, 2.55fr),
  inset: 5pt,
  align: left,
)[
  | *Class* | *Meaning* | *Examples and observations* |
  | :------ | :------- | :------------------------- |
  | SISD | Single instruction stream, single data stream | A scalar processor; pipelining and out-of-order execution do not change the programmer-visible single-stream model |
  | SIMD | Single instruction stream, multiple data elements | Vector or array processor; one instruction applies to many lanes |
  | MISD | Multiple instruction streams, one data stream | Rare as a pure form; systolic or streaming structures are the closest examples |
  | MIMD | Multiple instruction streams, multiple data streams | A multicore multiprocessor or a multithreaded processor |
]

Flynn's labels describe an execution organization, not a programming language.
A MIMD machine can run SIMD code, and a shared-memory program can run on
message-passing hardware through a runtime system. Conversely, a message
passing library can run on a shared address-space machine.

=== Tightly and Loosely Coupled Systems

A *tightly coupled* multiprocessor gives processors a global shared address
space. A load by one processor can observe a value written by another (subject
to the memory-ordering contract), and private caches need a coherence protocol.
Symmetric multiprocessors (SMPs), multicore CPUs, and many multithreaded chips
are tightly coupled examples. The programming model resembles a uniprocessor,
but accesses to shared data must be synchronized.

A *loosely coupled* multiprocessor, or multicomputer, gives each node private
memory and connects nodes with a network. Communication is normally explicit
`send` and `receive` (message passing). A node cannot load an arbitrary remote
address as if it were local memory; the program or runtime chooses when to
copy or stream data.

#three-line-table(
  columns: (1.45fr, 2.2fr, 2.2fr),
  inset: 5pt,
  align: left,
)[
  | *Property* | *Shared-memory model* | *Message-passing model* |
  | :--------- | :-------------------- | :--------------------- |
  | Communication | Implicit through loads and stores to common addresses | Explicit messages, queues, or remote procedure calls |
  | Coupling | Threads share an address space and synchronization objects | Components can have private address spaces and explicit ownership |
  | Programmer burden | Coherence, consistency, races, locks, and false sharing | Partitioning, buffering, routing, matching sends with receives |
  | Strength | Convenient for fine-grained sharing and familiar data structures | Scales naturally across nodes and makes communication visible |
  | Hardware implication | Usually global or distributed shared memory plus coherence | Network-connected memories; software can still emulate shared memory |
]

The programming model and the hardware model are separate layers:

`application -> compiler/library -> operating-system services -> hardware`

Software distributed shared memory can make a message-passing machine look
shared, while an MPI-like library can make a shared-memory machine look like a
cluster. The choice affects communication overhead, scalability, ease of
programming, and the kinds of bugs that are easy to create.

=== Design and Programming Issues

The principal hardware questions are synchronization (locks, atomics, and
barriers), cache coherence, memory consistency, shared-resource management, and
the interconnect. The principal software questions are how to partition work,
how to balance it, how to avoid contention, and how to establish happens-before
relationships. A program can be functionally correct yet scale poorly because
its critical path contains a lock, a barrier, a communication hop, a memory
queue, or a task-creation loop.

Hardware multithreading is another way to exploit parallelism. Coarse-grained
multithreading switches on a quantum or a long-latency event; fine-grained
multithreading selects a different thread every cycle; simultaneous
multithreading can dispatch instructions from several threads in one cycle.
These mechanisms improve utilization but share issue width, caches, queues, and
memory bandwidth, so they do not remove contention.

== Speedup and Its Caveats

=== Definitions

For a fixed problem and algorithm, let $T_1$ be execution time on one
processor and $T_P$ the time on $P$ processors. The speedup and parallel
efficiency are

$ S_P = T_1 / T_P $

$ E_P = S_P / P = T_1 / (P times T_P) $

Ideal speedup is $P$, but it is a bound rather than a promise. The comparison
must keep the problem, algorithm, input, correctness requirement, and useful
work fixed. A faster parallel algorithm can legitimately beat a slow serial
baseline while still having sublinear speedup relative to the best serial
algorithm.

=== Horner's Polynomial Example

Consider

$ R = a_4 x^4 + a_3 x^3 + a_2 x^2 + a_1 x + a_0 $

Assume that $x$ and all coefficients are available, every operation takes one
cycle, there is no communication cost, and a single processor executes no
operations concurrently. A direct data-flow graph uses three operations to
form $x^2$, $x^3$, and $x^4$, four coefficient multiplications, and four
additions: eleven operations, so $T_1 = 11$ cycles.

With three processors the independent products and powers can overlap. A
schedule with the longest dependence chain of five cycles gives $T_3 = 5$ and

$ S_3 = 11 / 5 = 2.2 $

The result is below the ideal factor of three because the additions that combine
the terms remain dependent. More importantly, eleven operations are not the
best serial algorithm. Horner's method rewrites the same polynomial as

`R = (((a4 * x + a3) * x + a2) * x + a1) * x + a0`

It performs four multiplications and four additions, only eight operations. Its
dependence chain is serial, so in this simplified model the best one-processor
time, written `T_1_best`, is 8 cycles and
the same three-processor schedule has a five-cycle span. The fair speedup is

$ S_3_"fair" = 8 / 5 = 1.6 $

The apparent $2.2 times$ speedup came from comparing a parallel direct
algorithm with a deliberately worse single-processor algorithm. Parallel
algorithm design and processor speedup must therefore be reported separately.

=== Superlinear Speedup

Measured speedup can exceed $P$, but this does not violate the work bound when
the experiment changes something besides processor count. Common explanations
are:

- *Unfair algorithm comparison*: the parallel implementation uses a better
  algorithm, as in the direct-versus-Horner example.
- *Cache and memory effects*: adding processors may add aggregate cache
  capacity, memory channels, or memory-level parallelism, reducing misses that
  the one-processor run suffered.
- *Search and pruning*: parallel search may find a result early or explore a
  different portion of a tree.
- *Measurement effects*: startup, I/O, thermal state, or an unrepresentative
  serial baseline can distort the ratio.

State exactly what is held constant before calling a result superlinear. A
parallel run that does less work is an algorithmic improvement, not evidence
that each processor delivered more than one processor's work.

=== Utilization, Redundancy, and Efficiency

The usual efficiency metric hides whether processors are doing useful work.
For $P$ processors and parallel execution time $T_P$:

$ U = "operations in parallel version" / (P times T_P) $

$ R = "operations in parallel version" / "operations in best single-processor algorithm" $

$ E = T_1_"best" / (P times T_P) = U / R $

*Utilization* is the fraction of available processing capacity occupied by
operations. *Redundancy* is extra work relative to the best one-processor
algorithm; it is greater than one when the parallel algorithm repeats work,
uses speculative tasks, or performs replicated fault checking. *Efficiency*
combines both effects. A machine can have high utilization and poor efficiency
if it keeps all processors busy doing redundant work, or low utilization and
good work efficiency if it executes little work but spends time waiting.

Always state whether "operations" includes synchronization, communication,
speculation, retries, and redundant copies. Otherwise two studies can report
different efficiencies for the same schedule.

=== Amdahl's Law and Real Overheads

Let $f$ be the fraction of the one-processor execution that is parallelizable
and let $N$ be the number of equal processors. The idealized Amdahl bound is

$ S_N = 1 / ((1 - f) + f / N) $

As $N$ tends to infinity, speedup approaches $1/(1-f)$. The serial fraction
therefore dominates large machines. Real parallel portions add terms that the
simple equation omits:

#three-line-table(
  columns: (1.35fr, 2.15fr, 2.2fr),
  inset: 5pt,
  align: left,
)[
  | *Overhead* | *Why it appears* | *Observable effect* |
  | :--------- | :---------------- | :----------------- |
  | Synchronization | Locks, atomics, barriers, condition variables | Threads wait and updates serialize |
  | Load imbalance | Tasks have different sizes or cores run at different rates | The last thread determines completion |
  | Communication | Producer/consumer or remote-cache data transfer | Useful work waits for messages or cache fills |
  | Resource contention | Shared caches, interconnect, MSHRs, DRAM banks, and queues | Latency rises as more processors are added |
  | Task management | Creation, scheduling, migration, and stealing | Fine-grained tasks spend a larger fraction of time in control |
]

These effects make speedup sublinear even when the source code has no obvious
serial loop. Conversely, optimizing a bottleneck can improve speedup without
increasing the nominal parallel fraction.

== Task Assignment and Scheduling

=== Static versus Dynamic Assignment

*Static scheduling* assigns work at compile time or when tasks are created.
The assignment does not react to runtime task lengths or processor state. It
has low control overhead and stable locality, and it works well when task costs
are known and uniform. Its failure mode is idle processors when tasks differ in
size, when a branch changes work, or when a processor encounters a cache miss
or fault.

*Dynamic scheduling* assigns a task when a processor becomes available. It uses
runtime information and balances irregular work, but task movement requires
queues, synchronization, metadata, and sometimes data migration. The scheduler
can also destroy locality by moving a task away from the cache that holds its
inputs.

#three-line-table(
  columns: (1.25fr, 2.05fr, 2.35fr),
  inset: 5pt,
  align: left,
)[
  | *Choice* | *Strength* | *Cost or failure mode* |
  | :------- | :-------- | :-------------------- |
  | Static, equal chunks | Minimal runtime overhead and predictable placement | Stragglers leave other processors idle |
  | Static, profiled chunks | Preserves locality while accounting for typical sizes | Sensitive to input and phase changes |
  | Dynamic central queue | Good load balance and simple global policy | One lock/atomic hot spot and queue contention |
  | Dynamic distributed queues | Local operations scale and preserve locality | Work can become uneven; stealing needs communication |
  | Hierarchical queues | Local balance first, global queue for overflow | More policy states and possible boundary hot spots |
]

For a histogram, one can statically give every processor an equal number of
input chunks and merge local histograms at the end. Dynamic assignment is better
when values or chunks have unpredictable cost: a processor takes the next chunk
after finishing the previous one. Static assignment is preferable when all
chunks cost about the same, the merge dominates, or the input's locality is
known to be important.

=== Queues and Work Stealing

A task queue stores ready tasks and their arguments. A centralized queue gives
one global order but serializes enqueue/dequeue operations. A distributed queue
gives each processor a local queue; the owner usually pushes and pops locally,
while an idle processor steals from another queue. A hierarchical design has
per-core queues, cluster queues, and a global overflow queue.

Work stealing proceeds as follows:

1. A processor executes from its local queue.
2. When the queue is empty, it chooses a victim, often at random or by a
   topology-aware policy.
3. It steals one task or a batch from the victim, using an atomic deque
   protocol, then resumes local execution.
4. If every queue is empty and no producer can create more work, the processor
   terminates or waits on a completion condition.

Stealing balances irregular recursive tasks and hides long tasks behind useful
work. It costs synchronization, interconnect traffic, and locality. Stealing a
large batch reduces control overhead but can starve the victim; stealing one
task improves fairness but increases communication. Randomized victims usually
avoid persistent hot spots, while termination detection is needed for dynamic
task generation such as exploring a maze.

=== Software and Hardware Scheduling

Software schedulers understand task semantics and can choose a domain-specific
partition, but a function call, lock, or queue operation can be expensive for a
very small task. Hardware task queues can maintain per-processor queues, move
tasks between queues, and expose a global queue with lower latency. They cost
area, energy, verification effort, and ISA/runtime integration. The right
boundary depends on task granularity: as task time approaches queue-operation
time, neither a sophisticated software scheduler nor a large number of steals
can recover the lost efficiency.

== Heterogeneity and Asymmetric Multicore

=== Why Asymmetry?

A symmetric chip uses one core design for every workload. Real programs and
phases differ in instruction-level parallelism, branch predictability, memory
intensity, serial fraction, synchronization behavior, and energy constraints.
An asymmetric or heterogeneous system offers several specialized instances and
schedules each phase on a best-fit resource.

Examples include scalar plus vector units, large out-of-order cores plus small
in-order cores, CPU plus GPU or FPGA, fast and slow memories, heterogeneous
cache policies, and separate control/data/synchronization networks. Asymmetry
bridges general-purpose flexibility and special-purpose efficiency, but adds
design/verification cost, scheduling complexity, migration overhead, and
different demands on shared resources.

=== Large and Small Cores

A large core typically has out-of-order issue, a wide front end, deep pipelines,
large branch predictors, multiple functional units, and memory-dependence
speculation. It delivers low latency for one hard-to-parallelize thread but
uses substantial area and power. A small core is often in-order, narrow, and
shallow; it has lower single-thread performance but much better throughput per
unit area or energy.

Consider an area budget equal to sixteen small cores. If one small core has
area/performance $(1,1)$ and one large core has $(4,2)$:

#three-line-table(
  columns: (1.45fr, 1.35fr, 1.4fr, 1.55fr),
  inset: 5pt,
  align: left,
)[
  | *Organization* | *Large cores* | *Small cores* | *Serial / parallel capability* |
  | :------------- | :------------ | :------------ | :---------------------------- |
  | Tile-large | 4 | 0 | Serial $2$, parallel throughput $4 times 2 = 8$ |
  | Tile-small | 0 | 16 | Serial $1$, parallel throughput $16$ |
  | ACMP | 1 | 12 | Serial $2$, parallel throughput $2 + 12 = 14$ |
]

The asymmetric chip multiprocessor (ACMP) keeps one large core for serial or
contended sections while using many small cores for throughput. The scheduler
may run the large core in the parallel phase too, provided doing so does not
make the rest of the machine lose more throughput than it gains.

=== Modified Amdahl's Law for an ACMP

Normalize a small core to one unit of performance. Let $f$ be the parallelizable
fraction, $L$ the number of large cores, $S$ the number of small cores, and $X$
the speedup of one large core over one small core. Assume the serial part runs
on a large core and the parallel part runs on all available cores. Then

$ S_"ACMP" = 1 / ((1 - f) / X + f / (S + X times L)) $

The first denominator term is the serial time on a core $X$ times faster than
the baseline. The second is the parallel work divided by aggregate throughput.
This model is intentionally optimistic: it ignores migration, contention,
load imbalance, and the fact that a large core may not scale linearly with a
small core. Those omitted terms must be measured for a real design.

=== Energy-Performance Introspection and EPI Throttling

Let EPI be energy per retired instruction and IPS be aggregate instructions per
second. A first-order power relation is

$ P = "EPI" times "IPS" $

Under a fixed power budget, a phase with little thread parallelism should run a
few cores at high voltage/frequency (high IPS per active core and high EPI),
while a highly parallel phase should run many efficient cores at lower voltage
and frequency. Dynamic voltage and frequency scaling (DVFS) changes voltage,
frequency, and the number of active cores at phase boundaries.

The intuition is not "always use the smallest core." A high-EPI large core can
finish a serial phase quickly enough to reduce total energy and expose the next
parallel phase. During a wide parallel phase, low-EPI small cores can deliver
more aggregate instructions under the same power. Phase detection, sampling,
core-switching time, thermal limits, and migration of cache state determine
whether the theoretical tradeoff is realized.

=== Scheduling Heterogeneous Resources

The scheduler needs a policy for choosing a core type, deciding when to migrate,
and sharing caches, interconnect links, MSHRs, and memory bandwidth. Possible
signals include observed IPC, branch and cache-miss rates, queueing delay,
critical-section waiting, deadline, and energy budget. A wrong phase prediction
can cost more than it saves; moving a thread also changes its cache locality and
may displace another thread. Heterogeneity is therefore a whole-system policy,
not only a collection of differently sized cores.

== Bottlenecks and Their Acceleration

=== Bottleneck Taxonomy

A bottleneck is any code or resource that limits progress of the application.
The limiting bottleneck can change during execution: for example, one phase
may contend for lock A while a later phase contends for lock B.

#three-line-table(
  columns: (1.4fr, 2.2fr, 2.2fr),
  inset: 5pt,
  align: left,
)[
  | *Bottleneck* | *Why threads wait* | *Useful acceleration target* |
  | :----------- | :----------------- | :-------------------------- |
  | Amdahl serial code | Only one thread can execute the region | A fast core or specialized unit |
  | Critical section / lock | Mutual exclusion queues contenders | Shorter lock holder execution and lock locality |
  | Barrier | All threads wait for the last arrival | Speed up lagging work or the barrier stage |
  | Pipeline stage | A slow stage backpressures its producer and successor | Accelerate the limiter stage or rebalance stages |
  | Load imbalance | Task lengths or core rates differ | Dynamic assignment, splitting, or stealing |
  | Communication / cache miss | Consumer waits for producer data or ownership | Data placement, prefetch, marshaling, or a faster link |
  | Shared resource contention | Cores compete for cache, DRAM, queues, or interconnect | Prioritization, partitioning, more bandwidth, or a dedicated resource |
  | Creation / scheduling | Work cannot start until tasks are made or queued | Coarser tasks, hardware queues, or parallel generation |
]

The critical path is the chain of work and waits that determines completion.
Accelerating code off the critical path may increase utilization but not reduce
end-to-end time. Thread waiting cycles (TWC) are a practical signal: code that
causes many other threads to wait is likely on the critical path, though waiting
can also reflect an external resource or an inaccurate annotation.

=== Accelerated Critical Sections (ACS)

In ordinary locking, every small core executes both the non-critical work and
the critical section:

1. `compute(private_input)` prepares thread-local arguments.
2. `lock(X)` acquires exclusive access.
3. `critical_update(shared_state, private_input)` produces `result`.
4. `unlock(X)` publishes the protected update.
5. `consume(result)` resumes private work.

As the number of threads grows, lock acquisition serializes more work and the
lock and shared data ping-pong between private caches. ACS ships the critical
section to a large core in an ACMP. A small core computes its private input,
places the arguments in a request area, and sends a `CSCALL` containing the
lock identifier, target program counter, stack pointer, and requesting core ID.
The large core executes the critical section while owning the lock, pushes the
result back, and sends `CSRET`/`CSDONE`; the small core resumes after the lock
operation.

#three-line-table(
  columns: (1.45fr, 2.2fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *ACS step* | *Action* | *Correctness or performance reason* |
  | :--------- | :----- | :---------------------------------- |
  | Call | Small core emits `CSCALL(lock, targetPC, context)` | Request is queued without taking the lock locally |
  | Queue | Critical Section Request Buffer (CSRB) orders requests, often by priority | One large-core context owns the lock at a time |
  | Execute | Large core acquires the lock, runs the target, and retains shared data in its cache | Faster single-thread execution and less lock/data ping-pong |
  | Return | Result/context is pushed back and `CSRET`/`CSDONE` wakes the requester | Preserves the original call and lock semantics |
]

ACS trades a dedicated large core and control-transfer latency against shorter
critical sections. It can reduce parallel throughput when the large core would
otherwise execute ordinary work, and private arguments may miss in the large
core's cache. The tradeoff becomes more favorable with more small cores because
parallel throughput loss is a smaller fraction while lock contention grows.

ACS can also create *false serialization*: independent critical sections that
use different locks may be sent through one queue and execute one after another.
Selective ACS (SEL) uses saturating counters or contention history to accelerate
only locks whose queueing justifies the transfer. Correct implementations keep
lock acquisition, release, atomicity, and the required memory-ordering edges
unchanged; ACS changes where the critical code executes, not what it means.

=== Bottleneck Identification and Scheduling (BIS)

ACS recognizes critical sections in advance. BIS generalizes the idea to locks,
barriers, pipeline stages, and other wait sites whose importance changes over
time. The compiler, library, or programmer annotates a bottleneck and rewrites
its wait loop with a small instruction interface:

- `BottleneckCall bid, targetPC` marks entry and identifies the code that can
  be accelerated.
- `BottleneckWait bid, watch_addr` attributes waiting at a lock, barrier, or
  queue to that bottleneck.
- `BottleneckReturn bid` marks completion and returns execution to the caller.

For a barrier, `targetPC` can be the barrier-handling code and `watch_addr` the
arrival counter. For a pipeline, one `BottleneckWait` watches the previous
stage's queue and another watches the next stage's space. The hardware measures
how many cycles other threads spend waiting at each `bid`.

The BIS control loop is:

1. Identify or annotate candidate bottleneck regions.
2. Count TWC while threads wait at each region.
3. Rank candidates by TWC and choose those above an acceleration threshold.
4. Migrate their context to a large ACMP core, or raise their priority/frequency
   in a shared resource.
5. Return the result and continue measuring, because the limiting bottleneck
   may have changed.

A representative implementation uses a global associative *Bottleneck Table*
(BT) for TWC, a *Scheduling Buffer* per large core, and an *Acceleration Index
Table* (AIT) at each small core mapping a bottleneck ID to its target large
core. Migration latency is often hidden by the wait that BIS is trying to
remove. If a bottleneck is not contended, migration overhead can instead make
the program slower. Multiple large cores can handle independent bottlenecks,
while preemptive acceleration and false-serialization detection improve
coverage.

BIS is a hardware/software cooperative mechanism: software supplies semantic
wait points, and hardware supplies low-overhead measurement and scheduling.
Coverage (critical-path waiting actually identified) and accuracy (identified
regions that are truly critical) are separate metrics; maximizing one can hurt
the other.

=== Utility-Based Acceleration (UBA)

BIS ranks by waiting, but a region with many wait cycles may be difficult to
speed up, while a moderately waiting region may run dramatically faster on a
large core. UBA also has to choose among applications sharing the same ACMP.
It ranks both bottlenecks and lagging threads with a utility that combines
criticality and local speedup.

Let segment $c$ take $t_c$ in the baseline application time $T$, and let an
accelerated execution save $Delta t_c = t_c - t'_c$. A useful normalized form is

$ U_c = Delta t_c / T = (Delta t_c / t_c) times (t_c / T) $

The first factor is the local speedup opportunity (fractional time reduction
of the segment); the second is its global criticality (fraction of application
time spent there). UBA estimates this utility for candidate bottlenecks and
lagging threads, selects the highest-utility set, and coordinates assignment to
the available large cores. This prevents a low-impact fast segment from
displacing a highly critical segment and lets multiple applications compete by
expected end-to-end benefit rather than raw waiting alone.

UBA's estimate can include queueing, migration, and private-data locality costs.
The utility is a decision aid, not a correctness rule: the scheduler still
must preserve synchronization semantics, avoid oversubscribing a large core,
and update estimates as phases change.

== Staged Execution and Data Movement

=== Staged Execution Model

Staged execution splits a program into segments and gives each segment a work
queue. Each instance runs on the core best suited to that segment, and adjacent
segments can overlap for different iterations:

#three-line-table(
  columns: (1.15fr, 3.5fr),
  inset: 5pt,
  align: left,
)[
  | *Segment* | *Operations* |
  | :-------- | :----------- |
  | S0 | `load X` -> compute -> `store Y` |
  | S1 | `load Y` -> compute -> `store Z` |
  | S2 | `load Z` -> compute -> emit result |
]

The model can accelerate a critical section, map a producer-consumer pipeline
stage to a dedicated core, execute Cilk/TBB-style tasks, or invoke a special
functional unit. It offers three benefits: specialization of a segment,
inter-segment parallelism, and improved within-segment locality. Its cost is
communication and synchronization between segment queues.

=== Inter-Segment Cache Misses

When S0 writes a block in its private cache and S1 consumes it on another core,
S1 may pay a cache miss and coherence transfer. Every pipeline handoff can then
turn useful overlap into a sequence of communication stalls. The same problem
appears when ACS moves a critical section to a large core: private arguments
that were hot on the small core are cold on the large core.

The key observation behind *data marshaling* is that the addresses of blocks
handed from one segment to the next are often generated by a stable set of
instructions, even when the addresses themselves vary by input.

=== Data Marshaling Protocol

A *generator instruction* is the last instruction in one segment that writes a
cache block later consumed by the next segment. A compiler or profiler marks
these instructions and inserts a `MARSHAL` operation with the destination
segment/core. Hardware records the physical block addresses produced by the
generator in a small marshal buffer and pushes those blocks to the next core
before that segment begins.

#three-line-table(
  columns: (1.45fr, 2.1fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *Phase* | *Compiler/profiler* | *Hardware/runtime* |
  | :----- | :------------------- | :----------------- |
  | Discover | Find stores whose blocks are consumed by a later segment | No address-pattern learner is required |
  | Annotate | Add a generator prefix and `MARSHAL destination` | Bind the next segment ID to a physical core |
  | Produce | Execute the marked store | Record each resulting physical block in the marshal buffer |
  | Transfer | Segment reaches its handoff point | Push or forward recorded blocks into the consumer's cache |
  | Consume | Consumer executes its ordinary load | The inter-segment access is a cache hit or has reduced latency |
]

Marshaling can handle arbitrary address sequences because it records generator
outputs rather than predicting a stride. It is timely when the push is issued
before the consumer starts, and its hardware can be small (the representative
design uses roughly sixteen address entries per core). The
tradeoffs are profiler/ISA/runtime support, conservative generator sets,
unneeded transfers and remote-cache pollution, interconnect bandwidth, and the
need to invalidate or update a marshaled block consistently. Data marshaling
complements ACS, BIS, and pipeline scheduling; it does not replace coherence.

== Memory Ordering and Cache Coherence

=== Two Different Contracts

*Memory consistency* (memory ordering) specifies the order in which loads and
stores to all addresses may become visible across processors. It answers
questions such as whether a load of `flag` may be observed before a preceding
store of `data`.

*Cache coherence* specifies the behavior of multiple copies of one cache block.
It requires write propagation (an update eventually reaches readers) and write
serialization (all processors agree on one order of writes to that location).
Coherence does not, by itself, order accesses to different locations.

An implementation can be coherent but weakly consistent, or strongly ordered
but incoherent; a usable shared-memory ISA needs both contracts plus atomic
synchronization operations.

=== Sequential Consistency

Lamport's formal definition is:

> A multiprocessor is sequentially consistent if the result of any execution is
> the same as if the operations of all processors were executed in some single
> sequential order, and the operations of each individual processor appear in
> that sequence in the order specified by its program.

Equivalently, there exists one global total order of all memory operations that
respects each thread's program order. Different executions may choose different
valid interleavings, but all processors in one execution observe the same
interleaving. This is a clear programming abstraction, at the cost of limiting
out-of-order loads, store buffering, cache hit behavior, and scalable
implementation freedom.

=== Lock Interleaving Counterexample

Suppose two flags initially contain zero and each processor tries to enter a
critical section by publishing its intent and then reading the other's flag:

#three-line-table(
  columns: (1fr, 1fr),
  inset: 5pt,
  align: left,
)[
  | *P1* | *P2* |
  | :--- | :--- |
  | `F1 = 1` (A) | `F2 = 1` (X) |
  | `r1 = F2` (B) | `r2 = F1` (Y) |
  | If `r1 == 0`, enter CS | If `r2 == 0`, enter CS |
]

Under sequential consistency, no interleaving that preserves `A before B` and
`X before Y` can produce `r1 = 0` and `r2 = 0`: one of the stores must appear
first in the global order, and the later load sees it. A weak implementation
with store buffers can let P1 perform B before A is visible to P2 while P2
performs Y before X is visible to P1. P1's local view appears to be `A, B, X`,
while P2's appears to be `X, Y, A`; there is no one global order consistent
with both views. Both processors can therefore enter the critical section.

The example is not a valid lock implementation. An atomic read-modify-write
(such as compare-and-swap or test-and-set) must choose one owner, and release
and acquire ordering must make the protected data visible. It is useful because
it separates *per-thread program order* from *global visibility order*.

=== Weak and Release Consistency

The strict total order of SC is stronger than needed for properly synchronized
programs. Relaxed models allow ordinary data accesses to overlap and use fences
or synchronization operations at communication boundaries.

#three-line-table(
  columns: (1.3fr, 2.25fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *Model* | *Guarantee* | *Programming consequence* |
  | :------ | :--------- | :----------------------- |
  | Sequential consistency | One global order, preserving each thread's order | Easiest reasoning; most implementation constraints |
  | Weak consistency | Ordinary accesses between fences may reorder; synchronization/fences delimit regions | Programmer identifies boundaries where ordering matters |
  | Release consistency | Acquire orders later operations after lock acquisition; release orders earlier operations before unlock/publication | Data protected by a lock becomes visible through acquire/release edges |
  | Total-store-order style | Stores have a stronger global order than loads; some load/store pairs may still reorder | Middle ground with less hardware cost than SC |
]

A full fence has the conceptual semantics:

- Memory operations before the fence are ordered before the affected operations
  after it and become visible as required by the ISA's fence scope.
- Operations after the fence cannot pass it.
- Fences from one processor appear in program order.

An acquire operation prevents later loads/stores from moving before the
acquire. A release prevents earlier loads/stores from moving after the release
and publishes prior writes. A lock acquire is normally acquire-like and an
unlock is release-like; a language or ISA may provide stronger semantics for
sequentially consistent atomics. Fences do not repair a data race or make a
non-atomic read-modify-write indivisible. They only constrain ordering around
operations that are already synchronized correctly.

Weak models improve overlap and scalability, but shift burden to compilers,
libraries, and programmers. Incorrect labels or missing fences can produce
outcomes that are legal for the hardware and surprising to a programmer. A
data-race-free program using the language's synchronization primitives is often
given an SC-like guarantee, but that guarantee depends on the language and ISA
contract rather than on coherence alone.

== Invalidate-Based Snooping Protocols

The earlier Memory System chapter introduces a simple `Valid/Invalid` (VI)
snooping protocol for a write-through, no-write-allocate cache. That protocol
captures the basic rule: a write broadcasts `BusWr` and other caches invalidate
their copies. The protocols below extend the same bus events to write-back
caches and more informative permissions.

Use this notation:

- `PrRd` and `PrWr` are local processor read and write requests.
- `BusRd` requests a shared/read copy.
- `BusRdX` (also called `ReadEx`) requests data and exclusive write permission.
- `BusUpgr` requests invalidation of other sharers when data is already local.
- `Flush`/`Data` supplies dirty data from an owner or cache to the requester.

Real implementations add transient states while a request, data response, or
invalidation acknowledgment is outstanding. The stable-state tables below omit
those bookkeeping states but state the required permissions.

=== MSI

#three-line-table(
  columns: (1.05fr, 2fr, 2fr, 1.55fr),
  inset: 5pt,
  align: left,
)[
  | *State* | *Meaning* | *Local requests* | *Snooped request* |
  | :------ | :------- | :--------------- | :---------------- |
  | M (Modified) | Only cached copy; dirty relative to memory | `PrRd`/`PrWr` hit and stay M | `BusRd`: supply data and downgrade (usually S); `BusRdX`: supply data and go I |
  | S (Shared) | Clean copy; other caches may also hold it | `PrRd` hit; `PrWr` emits `BusUpgr`/`BusRdX` and goes M | `BusRd`: stay S; `BusRdX`: invalidate, go I |
  | I (Invalid) | No usable copy | `PrRd` emits `BusRd` and fills S; `PrWr` emits `BusRdX` and fills M | Ignore ordinary reads; remain I |
]

MSI's read miss goes directly to `S`, even when no other cache has the block.
Consequently a later first write must broadcast an upgrade unnecessarily. A
write miss obtains ownership through `BusRdX`; repeated writes in M are silent
until another processor requests the block or it is evicted.

=== MESI

MESI adds *E (Exclusive)*, a clean copy known to be the only cached copy:

#three-line-table(
  columns: (1.05fr, 2fr, 2fr, 1.55fr),
  inset: 5pt,
  align: left,
)[
  | *State* | *Meaning* | *Local requests* | *Snooped request* |
  | :------ | :------- | :--------------- | :---------------- |
  | M | Sole dirty owner | Reads/writes hit silently | `BusRd` supplies data and loses sole dirty permission; `BusRdX` supplies then I |
  | E | Sole clean owner | `PrRd` hit; `PrWr` silently upgrades E -> M | `BusRd` downgrades E -> S; `BusRdX` invalidates E -> I |
  | S | Clean copy with possible sharers | Read hit; write emits `BusUpgr`/`BusRdX`, then M | `BusRd` stays S; `BusRdX` -> I |
  | I | No copy | `BusRd` -> E if no sharer responds, otherwise S; `BusRdX` -> M | Remains I |
]

During a `BusRd`, a wired-OR shared response or directory information tells the
requester whether another cache has a copy. No sharer permits E; any sharer
permits S. E removes the unnecessary invalidation for the common private-data
case. A transition from E or M to S/O is a *downgrade*; S to M is an *upgrade*.

=== MOESI

MESI's S state is clean, so an M cache that services another cache's `BusRd`
must first write the newest data to memory before both caches can be S. MOESI
adds *O (Owned)*:

- O is the one dirty owner; one or more other caches may hold clean-looking S
  copies, but memory is stale.
- M snooped `BusRd` can supply data and become O without writing memory.
- O services another read from the owner or a cache-to-cache transfer and stays
  O; the requester becomes S.
- O receiving a local write upgrades to M after invalidating other sharers.
- O receiving `BusRdX` supplies the data and becomes I; the requester becomes M.
- The O cache writes the block back when the last dirty ownership is evicted.

The extra state can save writebacks and memory traffic for producer/consumer
sharing. It also adds transient races, owner tracking, and verification cases.
Protocol optimizations are worthwhile only when their traffic savings exceed
their state and correctness cost.

=== Invalidate, Update, and Cache-to-Cache Choices

Invalidate protocols let an owner perform repeated writes silently, which is
usually efficient for private or write-intensive data. Update protocols push
new data to all sharers and can help a producer with many immediate readers,
but waste bandwidth when sharers do not reread. On a read miss, data can come
from memory or directly from a dirty/owner cache; cache-to-cache transfer saves
memory latency but adds arbitration and ordering cases.

== Directory-Based Coherence

=== Why a Directory?

A snooping bus gives every cache every transaction and a single serialization
point. It is simple and has short miss latency for a small machine, but a
broadcast bus or totally ordered virtual bus does not scale to many nodes.
A directory keeps a logically central record for each block and sends targeted
messages. The home directory may be physically distributed by address across
memory controllers or LLC slices.

#three-line-table(
  columns: (1.25fr, 2.1fr, 2.3fr),
  inset: 5pt,
  align: left,
)[
  | *Method* | *Basic action* | *Scaling tradeoff* |
  | :------- | :------------ | :---------------- |
  | Snooping | Broadcast `BusRd`, `BusRdX`, or upgrade; every cache reacts | Short critical path and simple ordering; broadcast traffic and one bus bottleneck |
  | Directory | Requester contacts home; home tracks sharers/owner and sends targeted invalidations | Scales with network and storage; adds indirection, metadata, acknowledgments, and hot-block serialization |
]

=== Directory Data and Actions

A full-map directory has one sharer bit per processor and an owner or exclusive
indicator. A compressed directory may use a limited pointer list, coarse vector,
region sharing, or a Bloom filter. False positives (invalidating a cache that
does not actually hold the line) are safe but hurt performance; false negatives
are not safe.

#three-line-table(
  columns: (1.35fr, 2.25fr, 2.2fr),
  inset: 5pt,
  align: left,
)[
  | *Request* | *Home-directory action* | *Resulting permissions* |
  | :-------- | :---------------------- | :--------------------- |
  | Read miss (`Read`) | If clean, fetch memory; if dirty, ask owner for data; add requester to sharers | Requester gets S; existing sharers remain S |
  | Read-exclusive miss (`ReadEx`/`RdEx`) | Invalidate all other sharers, or ask the dirty owner to supply and revoke; wait for acknowledgments | Requester gets M/E, all other copies I |
  | Upgrade (`Upgrade`) | Invalidate other sharers without refetching data; wait for acknowledgments | Existing requester changes S -> M |
  | Dirty eviction | Owner writes data to home or transfers ownership | Directory records clean memory or a new owner |
]

For a read, a typical message sequence is `requester -> home -> owner/memory ->
requester`, followed by a sharer-set update. For a write, it is
`requester -> home -> invalidations -> acknowledgments -> data/permission`. The
home is the serialization point for one block, so all writes to that block have
one order even when different blocks use different homes.

=== Worked Directory-Sizing Example

Suppose a 32 GiB physical address space is divided into 128-byte blocks and
spread over 32 directory nodes. The number of blocks homed at one node is

$ (2^35 / 2^7) / 2^5 = 2^23 " blocks" $

Assume a budget of about 200 MB for directory metadata at that node. The budget
is about 25 bytes per block, or

$ 25 times 2^23 " bytes" = 25 times 2^26 " bits" $

Dividing by $2^23$ blocks gives 200 bits per block. If a full-map entry stores
$P$ sharer bits plus one exclusive/owner bit, then

$ P + 1 = 200, quad P = 199 $

Thus a roughly 200 MB per-node budget can represent only about 199 processors
with a full vector at this block size. Increasing processor count, address
space, or directory granularity requires compression, sparse pointers, sharing
predictions, or more metadata capacity.

=== Races and Transient States

Directory protocols are not just tables; they are distributed state machines.
Important races include two processors issuing `RdEx` simultaneously, a new
read arriving while invalidations are pending, a dirty owner evicting while the
home forwards its data, and a requester retrying after a negative acknowledgment.

The home can handle a busy entry by queueing requests or returning `NACK` so
the requester retries. It must remember which acknowledgments and data
responses are outstanding, suppress duplicate grants, and choose a fair order
for queued writers. A protocol must also avoid deadlock cycles between request,
response, invalidation, and writeback virtual channels. Real designs add
transient states, retry queues, ordered networks, and sometimes direct cache-to-
cache forwarding.

=== Scalability Limits and Remedies

Directory metadata grows with the number of processors, and a heavily shared
or frequently written line can make its home a hot spot. Distributed homes
remove one global bottleneck but do not remove per-line serialization. Common
remedies include:

- sparse or limited-pointer directories and Bloom-filter sharer summaries;
- hierarchical directories that track clusters before sending global messages;
- replicated or migrated homes for read-mostly data;
- combining invalidations and acknowledgments;
- topology-aware placement and virtual channels;
- token or hybrid protocols that combine broadcast-like ordering with targeted
  traffic.

Every remedy trades storage, latency, traffic, false positives, or proof
complexity. A directory that is "scalable" in capacity can still fail under a
single hot lock or false-sharing line.

== CPU and Processing-in-Memory Coherence

=== Why PIM Changes the Contract

Processing-in-memory (PIM), also called near-data processing (NDP), places a
compute engine near or inside a memory stack. It can exploit internal bandwidth
and avoid moving a large data set through the CPU/interconnect. A CPU and PIM
engine may nevertheless access the same physical cache lines concurrently, so
the system needs a contract for visibility, synchronization, and conflicts.

Three simple policies illustrate the tradeoff:

#three-line-table(
  columns: (1.35fr, 2.15fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *Policy* | *Mechanism* | *Failure mode* |
  | :------- | :------------ | :------------ |
  | Non-cacheable PIM region | CPU bypasses caches for PIM data | Many off-chip accesses and poor CPU performance |
  | Coarse-grained ownership | Flush/lock an entire PIM region before a kernel | Unneeded dirty-data movement and CPU stalls |
  | Fine-grained conventional coherence | Coherent request for every cache line | Correct but can erase PIM's movement and energy benefit |
]

The useful contract is to retain the ordinary shared-memory programming model
where possible while avoiding coherence traffic for lines that cannot conflict.

=== LazyPIM: Defer Coherence to a Kernel Boundary

LazyPIM treats a PIM kernel as an optimistic coherence epoch. At kernel launch,
the CPU and PIM agree on the data region and synchronization boundary. During
the epoch:

- the PIM engine executes near memory without issuing a conventional coherence
  transaction for every access;
- the PIM side records a compact read set and write set (for example, line
  signatures); and
- CPU-side writes to the PIM region are tracked so they can be compared with the
  PIM read set.

At the kernel's commit/synchronization point, the coherence manager compares
the sets. A CPU write that overlaps a PIM read is a true violation because the
PIM may have read an old value. The implementation invalidates or flushes the
affected data and re-executes/aborts the PIM epoch. If there is no such conflict,
PIM writes can be committed and the signatures discarded. PIM write versus CPU
read, and PIM write versus CPU write, can often be ordered at commit without a
read-after-write violation; the exact allowed overlap is part of the ISA/runtime
contract.

LazyPIM is therefore *lazy* about coherence, not careless about correctness:
the boundary, set tracking, conflict action, and visibility of committed writes
are explicit. The benefit is that a mostly non-colliding kernel pays one
resolution cost instead of a coherence message for every line.

=== CoNDA: Optimistic Near-Data Accelerator Execution

CoNDA extends the same idea to near-data accelerators (NDAs) that are not
necessarily integrated into the DRAM array. An NDA kernel optimistically
executes while CPU hardware records writes to the NDA data region. The NDA
records `NDAReadSet` and `NDAWriteSet`; signatures such as Bloom filters make
large sets fit in fixed hardware state, with false positives causing extra work
but not incorrect execution.

The contract has four phases:

1. *Offload*: the CPU identifies an NDA kernel and the region/synchronization
   boundary.
2. *Optimistic execution*: the NDA assumes it has permissions and performs
   reads/writes without per-access off-chip coherence checks; CPU writes are
   logged in `CPUWriteSet` (often with per-word dirty bits).
3. *Resolution*: compare `CPUWriteSet` with `NDAReadSet` and `NDAWriteSet`.
   A CPU write intersecting `NDAReadSet` is a read violation. If no violating
   conflict exists, commit NDA updates. If one exists, flush or invalidate the
   affected lines, discard uncommitted NDA state, erase signatures, and restart
   the kernel.
4. *Commit and synchronization*: publish NDA writes in the ordinary coherence
   order and release the boundary so CPU threads observe a valid result.

The key necessary-coherence rule is that both agents must access a line and at
least one must update it, but the direction matters. NDA-read/CPU-write can
make the NDA read stale data; NDA-write/CPU-read or NDA-write/CPU-write can be
made correct by ordering the commit and subsequent CPU access. CoNDA exploits
this asymmetry and the observed low collision rate between CPU and NDA accesses.
For Connected Components, only about 5.1% of CPU accesses collided with NDA
accesses in the reported study, which explains why resolving only necessary
coherence was effective.

Compared with non-cacheable, coarse-grained, and fully fine-grained schemes,
CoNDA trades signature storage and occasional re-execution for much less
off-chip coherence traffic. The signature may have false positives, so a
conservative implementation can recheck or re-execute unnecessarily; it must
never produce a false negative. The CPU/NDA contract must also define atomics,
locks, fences, virtual-memory permissions, interrupts, and what happens if a
kernel is preempted. Optimistic coherence is a system design, not only a cache
metadata optimization. Across the evaluated workloads, CoNDA came within about
10.4% of the performance and 4.4% of the memory-system energy of an ideal NDA
coherence mechanism; these gaps include signature false positives, resolution,
and occasional recovery.

=== PIM Summary

LazyPIM and CoNDA show that moving computation near memory is safe only when
access insight, explicit synchronization boundaries, and commit/retry preserve
the result of a conventional coherent execution.

