#import "../../index.typ": *
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: series-chapter.with(
  arch-notes-series,
  route: "docs/arch-notes/25-future-architecture/",
  title: "Epilogue: Future Computer Architecture",
)

== Architectural Foundations

The preceding topics build a computer system from transistors and logic to complete execution and memory systems:

- ISA and microarchitecture define the hardware/software contract.
- Pipelining, branch prediction, speculation, out-of-order execution, and superscalar issue exploit instruction-level parallelism.
- Dataflow, VLIW, systolic arrays, decoupled access/execute, SIMD, vector, and GPU machines expose different execution models.
- Memory organization, caches, prefetching, and virtual memory determine how data reaches computation.

The mechanisms are important, but the reusable skill is to identify the actual bottleneck and reason about tradeoffs. A design should be evaluated across performance, energy, area, programmability, reliability, security, and cost rather than by peak throughput alone.

== Why Architectures Must Change

Applications process more data, but traditional scaling no longer improves every property at once. Higher transistor density does not automatically provide proportionally faster cores, cheaper data movement, lower power, or greater reliability.

Important pressures include:

- *Energy and power*: data movement and storage can consume more energy than arithmetic.
- *Memory latency and bandwidth*: processor throughput grows faster than the ability to supply operands.
- *Reliability and security*: denser devices and more shared structures create new failure and attack modes.
- *Predictability*: average throughput is insufficient for real-time and interactive services with strict tail-latency limits.
- *Workload diversity*: AI, graph analytics, genomics, databases, and scientific applications have different data types, access patterns, and accuracy requirements.
- *End of uniform improvement*: one general-purpose core cannot be best for every important workload.

These pressures motivate architecture that is specialized where the workload permits it and programmable where deployment requires it.

== Four Broad Directions

#three-line-table(
  columns: (1.45fr, 2.2fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *Direction* | *Primary question* | *Representative approaches* |
  | :---------- | :--------------- | :-------------------------- |
  | Secure, reliable, and safe | How can the system remain correct under faults, attacks, and uncertainty? | Isolation, integrity, fault tolerance, verification, safe interfaces |
  | Energy-efficient and memory-centric | How can useful work be performed with less data movement? | Specialization, near-data processing, processing in memory, new memories |
  | Low-latency and predictable | How can both average and worst-case response time be controlled? | QoS, resource partitioning, deterministic scheduling, latency-aware memory |
  | Domain-oriented | Which application properties deserve architectural support? | AI/ML, genomics, medicine, graph, database, and scientific accelerators |
]

These directions interact. For example, moving computation into memory may improve performance and energy, but it also changes virtual-memory translation, protection, coherence, and the trusted computing base.

== Cross-Layer Specialization and Co-Design

A system is a hierarchy of transformations:

`problem -> algorithm -> programming model -> compiler/runtime -> ISA -> microarchitecture -> circuits -> devices`.

Each layer hides details from the layer above. Abstraction improves portability, but a strict boundary can hide information required for efficiency. Cross-layer design deliberately exposes selected information or specializes several layers together.

Examples:

- A sparse algorithm exposes sparsity so hardware can skip zero-valued work.
- A compiler tiles a matrix so an accelerator reuses values in a local buffer.
- An ISA adds vector, matrix, or domain operations rather than expressing every operation as scalar instructions.
- A runtime places data near the memory-side engine that will process it.
- A memory device exposes bulk primitives that exploit its internal organization.

The central principle is:

> Specialize and co-design across the stack when the efficiency gain justifies the loss of generality and the additional software contract.

Specialization is not simply adding an accelerator. The entire path from application to data placement must allow the accelerator to receive useful work without excessive conversion, synchronization, or copying.

== Heterogeneous and Domain-Specific Systems

A heterogeneous system combines components with different strengths: general-purpose CPUs, GPUs, matrix/tensor engines, FPGAs, media engines, network accelerators, and memory-side processors.

The CPU normally handles control-intensive and latency-sensitive work. A specialized engine handles a regular, parallel, high-volume phase. Effective acceleration therefore depends on more than the engine's peak operation rate:

`total time = host work + data preparation + transfer + accelerator work + synchronization`.

Amdahl's law applies to both computation and communication. A very fast accelerator provides little end-to-end speedup when data conversion, launch overhead, or the unaccelerated fraction dominates.

Three recurring design questions are:

1. *Interface*: how does software describe work and discover capabilities?
2. *Data orchestration*: who allocates, places, transforms, and transfers data?
3. *Correctness*: how are protection, synchronization, coherence, and exceptions preserved?

Large matrix engines and wafer-scale systems illustrate aggressive specialization and integration. Large on-chip memories, high internal bandwidth, regular communication, and compiler-managed execution can provide high efficiency, but mapping and utilization become central architectural problems.

=== Heterogeneous Layers: Mensa

Even one neural-network model can contain layers with very different resource demands. Measurements across CNNs show up to 200x variation in multiply-accumulate (MAC) intensity and up to 244x variation in FLOP/Byte. A single monolithic accelerator is therefore either overprovisioned for compute-centric layers or starved by data movement on data-centric layers.

Mensa groups layers into a small number of families and maps each family to a matching heterogeneous accelerator placed alongside 3D-stacked DRAM. A runtime chooses the family-specific engine while keeping the CPU in the control path. The Mensa-G evaluation reports about 3.0x lower energy and 3.1x higher inference throughput than a baseline Edge TPU. The result is a reminder that heterogeneity can be useful inside one model, not only between unrelated applications.

=== PAPI and CENT: Near-Memory LLM Inference

Large-language-model decoding adds a more dynamic form of heterogeneity. A
fully connected (FC) kernel can be compute-bound or memory-bound depending on
its arithmetic intensity, batch size, and the available row-level and
thread-level parallelism (RLP/TLP). Attention kernels repeatedly access the
key/value cache and are usually limited by memory capacity and bandwidth.

*PAPI* (ASPLOS 2025) combines computation-centric processing units (PUs) with
two kinds of PIM unit. FC-PIM places more floating-point capability near the
memory banks for FC kernels; Attn-PIM provides more bank groups and capacity
for attention and KV-cache accesses. An online scheduler first monitors RLP
and TLP, predicts FC arithmetic intensity against an offline
memory-boundedness threshold, and then maps the kernel to PUs or FC-PIM. The
important point is dynamic placement: one fixed "PIM or GPU" choice is not
optimal throughout a decoding session.

#three-line-table(
  columns: (1.45fr, 2.05fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *Kernel condition* | *Preferred resource* | *Reason* |
  | :----------------- | :----------------- | :------ |
  | Compute-bound FC | High-performance PU | More arithmetic throughput and less benefit from moving operands into PIM |
  | Memory-bound FC | FC-PIM | Bank-local bandwidth avoids repeated host/interconnect transfers |
  | Attention / KV-cache | Attn-PIM | More memory capacity and bank-group parallelism for irregular cache reads |
  | Changing RLP/TLP | Runtime scheduler | The best mapping changes with batch and decoding phase |
]

Across LLaMA-65B, GPT-3 66B, and GPT-3 175B workloads, the PAPI evaluation
reports about 1.8x speedup and 3.4x energy-efficiency improvement over its best
prior decoding baseline (the exact comparison varies by baseline and
parallelism). These values include the scheduling and data-partitioning model;
they are not the peak bandwidth of a PIM device.

*CENT* ("PIM Is All You Need", ASPLOS 2025) explores a complementary point:
a CXL-enabled near-memory system that removes the dependency on a discrete
GPU for LLM inference. CXL provides a coherent, scalable attachment for
memory-side compute and capacity, while the host CPU and near-memory engines
share work through an explicit runtime interface. CENT illustrates a useful
system-level question for any accelerator: whether the saved GPU transfer and
memory capacity justify the added CXL latency, software stack, and resource
sharing. PAPI and CENT therefore extend the same data-centric principle from
fixed in-memory primitives to dynamic, heterogeneous LLM execution.

== Data Movement as the Bottleneck

In a processor-centric system, instructions and operands travel through many structures before arithmetic occurs: storage, memory channels, caches, interconnects, queues, register files, and execution units. The energy and latency of this movement can exceed the cost of the arithmetic operation itself.

Data-intensive workloads amplify the problem because they have one or more of these properties:

- Little computation per byte fetched.
- Large working sets that exceed on-chip caches.
- Irregular accesses with poor locality and weak prefetchability.
- Bulk operations that touch many locations but perform simple logic.
- Intermediate data that is produced only to be moved and consumed elsewhere.

The relevant metric is therefore not only operations per second. Useful measures include bytes moved per useful operation, energy per result, off-chip traffic, memory-level parallelism, locality, and the fraction of data filtered before reaching the CPU.

=== Quantitative Motivation

The cost gap is large enough to determine the architecture. In a representative energy breakdown, an integer `ADD` is about 0.1 pJ while a DRAM access is about 640 pJ: one DRAM access costs roughly 6400x as much energy as the simple addition it supplies. Measurements of Google consumer-device workloads attribute 62.7% of total system energy to data movement. For Google machine-learning models on edge devices, `>90%` of total system energy is spent in memory; for the LSTM and transducer examples, `>90%` is in the off-chip interconnect and DRAM. These numbers motivate reducing bytes moved, even when the arithmetic unit itself is already efficient.

== Data-Centric Architectures

Processor-centric architecture brings data to computation. Data-centric architecture instead places computation where data is stored or communicates only the information required by the consumer.

Design principles:

- Ensure that data movement does not overwhelm computation.
- Exploit different properties of different data rather than treating all bytes identically.
- Use data values, types, access patterns, and metadata to guide decisions.
- Place computation and storage according to communication needs.
- Avoid moving data that will be discarded, overwritten, or reduced immediately.
- Preserve programmability and correctness across the resulting distributed system.

The term *near-data processing* covers several locations. They must be distinguished because they provide different capabilities and face different constraints.

#three-line-table(
  columns: (1.4fr, 1.55fr, 2.7fr),
  inset: 5pt,
  align: left,
)[
  | *Approach* | *Where computation occurs* | *What movement it avoids* |
  | :--------- | :------------------------- | :----------------------- |
  | Processing using memory | In the memory-cell array or its analog behavior | Reading many cells out of the array |
  | Processing near memory | In logic close to banks, dies, or memory stacks | Sending high-volume data across the off-chip channel |
  | Processing in storage | In or beside an SSD/storage controller | Transferring cold or filtered data through storage I/O and main memory |
]

== Processing-in-Memory Taxonomy

*Processing in memory (PIM)* is often used as an umbrella term for two different mechanisms.

=== Physical Placement: Bank, Vault, and Logic Layer

*Processing-using-memory* reuses the memory array and its sensing circuitry. In DRAM this usually means operating inside a bank/subarray, where row activation, sense amplifiers, bitlines, and local buses expose bulk operations without adding a conventional arithmetic core. The operation is constrained by the cell and array protocol, but the data does not cross the memory channel.

*Processing-near-memory* adds computation logic beside the storage structures: near a DRAM bank, beside a high-bandwidth-memory vault controller, on a memory module, or on the logic layer of a 3D stack. A near-bank engine sees one bank's locality; a near-vault engine can use the stack's internal links; logic-layer engines can coordinate several vaults while still avoiding most off-package traffic. These placements have richer control and arithmetic than processing-using-memory, but consume logic-layer area and must handle bank/vault contention and inter-engine communication.

The distinction is architectural rather than merely physical. A memory controller can expose an array primitive as a command, while a logic-layer core can execute a kernel. Both are "near data," yet they require different instruction sets, synchronization, protection, and failure semantics.

=== Compute Using Memory Structures

The memory array itself performs an operation by exploiting its internal organization or device physics. Operations can affect an entire row, subarray, or group of cells in parallel.

Representative bulk primitives include:

- *COPY*: duplicate a row or region without sending every byte through the CPU.
- *ZERO/initialization*: initialize many locations inside memory.
- *AND, OR, NOT*: compute bulk bitwise operations over many elements.
- *MAJORITY*: combine multiple rows; together with inversion, majority logic can synthesize other Boolean functions.

RowClone is an example of using DRAM row operations for bulk copy and initialization. Ambit uses simultaneous DRAM-row activation and sense-amplifier behavior to realize bulk bitwise operations. SIMDRAM organizes sequences of such majority/inversion operations to execute wider bit-serial computations.

This approach offers very high internal parallelism and low external traffic, but the available operations are constrained by the array. It may require special data layout, careful handling of destructive operations, temporary rows, and changes to the memory controller.

=== In-DRAM Mechanisms in Detail

- *RowClone*: two consecutive `ACT` commands to a source and destination row in one subarray leave the row-buffer value in the destination, copying a full DRAM row (often 4 KB) without a cache or channel round trip. Inter-bank and inter-subarray copies need additional movement, so placement still matters.
- *Ambit*: triple-row activation makes the sense amplifier resolve a majority function; combining majority with inversion implements bulk `AND`, `OR`, `NAND`, and `NOR` over bit-vectors. A neighboring-subarray path supplies `NOT`, allowing database bitmap operations to run in the array.
- *SIMDRAM*: a compiler/framework lowers bit-serial SIMD operations to a microprogram of `ACT`/`PRE` and majority/inversion steps. It exposes a software call while the memory controller executes the generated sequence, trading many short DRAM operations for very wide parallelism.
- *MIMDRAM*: segmented global wordlines select narrower portions of a row than the native DRAM row. Only mats containing an operand are activated, independent PIM operations can run concurrently (a multiple-instruction, multiple-data model), and local/global buses provide low-cost vector reduction. LLVM passes schedule these operations and hide the mapping from the programmer.
- *Sectored DRAM*: sector latches and local wordline drivers permit fine-grained row activation, while variable burst length transfers only the open words of a cache block. It reduces both unnecessary cell activation and channel traffic with a small area cost; a sector predictor and load/store-queue lookahead address the extra sector-miss cases.

These mechanisms illustrate a continuum: RowClone and Ambit exploit analog array behavior, SIMDRAM and MIMDRAM add compilation and scheduling around those primitives, and Sectored DRAM changes the transfer/activation granularity even when no arithmetic is requested.

=== Commodity DRAM and PiDRAM

PiDRAM is an end-to-end FPGA framework that drives off-the-shelf DRAM with carefully selected timing violations. A host FPGA/RISC-V system and a PIM-enabled DIMM expose RowClone-like copy/initialization and a DRAM-based true-random-number generator without changing the cell array. Its microbenchmarks report about 119x higher copy throughput and 89x higher initialization throughput than a conventional host path. Independent commodity-DRAM characterization further shows that one row can be copied to up to 31 destinations with more than 99.98% success, `NOT` can produce up to 32 outputs, and `AND`/`NAND`/`OR`/`NOR` can be evaluated with up to 16 inputs (with reliability depending on chip and data pattern).

Memory-cell behavior can also generate security primitives. Device variation can produce a physically unclonable function (PUF), and timing or noise variation can contribute entropy for a true random-number generator (TRNG). Such mechanisms require characterization, error correction, and protection against environmental variation.

=== Compute Near Memory

General-purpose or specialized logic is placed near memory banks, in a memory controller, on the logic layer of a 3D-stacked memory, or on the same module/package.

Near-memory logic can support richer arithmetic and control than an array primitive. It also has access to high internal bandwidth before data crosses a narrower external interface. Possible engines include simple cores, SIMD units, fixed-function pipelines, or programmable accelerators.

3D-stacked memory is attractive because multiple memory dies connect through dense vertical links to a logic layer. A graph-processing engine, for example, can partition vertices across memory stacks and perform traversal or update operations close to the responsible partitions.

The limiting resource often shifts from external bandwidth to internal bank conflicts, logic-layer area and power, synchronization, or inter-stack communication. Near-memory processing does not make communication free; it changes where communication occurs.

=== Case Study: Tesseract

Tesseract (Ahn et al., ISCA 2015) is a concrete near-memory graph-processing design: an interconnected set of 3D-stacked memory/logic chips, each with simple in-order cores and a crossbar network. The host sees a memory-mapped accelerator interface that is explicitly non-cacheable and physically addressed. Inside a stack, local prefetch logic and a prefetch buffer feed the cores; message-transfer/processing units, message queues, and network interfaces carry remote function calls between stacks. This arrangement keeps graph data near the core that owns it, but shifts coherence and virtual-memory responsibility to software and the runtime.

The evaluated Tesseract system exposes about 8 TB/s of aggregate stack-internal bandwidth (versus 102.4 GB/s for the DDR3 baseline and 640 GB/s for the HMC baselines). Across five graph algorithms, the prefetching/message-passing configuration reaches up to 13.8x speedup (reported as more than 13x) and more than 8x system-energy reduction relative to the corresponding processor-centric baselines. The trend matters more than the peak: local work and timely prefetching remove off-chip transfers, while remote calls and queueing make remaining communication explicit.

=== Processing in Storage

Storage-side processing filters, searches, compresses, transforms, or aggregates data before it traverses the storage interface and main-memory hierarchy.

For genomics, a storage device can reject sequencing reads that cannot match a reference or prefilter candidate regions before expensive alignment. The host then transfers only the surviving records. Similar ideas apply to database selection, search, compression, and analytics over large stored data sets.

Storage-side processing is useful when the eliminated transfer is large relative to the amount of device-side computation. It is less useful when every byte must still be returned, the operation requires frequent fine-grained host interaction, or the device lacks enough compute and memory capacity.

=== In-Flash Primitives

NAND flash also exposes useful device-level operations. Flash-Cosmos uses multi-wordline sensing: simultaneously sensing several wordlines makes a bitline read as `1` only when all selected cells are `1`, which implements a wide bitwise `AND` in one sensing operation. Existing flash features and sense circuitry can derive `NOT`, `NAND`, `NOR`, `XOR`, and `XNOR` without changing the cell array. Real-device results support up to 48 operands for `AND` and up to 4 for `OR` with less than a 10% sensing-latency increase; error-suppression steps avoid propagating raw bit errors. The primitive is attractive for bitmap filtering and search because it removes both flash-channel traffic and host-side bitwise loops, but it is limited by block/wordline placement and flash program/erase semantics. Related work such as CIPHERMATCH applies in-flash processing and compact packing to homomorphic string matching.

== Mapping Computation to PIM

A workload is a good PIM candidate when:

- Its performance or energy is dominated by moving data.
- It has sufficient parallelism across banks, partitions, or rows.
- Each partition performs mostly local work.
- The result is much smaller than the input, or in-place update avoids a round trip.
- Required operations match the available memory-side primitives.
- Communication and synchronization between partitions are limited.

Examples include bulk initialization/copy, bit-vector operations, sparse matrix-vector multiplication, graph traversal, database filtering, reductions, machine-learning operators, sequence alignment, and some transcendental or lookup-based functions.

The mapping process should identify:

1. The data-movement bottleneck in the baseline.
2. The unit of placement: page, row, bank, channel, stack, or storage range.
3. The operation executed at each location.
4. The data that still crosses location boundaries.
5. The synchronization, ordering, and failure semantics.
6. The fallback path when the PIM capability is unavailable.

== Programming and Execution Models

Hardware capability alone does not make PIM usable. Software needs a stable way to express operations, identify data, and synchronize with host execution.

Possible interfaces include:

- Explicit ISA instructions for fixed bulk operations.
- Library calls or compiler intrinsics.
- Commands sent to a memory-side queue.
- Kernels offloaded to programmable near-memory cores.
- Runtime-generated operations selected from a capability description.

An asynchronous command interface can overlap host and PIM work, but it needs completion events, dependencies, exceptions, and cancellation semantics. A synchronous instruction is simpler to reason about but may block a processor for a long and variable interval.

Compilers and runtimes must decide when offloading is profitable. They may transform data layout, batch small requests, partition work across memory units, and preserve a software fallback. Libraries are especially important for stable primitives such as copy, bitset operations, sparse linear algebra, or database scans.

=== Software and System Contracts

PIM adoption depends on a contract that spans the programmer, compiler, runtime, OS, and memory device. Representative efforts make different parts of that contract explicit:

- *TOM* (Transparent Offloading and Mapping) hides near-data placement and offload decisions from GPU programmers while mapping work to memory-side engines.
- *DaPPA* provides a data-parallel programming model for expressing partitioned PIM kernels and their communication.
- *SimplePIM* supplies high-level array metadata, host-to-PIM and PIM-to-PIM communication, kernel launch, and synchronization abstractions for real PIM hardware.
- *DAMOV* contributes a data-movement-bottleneck methodology, benchmark suite, and simulator so that an offload decision can be evaluated against a meaningful baseline.
- *LazyPIM* delays most CPU/PIM coherence traffic and validates conflicting updates at synchronization boundaries; *CoNDA* provides a more general efficient coherence protocol for near-data accelerators.
- *SynCron* targets synchronization itself, providing efficient barriers and coordination for distributed near-data engines.

Together these projects emphasize that an ISA opcode alone is insufficient. A usable contract must define data handles and placement, cacheability, address translation, command completion and exceptions, coherence/consistency ordering, synchronization, capability discovery, and a portable fallback when a device lacks the primitive.

== System Integration Challenges

#three-line-table(
  columns: (1.35fr, 2.15fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Layer* | *Problem* | *Required mechanism* |
  | :------ | :-------- | :------------------- |
  | Data placement | Operands may reside in different banks or modules | Allocation, migration, partitioning, and locality-aware scheduling |
  | Virtual memory | PIM sees data through physical structures while applications use virtual addresses | Translation, page pinning/migration rules, protection checks, faults |
  | Coherence | CPU caches may hold stale or dirty copies | Flush/invalidate, coherent commands, ownership transfer, or noncoherent regions |
  | Consistency | Host and PIM operations may be reordered | Defined ordering points, fences, completion events, and atomics |
  | Communication | Distributed PIM engines exchange partial results | Interconnect, messaging, collective operations, and congestion control |
  | Resource sharing | Applications contend for banks, bandwidth, and engines | Scheduling, isolation, QoS, and accounting |
  | Reliability/security | Memory-side logic handles protected data | Access control, integrity, error handling, attestation, and fault containment |
  | Portability | Devices expose different primitives and capacities | Common abstractions, discovery, libraries, compilation, and fallback |
]

=== PIM Security Threat Model

Adding computation beside or inside memory adds privileged agents, command queues, crossbars, and timing behavior to the trusted computing base. A malicious or compromised PIM kernel could read another process's bank, issue operations through a physically addressed/non-cacheable interface, or leave partially updated data after an exception. Even honest kernels can expose timing and contention channels: row activation, bank/vault occupancy, queue pressure, and data-dependent sensing can amplify covert channels and RowHammer-like disturbance. Secure deployment therefore needs capability-checked commands, IOMMU-like translation or protected handles, process isolation and memory-integrity checks, authenticated firmware/attestation, rate limiting and fault containment, and an explicit rule for cache flush, ordering, rollback, and revocation. PUF/TRNG and in-flash primitives also need entropy/error characterization so that a performance feature does not become a data-leakage or reliability primitive.

=== Coherence and Consistency

Suppose a CPU cache contains a dirty copy of a page while a PIM engine reads DRAM directly. Without coordination, the PIM engine observes stale data. Similarly, a CPU may read a cached value after PIM has updated memory.

Solutions include:

- Make PIM operations participate in hardware coherence.
- Flush dirty lines before offload and invalidate stale lines before reuse.
- Mark regions uncacheable or give temporary ownership to the PIM engine.
- Restrict PIM operations to explicitly managed buffers.

Each solution trades hardware complexity, traffic, programmability, and concurrency. Correctness also requires an ordering model: software must know which earlier stores are visible to PIM and when PIM results become visible to later loads.

=== Virtual Memory and Protection

Applications pass virtual addresses, but a memory-side engine operates on physical channels, banks, rows, or devices. The system must translate and authorize every region without allowing PIM to bypass process isolation.

Options include translating and pinning pages before launch, giving a near-memory engine its own IOMMU-like translation, or issuing operations on protected physical handles created by the OS. Page migration and swapping must be coordinated with outstanding commands. Fault semantics need particular care because partially completed bulk operations may not be trivially restartable.

=== Data Placement and Partitioning

PIM performance depends on where data resides. Two operands placed in different banks or modules may require more movement than the operation saves. The OS, allocator, runtime, or compiler therefore needs topology information and control over placement.

Good partitioning balances work while maximizing local accesses. Poor partitioning causes hot banks, serialized requests, replicated state, or expensive reductions across PIM units. Placement is thus part of the programming model, not merely a memory-controller detail.

== Real PIM Design Points

Commercial and prototype systems occupy different points in the design space:

#three-line-table(
  columns: (1.35fr, 1.75fr, 2.55fr),
  inset: 5pt,
  align: left,
)[
  | *Design point* | *Representative example* | *Architectural character* |
  | :------------- | :----------------------- | :------------------------ |
  | Programmable cores near DRAM | UPMEM-style DRAM processing units | Many small cores execute kernels close to local memory banks |
  | Fixed/vector logic near high-bandwidth memory | HBM-PIM/AiM-style designs | Specialized arithmetic exploits internal bandwidth for regular kernels |
  | Memory-module acceleration | Accelerator DIMM/AxDIMM-style systems | Logic on or near the module processes selected operations |
  | In-array DRAM operations | RowClone, Ambit, SIMDRAM | Row-level bulk movement or bit-serial logic uses DRAM structures |
  | Logic layer in stacked memory | Graph/analytics research prototypes | Cores or accelerators use stack-internal bandwidth and partitioned data |
]

These examples should not be compared only by TOPS or internal bandwidth. They expose different operation sets, programming models, capacities, precision, memory semantics, and host-integration costs.

== Evaluating a Future Architecture

An architectural evaluation should first define a fair baseline and identify what resource is actually removed or reduced. For data-centric systems, report at least:

- End-to-end performance, including data preparation and host/PIM synchronization.
- Total system energy, including memory, interconnect, and host overhead.
- Bytes transferred at each boundary, not only arithmetic throughput.
- Area, power, and thermal constraints of memory-side logic.
- Bank/channel utilization and load balance.
- Sensitivity to data placement, input size, and access distribution.
- Effects on concurrently running applications and memory QoS.
- Software changes, portability, and fallback behavior.
- Correctness, reliability, and security assumptions.

A claimed improvement can come from specialization, added parallelism, more bandwidth, a changed algorithm, reduced precision, or reduced data movement. A rigorous comparison separates these causes.

== Architectures for Genomics and Medicine

Genomics illustrates why domain knowledge matters. Sequencing pipelines manipulate enormous data sets, but their stages have different properties: filtering, exact matching, approximate alignment, graph traversal, dynamic programming, compression, and storage retrieval.

Architectural opportunities include:

- Filter reads close to storage or memory before expensive alignment.
- Accelerate seed lookup and dynamic-programming kernels.
- Compress reference and read data to reduce movement.
- Design memory systems for irregular graph/genome accesses.
- Preserve privacy, reproducibility, and numerical/algorithmic correctness.

=== Filtering Before Alignment: GRIM-Filter and GenStore

Read mapping is a useful example of filtering before expensive computation. *GRIM-Filter* performs seed-location filtering with processing-in-memory: reads that have no possible reference location are rejected near DRAM, while only candidates continue to approximate alignment. *GenStore* moves the same idea into the storage system, eliminating a storage-to-host transfer for reads that can be discarded there. The GenStore evaluation reports about 1.4x--33.6x speedup and 3.9x--29.2x energy reduction at low additional cost. Both designs exploit the fact that a small, simple predicate can remove most of the bytes that a general-purpose aligner would otherwise fetch and inspect.

Medicine adds stricter requirements for privacy, safety, explainability, and long-lived data formats. Performance must be considered together with trust and deployment constraints.

== Open Research Questions

- Which abstractions expose locality and data semantics without tying software to one device?
- How should the OS allocate, migrate, and protect data for heterogeneous engines?
- Can coherence and virtual memory remain simple when computation is distributed throughout memory and storage?
- Which operations are stable enough to standardize in an ISA or memory interface?
- How should resource sharing provide both throughput and predictable latency?
- How can systems detect faults or attacks in increasingly complex memory-side logic?
- What evaluation methodology prevents optimistic comparison against an artificially weak baseline?
- When does a specialized design save enough energy and time to justify its software and manufacturing cost?

== Closing Perspective

Future architecture is not one replacement for the CPU. It is a collection of cross-layer designs that place each computation where it can be performed efficiently while maintaining a usable and correct system.

The durable method is:

1. Characterize the workload and locate the true bottleneck.
2. Identify unnecessary movement, serialization, or generality.
3. Choose an execution and memory organization that removes that cost.
4. Rebuild the required software and correctness contracts around it.
5. Evaluate the complete system, including the costs introduced elsewhere.

The specific technologies will change; this method of workload-driven, data-aware, and tradeoff-conscious design remains useful.

