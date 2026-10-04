#import "../../index.typ": *
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: series-chapter.with(
  arch-notes-series,
  route: "docs/arch-notes/01-architectural-simulation/",
  title: "Architectural Simulation",
)

== Why Architecture Needs Evaluation

An architectural idea is rarely good or bad in isolation. Its effect depends on the workload, the rest of the system, and the values chosen for many parameters. A cache policy, for example, can help one access pattern and hurt another; a memory scheduler can improve throughput while increasing tail latency. Workloads and system parameters also change over time, so an intuition validated for one configuration is not a proof for the next one.

Simulation is the architect's way to reason about a system that does not yet exist. It can expose bottlenecks, compare alternatives, and provide a reality check before hardware is built. The same freedom also makes simulation dangerous: an incorrect model can produce a precise-looking answer for a false system. The goal is therefore not merely to run a simulator, but to choose an appropriate model and establish evidence that its conclusions are trustworthy.

== Evaluation Methods

#three-line-table(
  columns: (1.35fr, 1.15fr, 2.2fr, 2.35fr),
  inset: 5pt,
  align: left,
)[
  | *Method* | *Typical speed/cost* | *What it can establish* | *Main limitation* |
  | :------- | :------------------- | :---------------------- | :---------------- |
  | Theoretical proof | Very fast; low implementation cost | A property that follows from explicit assumptions | Usually abstracts away workload and implementation details |
  | Analytical model | Very fast; low to moderate effort | Trends, bounds, sensitivity to a few parameters | Simplifying assumptions may hide interactions and phase behavior |
  | High-level simulation | Fast; flexible | Relative effects over many workloads and configurations | Accuracy depends on which details were omitted |
  | Detailed or RTL simulation | Slow; high development cost | Cycle-level behavior of a specified implementation | Too slow for broad design-space exploration |
  | FPGA/prototype | Much faster than RTL for many tests; hardware effort | Behavior of an executable prototype under realistic traffic | Limited observability, capacity, and iteration speed |
  | Real implementation | Final evidence for the shipped system | Actual performance, energy, correctness, and usability | Expensive and too late for fundamental design changes |
]

These methods are complementary. A proof can rule out an impossible design, an analytical model can identify dominant parameters, and a high-level simulation can test many workload-dependent interactions. Detailed simulation, prototyping, and measurement then increase confidence in the small set of designs worth implementing.

== Goals of Simulation

The desired output determines what the simulator must model. Common goals include:

- *Design-space exploration*: quickly compare many algorithms, capacities, organizations, and policies. Relative trends matter more than an exact prediction of one implementation.
- *Bottleneck and profiling analysis*: attribute time, traffic, energy, or queue occupancy to components and events.
- *Component evaluation*: study a cache, memory controller, SSD, interconnect, or accelerator while replacing the rest of the system with a controlled model.
- *Full-system performance estimation*: capture interactions among the core, OS, virtual memory, devices, storage, and other programs.
- *Behavior matching and debugging*: reproduce an existing machine closely enough to diagnose a bug or evaluate a small cycle-level tweak.

#three-line-table(
  columns: (1.7fr, 1.55fr, 1.75fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Question* | *Useful scope* | *Accuracy emphasis* | *Typical output* |
  | :--------- | :------------- | :----------------- | :--------------- |
  | Is this idea worth pursuing? | Abstract component or system model | Correct direction and ranking | Speedup trend, sensitivity, bottleneck |
  | Which component limits throughput? | Target component plus a controlled producer/consumer | Correct resource accounting | Queue delay, utilization, traffic breakdown |
  | How does software interact with hardware? | Full system or an OS-aware hybrid | Correct software and hardware interaction | Runtime, system throughput, VM overhead |
  | Will this implementation behave correctly? | Detailed timing/functional model | High functional and timing fidelity | Cycle trace, state transitions, error reproduction |
  | Is the final product fast enough? | Prototype or real system | Measured behavior and tail distribution | Throughput, latency, energy, reliability |
]

The same simulator can support several goals only when its model boundaries and accuracy limits are explicit. Reusing a fast component simulator as though it were a full-system predictor is a common source of overconfident conclusions.

== Why High-Level Simulation?

RTL simulation is often intractable for architectural exploration. A single design may need to be tested over a large portion of many workloads, while varying cache size and associativity, memory scheduling, pipeline style, reservation-station capacity, queue sizes, and many other parameters. The product of configurations and workloads quickly dominates the cost of a detailed run.

High-level simulation raises the abstraction level and models only factors that are expected to affect the question. It can omit corner cases and implementation details while preserving the *relative trend* between candidate designs. This makes simulator development and design decisions faster.

The tradeoff is not "fast versus correct." A high-level model can be useful if it ranks designs correctly, but it can also omit an interaction that reverses the ranking. Every high-level conclusion should therefore identify its assumptions and be checked by a more detailed model, a prototype, an analytical bound, or a real-system experiment when the decision matters.

== Speed, Flexibility, and Accuracy

Three dimensions describe a simulator:

#three-line-table(
  columns: (1.35fr, 1.65fr, 2.45fr, 1.75fr),
  inset: 5pt,
  align: left,
)[
  | *Dimension* | *Meaning* | *Useful measurements* | *What improves it* |
  | :---------- | :------- | :------------------- | :---------------- |
  | Speed | How quickly simulated work advances | xIPS (instructions/s), xCPS (cycles/s), wall-clock time, slowdown versus native execution | Higher abstraction, compiled/vectorized code, event skipping, parallel runs |
  | Flexibility | How quickly algorithms, structures, and parameters can be changed | Lines/modules changed, rebuild time, time to add a policy, configuration effort | Modular interfaces, declarative parameters, reusable components |
  | Accuracy | How closely functional, timing, energy, or ordering results match the target | Simulation error, correlation, rank preservation, confidence interval | More detailed state/timing, calibration, validation against measurements |
]

Speed and flexibility determine how many design decisions can be explored. Accuracy determines whether those decisions are likely to transfer to the target system and how much simulator-development effort is justified. Increasing detail often reduces speed and flexibility; increasing speed by dropping detail can increase modeling error. The best point depends on the design stage and the question, not on a universal simulator ranking.

For a measured quantity $y$, a simple relative error is

$ "relative error" = abs(y_"sim" - y_"real") / y_"real" $

Absolute accuracy is not always required for early exploration. A model that predicts a consistent ordering of alternatives can be valuable even when every absolute latency is biased. That claim must be tested rather than assumed.

== Simulation as Progressive Refinement

Architectural evaluation is usually a loop rather than a one-way march toward RTL:

#three-line-table(
  columns: (1.35fr, 1.55fr, 1.65fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Level* | *Typical model* | *Strength* | *Risk or cost* |
  | :------ | :-------------- | :-------- | :------------ |
  | High | Abstract equations or a compact C/C++/Python model | Very fast and easy to modify; broad search | May miss queueing, timing, and feedback interactions |
  | Medium | Detailed component or transaction-level model | Adds important contention and policy behavior | More state and longer runs; boundaries still approximate |
  | Low | Cycle-accurate microarchitecture model | Captures pipeline, queues, and resource timing | Slow; difficult to configure and validate |
  | RTL | All relevant signals and implementation timing | Close to an implementation and useful for correctness | Very slow and expensive to develop |
  | Prototype/real | FPGA or fabricated system | Direct evidence under real software and devices | Limited flexibility; expensive to change |
]

Moving downward normally reduces abstraction and flexibility while increasing cost and, hopefully, accuracy. "Hopefully" matters: adding detail does not automatically make a model correct. An inaccurate detailed model can be less useful than a validated abstract one. Results should flow back upward: use detailed or measured evidence to calibrate the high-level model, revise assumptions, and repeat the design-space search.

== Scope: What, How, Where, and When

Before writing or selecting a simulator, state four boundaries explicitly:

#three-line-table(
  columns: (1.1fr, 2.2fr, 2.65fr),
  inset: 5pt,
  align: left,
)[
  | *Choice* | *Alternatives* | *Consequence* |
  | :------ | :------------ | :----------- |
  | What | One component, several components, or the full system; program, input set, or captured trace | Determines which interactions can exist in the model and which effects are treated as external |
  | How | Functional, timing, transaction-level, event-driven, or cycle-by-cycle | Determines what state is maintained and how much timing detail is observable |
  | Where | Software simulation, emulation, FPGA, or another hardware accelerator | Determines speed, observability, and how easily the model can change |
  | When | Use information available only to an oracle, or make decisions as a real machine would | Determines whether the experiment is predictive or merely an upper-bound/diagnostic study |
]

=== Component versus Full-System Simulation

A component simulator is appropriate when the component is the research question and the surrounding traffic can be represented by a controlled driver or a trace. It is fast and makes causes easy to isolate, but it cannot discover effects that depend on omitted software, translation, coherence, interrupts, or feedback from another component.

A full-system simulator executes or models the OS, applications, memory allocator, virtual-memory subsystem, devices, and interconnect together. It can capture these interactions, but it requires substantially more state, takes longer to run, and is harder to develop and validate. The OS and memory allocator should be modeled when they influence the metric; otherwise their cost may be replaced by a justified abstraction.

=== Simulator Inputs and Outputs

#three-line-table(
  columns: (1.45fr, 2.35fr, 2.45fr),
  inset: 5pt,
  align: left,
)[
  | *Interface* | *Examples* | *Questions to document* |
  | :---------- | :-------- | :---------------------- |
  | Inputs | Program binaries, traces, configuration, system state, checkpoints, device/storage/network state | Which inputs are fixed, generated, or sampled? What state is restored? |
  | Functional outputs | Program results, exceptions, architectural events, instruction and address statistics | Does the result match a reference execution? |
  | Timing outputs | Per-program time, system throughput, queue delays, resource utilization, event counts | Which clock, contention, and completion definition produced the number? |
  | Energy/reliability outputs | Activity, bytes moved, power, errors, wear, thermal events | Which technology model and calibration support the estimate? |
]

== Functional and Timing Simulation

*Functional simulation* answers what the program or system does: instruction semantics, control flow, memory values, system-call effects, and final results. It need not model the exact cycle in which an operation completes.

*Timing simulation* answers when events occur: pipeline availability, queue occupancy, arbitration, bank conflicts, cache misses, overlap, and completion time. It can use a functional source for addresses and values, or it can execute enough semantics itself to determine them.

#three-line-table(
  columns: (1.45fr, 2.25fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *Organization* | *Mechanism* | *Advantages and limitations* |
  | :------------- | :-------- | :-------------------------- |
  | Functional-first | A functional engine advances the program and sends instructions/requests to a timing model | Fast and modular; timing-dependent behavior can be hard to reproduce if the functional engine runs too far ahead |
  | Timing-first | The timing model controls advancement and invokes functional work when an instruction is ready | Natural timing causality; detailed functional work can reduce speed |
  | Integrated/hybrid | Functional and timing state advance together, with selective shortcuts or detailed regions | Can balance speed and fidelity; synchronization and state ownership must be designed carefully |
]

Functional accuracy and timing accuracy are independent. A simulator can produce the right final value at the wrong time, or the right timing for an instruction stream that is functionally wrong. Validate both when both matter.

=== Execute-at-the-Frontend versus Execute-at-Execute

In an *execute-at-frontend* organization, a functional frontend determines the instruction stream, addresses, and values; the timing model consumes those events. This is efficient, but it assumes that timing does not change what the program will execute. Timing-dependent mechanisms such as value prediction, data-dependent control, OS scheduling, and contention-triggered behavior become difficult to model faithfully.

In an *execute-at-execute* organization, the timing model itself performs or requests the functional execution when an instruction reaches its modeled execution point. This preserves a tighter causal relationship between timing and future instructions, but it requires more architectural state and is usually slower. Hybrid designs execute ordinary regions in the frontend and synchronize at timing-sensitive boundaries.

=== Oracle Information versus Real-Machine Information

An oracle can reveal a future branch outcome, exact reuse distance, a perfect physical address mapping, or the next request before a real implementation could know it. Oracle experiments are useful for upper bounds and mechanism diagnosis, but they are not predictive evaluations. A predictive simulator must make decisions from information available at the modeled time, with the same visibility and latency as the target design.

== Workload Construction and Sampling

Running an entire application from cold start is often unnecessary or too expensive. A workload can contain initialization, libraries, idle periods, short phases, and a long region whose behavior is representative of the question. Sampling reduces cost, but only if the selected intervals and their weights represent the population being reported.

#three-line-table(
  columns: (1.5fr, 2.1fr, 2.35fr),
  inset: 5pt,
  align: left,
)[
  | *Method* | *Procedure* | *Main caution* |
  | :------- | :--------- | :------------ |
  | Complete run | Simulate the full program and report the chosen region or total | High cost; startup and one-time phases can dominate |
  | Representative sampling | Profile execution, select intervals by phase or frequency, simulate each interval, and apply weights | A small or biased sample can reverse conclusions |
  | Trace sampling | Capture dynamic instructions/requests, select trace windows, and replay them | Feedback from timing to execution may be missing |
  | Checkpoint and restore | Save a state at a selected point, restore it for each configuration, and measure a region of interest | Checkpoint must include every state that affects the metric |
]

=== Regions of Interest and Weights

Define a *region of interest* (ROI) before collecting results. A useful workflow is:

1. Run or profile the workload cheaply to identify phases and representative intervals.
2. Record each interval's length and frequency or sampling weight.
3. Warm the modeled structures as required, then measure only the ROI.
4. Aggregate interval measurements using their weights and report both the weighted mean and variation.

Sampling by instruction count alone can overrepresent short phases or underrepresent phases with high memory cost. Sampling should consider the metric: memory-system research may need intervals selected by misses, addresses, row-buffer behavior, or queue occupancy rather than only by instruction count.

=== Checkpoints

A checkpoint is a saved system state from which multiple configurations can start. Depending on the scope, it may contain architectural registers and memory, page tables and OS state, device and storage state, and microarchitectural structures such as caches, predictors, queues, and outstanding requests.

Restoring an architectural-only checkpoint and flushing all microarchitectural state measures a cold start. Restoring warmed caches and predictors measures a steady-state continuation. Neither is universally correct; the checkpoint policy must match the question and be stated explicitly. Checkpoints also improve reproducibility because every design sees the same starting state.

=== Warm-Up and Cold Start

Many structures have transient behavior after reset. Caches, TLBs, branch predictors, prefetch tables, replacement state, DRAM row buffers, and queues need time to reach the regime being measured. A warm-up interval populates these structures and is discarded from the reported statistics.

Warm-up must be long enough for the relevant state to converge and short enough that the ROI remains representative. A cold-start study should intentionally include empty structures and report startup cost separately. Warm-up does not repair a bad checkpoint: if the OS, allocator, address stream, or phase is wrong, a longer warm-up only hides the problem.

== Trace-Driven and Execution-Driven Simulation

In *trace-driven simulation*, a previously captured sequence of instructions, memory requests, or transactions drives the model. It is fast, deterministic, and convenient for sweeping a component design. The trace fixes the dynamic behavior, however, so a simulated cache miss, branch misprediction, queue delay, or policy change cannot normally alter which request appears next. Wrong-path instructions, timing-dependent synchronization, and feedback from the simulated system are therefore difficult or impossible to model unless they were encoded in the trace.

In *execution-driven simulation*, the simulator emulates or executes the program and determines the next instruction and request as the simulated state evolves. It can model branch outcomes, data-dependent addresses, wrong-path work, OS activity, and timing feedback more naturally, but it must maintain architectural state and is slower.

#three-line-table(
  columns: (1.45fr, 2.15fr, 2.35fr),
  inset: 5pt,
  align: left,
)[
  | *Property* | *Trace-driven* | *Execution-driven* |
  | :--------- | :------------- | :----------------- |
  | Next event | Read from a captured stream | Determined by current simulated state |
  | Speed and reproducibility | Usually high and deterministic | Lower; depends on functional execution and timing |
  | Timing-to-control feedback | Usually absent | Naturally representable |
  | Wrong path/speculation | Must be captured or approximated | Can be generated and recovered if state is modeled |
  | Best use | Component sweeps and stable request streams | Full-system, speculative, or timing-sensitive studies |
]

Hybrid simulators use traces for stable regions and execution for regions where timing changes behavior. The boundary must preserve enough state that switching modes does not create an artificial cache, predictor, or program phase.

== State Maintenance and Recovery

An execution-driven or speculative simulator must define ownership for every state element: program counter, registers, memory, page tables, caches, predictors, queues, outstanding requests, and OS/device state. A wrong-path instruction may allocate entries, train a predictor, issue a prefetch, or touch a cache even though its architectural result is discarded. The simulator must specify which microarchitectural side effects survive recovery.

Recovery can use a checkpoint, a history buffer, undo logging, or explicit invalidation. The mechanism is part of the model: restoring registers but not a wrong-path cache fill models a different machine from restoring both. State snapshots should be versioned and validated so that a restored run is deterministic.

== Advancing Simulated Time

Architectural simulators commonly use either cycle-by-cycle polling or discrete events.

#three-line-table(
  columns: (1.55fr, 2.05fr, 2.35fr),
  inset: 5pt,
  align: left,
)[
  | *Method* | *How time advances* | *Tradeoff* |
  | :------- | :------------------ | :-------- |
  | Cycle-by-cycle | Increment the global cycle and inspect every pipeline/resource each cycle | Simple and easy to reason about; spends work checking idle structures |
  | Event-driven | Jump to the timestamp of the next completion, request, wake-up, or timeout | Efficient when events are sparse; event ordering and simultaneous events are more complex |
  | Batched/hybrid | Advance regular stages in batches and schedule exceptional events explicitly | Can approach event-driven speed while retaining regular timing structure; requires careful synchronization |
]

A cycle model should define the order of actions within a cycle, such as complete, write back, wake up, select, issue, and fetch. An event model should define a total order for events with the same timestamp, resource arbitration, and whether a newly generated event can fire in the current timestamp or only in a later one. Ambiguous ordering can create artificial one-cycle speedups or deadlocks.

The simulated state evolves as

$ "state"_(t + Delta t) = "transition"("state"_t, "events"_t, "inputs"_t) $

where `Delta t` is one cycle or the distance to the next event. The transition must conserve causality: an event cannot consume a value or resource before its producer has made it available in the modeled time order.

== Validating Accuracy

Validation asks whether the simulator represents the intended target, not whether its output merely looks plausible. Separate at least two questions:

- *Functional validation*: Does the simulated program produce the same architectural results, exceptions, memory values, and control flow as a trusted reference?
- *Timing validation*: Does it reproduce measured latency, throughput, queueing, bandwidth, miss rates, resource utilization, and ordering behavior?

Validation can be *offline* or *online*. Offline validation compares a complete run or trace after the fact. Online validation compares intermediate checkpoints, per-phase statistics, or event streams while the simulation proceeds; it localizes the first divergence and is often more useful for debugging.

#three-line-table(
  columns: (1.55fr, 2.05fr, 2.35fr),
  inset: 5pt,
  align: left,
)[
  | *Validation layer* | *Compare* | *Typical failure revealed* |
  | :----------------- | :------ | :------------------------- |
  | Functional | Final values, instruction counts, exceptions, address stream | Wrong ISA, loader, syscall, or memory-semantics model |
  | Microarchitectural | Cache/TLB misses, branch outcomes, queue occupancy, bank conflicts | Incorrect structure size, replacement, arbitration, or state update |
  | Timing | Per-component latency, overlap, throughput, tail latency | Wrong pipeline order, contention, timing parameter, or event causality |
  | System-level | End-to-end runtime, throughput, power, and phase behavior | Missing OS/device interaction or an invalid workload abstraction |
]

Use several workloads and configurations, not only the case that motivated the simulator. Report absolute error and rank correlation when comparing alternatives. Validate distributions and tails when the system is sensitive to contention; a correct mean can hide a severe tail-latency error. Keep a baseline configuration, publish parameters and seeds, and repeat stochastic experiments with confidence intervals.

Calibration is not validation. Tuning a parameter until one benchmark matches can be useful, but it can also overfit. Calibration should use measurements disjoint from the validation set, and every tuned parameter should have a physical or architectural interpretation.

== Accelerating Simulation

Simulation acceleration should preserve the modeled question while reducing overhead:

- *Hardware support*: FPGA prototypes, hardware emulation, and specialized accelerators can execute simple repetitive logic much faster than a software simulator. They often trade away observability and flexibility.
- *Software methods*: memoization can reuse the result of a deterministic state/transition pair; trace reuse, vectorization, compiled hot paths, parallel workload runs, and event skipping reduce repeated work.
- *Better engineering*: modular models, efficient data structures, profiling, deterministic seeds, checkpointing, and separating measurement from debug instrumentation improve both speed and reproducibility.

Memoization is safe only when the cached result includes every input that can affect the transition. Reusing a timing result while ignoring queue state, replacement state, or phase can silently invalidate the experiment. Parallel runs improve throughput for a design sweep, but shared random streams, host contention, and nondeterministic reductions must be controlled.

== Prototyping and Measurement

Simulation is not a substitute for measuring the device effects that the model
does not know. FPGA-based infrastructures such as *SoftMC* and *DRAM Bender*
issue programmable DRAM commands to real DIMMs, SODIMMs, and stacked-memory
boards. They expose retention, timing-margin, RowHammer/RowPress, row-buffer,
and in-DRAM-logic behavior that is difficult to infer from a nominal timing
model. A typical experiment initializes a known pattern, executes a controlled
command sequence, samples data and timing, and repeats over rows, chips,
temperatures, and voltages.

Prototype scope still matters. A PiDRAM-style FPGA system can expose
RowClone-like copy and initialization or a DRAM TRNG using commodity parts,
while a functionally-complete-DRAM or simultaneous-many-row-activation study
tests the limits of analog array operations. Report the board, DIMM/chip
geometry, address mapping, command timing, environmental conditions, and
failure filtering so that a simulator can be calibrated without turning one
device's behavior into a universal assumption.

== Ramulator: A Memory-System Simulator

DRAM standards and memory-controller designs change quickly. A simulator tied to one device or one controller becomes difficult to extend precisely when new proposals need evaluation. Ramulator was designed as a fast, modular, and extensible DRAM simulator for this space.

=== What Ramulator Models

Ramulator represents memory requests, channel/rank/bank organization, DRAM commands, timing constraints, row-buffer state, and controller scheduling. It can be driven by a simple CPU model, a trace, or integrated with a larger architectural simulator. The separation between standards, organization, and controller policy makes it possible to compare both existing technologies and proposed mechanisms.

#three-line-table(
  columns: (1.7fr, 2.15fr, 2.1fr),
  inset: 5pt,
  align: left,
)[
  | *Capability* | *Representative examples* | *Why it matters* |
  | :----------- | :-------------------------- | :--------------- |
  | Standard support | DDR3/4, LPDDR3/4, GDDR5, Wide I/O 1/2, HBM | The same workload can be compared across different latency, bank, and bandwidth organizations |
  | Research proposals | SALP, AL-DRAM, TL-DRAM, RowClone, SARP | New command/timing/controller ideas can be explored before hardware exists |
  | Performance | About 2.5x faster than the fastest open-source simulator reported in the original study | Makes larger workload/configuration sweeps practical |
  | Modularity | Pluggable standards and controller components | A policy can be changed without rewriting the complete memory model |
]

The speed comparison is a result reported for the original Ramulator study, not a permanent ranking. A fair comparison must use the same host, workload, accuracy target, and output checks.

=== Using Ramulator for a Study

A typical experiment supplies a request stream or a simple core model, selects a DRAM standard and controller, runs a warm-up and measurement interval, and records latency, bandwidth, row-buffer hits, queue occupancy, and energy-related activity if modeled. Across a workload suite, the study can reveal interactions that are hard to infer from a single benchmark.

The original workload--DRAM study compared 22 workloads and nine modern DRAM types, including DDR3, DDR4, GDDR5, HBM, HMC, LPDDR3, LPDDR4, Wide I/O, and Wide I/O 2. Its broad findings were:

- DRAM latency remains a critical bottleneck for many applications.
- Many workloads do not fully use the available bank parallelism.
- Spatial locality remains valuable when the memory subsystem can exploit it.
- Low-power memory can save energy without a large performance loss for some workload classes.

These are workload-dependent observations, not universal properties of one standard. The point of the simulator is to expose the interaction systematically.

=== Integration and Reproducibility

Ramulator is open source under the MIT license and can be integrated with CPU, GPU, or full-system simulators. A reproducible memory experiment should record the Ramulator version/commit, standard and timing parameters, address mapping, controller policy, request source, warm-up and ROI, random seeds, and output aggregation. Ramulator 2.0 modernizes the design with a more modular and extensible framework; it should be treated as a distinct implementation and validated independently.

Ramulator is primarily a memory-system/component model. It does not, by itself, reproduce all OS, virtual-memory, device, or core behavior. Those effects must come from the driver or an integrated simulator when they influence the research question.

=== NAPEL and PIM Performance Prediction

Not every processing-in-memory design needs a full cycle-accurate simulator
for its first design-space sweep. *NAPEL* (Near-Memory Computing Application
Performance prediction via Ensemble Learning) extracts application and kernel
features, such as operation mix, parallelism, locality, and memory traffic,
from representative runs and learns a performance model for candidate PIM
organizations. The model can quickly screen mappings and identify which
kernels are likely to benefit; selected points must then be checked with a
detailed memory or architectural simulation.

The same separation appears in *DAMOV-SIM*: a benchmark suite characterizes
data-movement bottlenecks, while a simulator evaluates alternative
processing-near-memory placements and interfaces. Prediction models are useful
only within the feature and hardware range on which they were trained. Report
the training workloads, held-out workloads, feature definitions, and error;
otherwise a fast learned predictor can hide an extrapolation failure.

== Virtuoso: Imitation-Based OS Simulation

Virtual-memory research exposes a difficult scope tradeoff. Emulation-based simulators such as Ramulator, ZSim, Sniper, and ChampSim run quickly and model selected microarchitectural features, but have limited support for OS primitives. Full-system simulators such as gem5-FS, QFlex, and PTLsim execute a full-blown OS on a hardware simulator, but are slow and difficult to develop.

#three-line-table(
  columns: (1.65fr, 2.25fr, 2.2fr),
  inset: 5pt,
  align: left,
)[
  | *Simulator class* | *Strength* | *Limitation for VM research* |
  | :---------------- | :------- | :--------------------------- |
  | Emulation-based | High simulation speed; focused microarchitectural modeling | OS, allocator, page-table, and system-call overhead may be missing or analytically approximated |
  | Full-system | Executes a complete OS and hardware model; rich software interaction | Low speed and high development/validation cost |
  | Virtuoso goal | Fast prototyping plus accurate hardware/software VM evaluation | Accuracy depends on selecting and validating the OS modules that are imitated |
]

=== Imitation Rather Than a Complete Kernel

Virtuoso uses a lightweight userspace kernel written in a high-level language. It imitates only the OS functionality relevant to the research question instead of booting and simulating every kernel subsystem. The selected modules can include a buddy allocator, radix-based page tables, transparent huge pages, swap space, page cache, NUMA management, virtual-memory-area handling, cgroups, `hugetlbfs`, block-device behavior, and protection checks.

This is an imitation, not a claim that the full OS is irrelevant. The researcher chooses the modules, interfaces, and overheads that must be preserved, then validates that omitted kernel behavior does not change the conclusion. A module that is irrelevant to one VM policy can be essential to another.

=== Connecting the Userspace Kernel to Hardware Timing

Binary instrumentation observes the instruction stream and invokes the lightweight kernel when an emulated OS operation is needed. The architectural simulator models core and memory timing, while the userspace kernel supplies the functional outcome and the software-level work or delay.

The conceptual flow is:

1. Instrumented application instructions generate ordinary computation and memory events.
2. A system call, allocation, page fault, mapping change, or other selected event enters the userspace kernel.
3. The kernel module updates its software state and emits the corresponding memory accesses, translations, protection actions, or timing overhead.
4. The architectural simulator schedules those events through the modeled core, cache, interconnect, and memory system.
5. The functional result returns to the instruction stream, and the next event is determined using the updated state.

This arrangement combines the speed of emulating only desired OS functionality with the timing fidelity of an architectural simulator. It also makes the boundary explicit: software state and hardware state must agree on addresses, permissions, page sizes, and completion ordering.

#three-line-table(
  columns: (1.55fr, 2.35fr, 2.2fr),
  inset: 5pt,
  align: left,
)[
  | *Virtuoso property* | *Mechanism* | *Benefit* |
  | :------------------ | :-------- | :------- |
  | Rapid development | High-level modules instead of a full kernel | New VM policies can be prototyped quickly |
  | High speed | Execute only selected kernel functionality | Avoids the cost of simulating unrelated OS work |
  | Hardware/software accuracy | Integrate the userspace kernel with a timing simulator | Captures VM overhead and hardware contention together |
]

=== MimicOS and VirTool

MimicOS is an example lightweight kernel implementation in C++ that imitates Linux-related mechanisms such as the buddy allocator, radix page table, transparent huge pages, swap space, and page cache. The implementation is useful only insofar as those mechanisms and their costs are validated against the chosen reference behavior.

Virtuoso's VirTool demonstrates that the framework can host a broad VM technique set, including multiple page-table designs, nested-MMU support, software-managed TLBs, hash-based address mappings, transparent-huge-page policies, speculative translation, page-size prediction, memory-tagging schemes, contiguity-aware schemes, intermediate address spaces, and TLB prefetching. The point is not the feature count; it is that hardware and software alternatives can be changed behind one consistent simulation interface.

=== Integration with Other Simulators

The lecture reports integration with five diverse simulators:

#three-line-table(
  columns: (1.55fr, 2.25fr, 2.3fr),
  inset: 5pt,
  align: left,
)[
  | *Simulator* | *Primary focus* | *What the combination enables* |
  | :---------- | :------------- | :----------------------------- |
  | gem5-SE | System-call-emulation mode of gem5 | VM mechanisms with a detailed general architectural model |
  | Ramulator | Main-memory subsystem | Translation and allocator effects coupled to detailed DRAM behavior |
  | Sniper | Multicore systems | VM policies under scalable multicore timing and contention |
  | ChampSim | Microarchitecture and trace-oriented studies | Fast VM experiments over broad instruction traces |
  | MQSim | Storage devices | Virtual-memory behavior coupled to SSD/storage timing |
]

This versatility is useful when the research question changes, but it does not remove the need for validation at each integration boundary. A VM policy may look correct with a core-only model and change once page faults, storage, NUMA traffic, or DRAM scheduling are included.

== A Practical Simulation Workflow

#three-line-table(
  columns: (1.1fr, 2.25fr, 2.65fr),
  inset: 5pt,
  align: left,
)[
  | *Step* | *Decision* | *Evidence to record* |
  | :----- | :-------- | :------------------ |
  | 1. Define the question | Metric, target system, and decision the experiment should support | Baseline, hypotheses, and what counts as a meaningful change |
  | 2. Choose scope | Component/full system, program/trace, functional/timing, software/hardware | Included and omitted interactions, information visibility |
  | 3. Form workloads | Complete runs, phases, samples, checkpoints, and warm-up | Selection rule, interval weights, seeds, starting state |
  | 4. Build the model | State, event ordering, parameters, and recovery behavior | Assumptions and invariants |
  | 5. Validate | Functional, microarchitectural, timing, and system-level comparisons | Reference measurements, error, correlation, and tails |
  | 6. Explore and refine | Sweep designs, inspect outliers, and move to a more detailed level when needed | Full configuration matrix and discarded cases |
  | 7. Report limits | Explain uncertainty, omitted effects, and transfer conditions | Reproducible scripts/configuration and residual risk |
]

The final result should be a defensible chain from question to model to evidence. A fast number without a scope statement, a workload rule, and a validation argument is not yet an architectural conclusion.

== Agent-Based Simulation

Architectural simulation is one instance of a broader pattern: represent a
system as many interacting agents, give each agent state and local behavior,
and observe the global behavior that emerges. In a flock model, for example,
each bird has a position and velocity and follows separation, alignment, and
cohesion rules. The simulator need not prescribe a global trajectory; it
advances local interactions and resolves their effects over time.

*BioDynaMo* applies this model to scalable biological simulation. A cell agent
has attributes such as type and position and can execute behaviors including
substance secretion, chemotaxis, and mechanical forces. The infrastructure
partitions agents spatially, schedules independent interactions in parallel,
and provides checkpointing/visualization and reproducible execution. It has
been used for cell sorting and other biology, but the engineering lessons are
general: define the neighborhood, avoid races when agents update shared state,
balance partitions as density changes, and validate both local rules and
population-level behavior.

Agent-based simulation differs from a trace replay because the next event is
generated by the current population state. It therefore captures feedback and
emergent behavior, but requires a clear time-stepping or event-ordering rule
and can become expensive when every agent interacts with many neighbors.
