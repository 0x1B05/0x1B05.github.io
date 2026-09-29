#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#import "../_diagrams/memory-organization.typ": (
  dram-bank-operation, dram-system-hierarchy, memory-array-organization,
  rank-cache-block-transfer, sram-dram-addressing,
)
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/15-memory-organization/",
  title: "Memory Organization and Technology",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/15-memory-organization/")

= Memory Organization and Technology

#series-navbar("en", nav)

#doc-toc("en")


== Memory Is Critically Important

Every computing system must provide *computation*, *communication*, and *storage*. Modern systems devote a large fraction of both the processor die and the platform to storage and data movement: register files, SRAM caches and scratchpads, DRAM, nonvolatile storage, controllers, and interconnects.

Memory affects much more than capacity:
- *Performance*: pipeline loads stall, OoO windows fill behind long-latency misses, VLIW schedules wait for memory, and SIMD/GPU execution needs enough banking and bandwidth.
- *Energy*: moving data through a hierarchy can cost orders of magnitude more energy than operating on it. A distant memory access can consume roughly 100--1000 times the energy of a complex arithmetic operation.
- *Reliability and security*: stored bits can fail because of retention loss, manufacturing variation, radiation, wear, and disturbance effects such as DRAM RowHammer.
- *Cost and scalability*: memory capacity, bandwidth, pins, packaging, cooling, and controller complexity shape the whole system.
- *Predictability and QoS*: requests contend for shared banks, channels, and buses, so latency depends on both the address and other traffic.

Data-intensive workloads include machine learning, genomics, analytics, databases, graph processing, and datacenter services. Their data sets and data-generation rates grow faster than processor throughput. The bottleneck is therefore often moving data to the computation rather than performing the computation itself.

This observation motivates larger and more parallel memory systems, 3D-stacked memory, specialized data-movement engines, and *processing near or inside memory*.

=== Reliability and Security Example: RowHammer

Repeatedly activating and precharging an aggressor row can disturb nearby victim rows and induce bit flips in data software never addressed, turning a circuit failure into a security problem. Defenses include stronger refresh, access-rate tracking, physical isolation, and error correction, each with cost or coverage tradeoffs.

== Virtual versus Physical Memory

The programmer names data using a *virtual address space* and can act as though memory is very large and private. The installed *physical memory* is smaller. Hardware and system software cooperatively translate virtual addresses to physical addresses and manage physical frames transparently.

Virtual memory makes programming, protection, sharing, and relocation easier, but requires an indirection and a mapping data structure. When physical memory is insufficient, the system can use a larger backing store, normally an SSD or disk. This lecture first studies the physical memory subsystem while temporarily ignoring address translation.

== Ideal Memory

An ideal memory would have:
- Zero access latency.
- Infinite capacity.
- Zero cost.
- Infinite bandwidth for parallel accesses.
- Zero energy.

No real technology satisfies all requirements.

The goals conflict. Larger arrays have longer wires and more cells to select; faster cells occupy more area and cost more; more bandwidth needs additional banks, channels, pins, frequency, or 3D integration. Real systems therefore combine technologies and organize them hierarchically.

== Storage Technology Spectrum

#three-line-table(
  columns: (1.25fr, 1.15fr, 1.35fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *Technology* | *Cell* | *Volatility* | *Main tradeoff* |
  | :----------- | :----- | :----------- | :-------------- |
  | Flip-flop/latch | tens of transistors/bit | volatile | Fastest, but very low density and expensive |
  | SRAM | normally 6T/bit | volatile | Fast and logic-process compatible; lower density |
  | DRAM | 1T1C/bit | volatile | Dense and inexpensive; slower, destructive read, refresh required |
  | PCM / STT-MRAM / RRAM | resistive state | nonvolatile | Dense and persistent; writes, energy, endurance, and process maturity vary |
  | NAND flash | one transistor can store multiple bits | nonvolatile | Very dense; page reads/programs, block erases, limited endurance |
  | Disk / tape | magnetic medium | nonvolatile | Very high capacity and low cost/bit; very high access latency |
]

== Memory Arrays

The purpose of a memory array is to store many bits compactly while exposing only a small number at a time. It contains:
- A two-dimensional array of one-bit storage cells.
- Address-selection logic, normally a row decoder and wordlines.
- Bitlines, sensing circuitry, and column-selection logic for reading or writing data.

An $M$-bit value can be read or written at each unique $N$-bit address. An array with $N$ address bits and $M$ data bits has:

$ "depth" = 2^N " rows" $

$ "width" = M " bits per row" $

$ "capacity" = 2^N times M " bits" $

For example, a $2^2 times 3$ array has 4 rows and stores one 3-bit word per row. A $1024 times 32$ array has ten address bits, 1024 words, and 32 bits per word.

#figure(
  html.frame(memory-array-organization()),
  caption: [Organization of a two-dimensional memory array. The decoder activates one wordline; the selected cells drive the column bitlines and readout circuitry.],
)

The address decoder activates exactly one wordline. Each selected cell's access transistor connects its storage node to a bitline. All cells on the selected row are exposed together, after which column logic returns only the requested subset. Restricting each access to one row or word makes the physical implementation much denser than giving every bit an independent external connection.

=== Generic Read Sequence

1. Latch and split the address into row and column portions.
2. Decode the row address and drive one wordline.
3. Selected cells perturb or drive their bitlines; the entire physical row is sensed.
4. Sense amplifiers amplify the row, and a column decoder/multiplexer selects the requested bytes.
5. Precharge the bitlines so the array is ready for a later access.

*Access latency* is the time until requested data becomes available. *Cycle time* is the minimum time before the array can begin another access; it also includes recovery such as precharge and can therefore exceed access latency.

== Building Larger Memories

Simply enlarging one array increases decoder fanout, wordline/bitline capacitance, sensing time, energy, and contention. Large memories are therefore built from many smaller arrays connected through hierarchical buses and multiplexers.

A useful DRAM capacity hierarchy is:

`channel -> DIMM -> rank -> chip -> bank -> subarray/mat -> row/column`

The hierarchy has two roles:
- Keep each physical array small enough for reasonable latency and energy.
- Create independently operable structures so multiple requests can overlap.

== Interleaving and Banking

A monolithic array has high latency and only one active access path. *Banking* divides it into smaller, independently controlled arrays. Requests to different banks can be activated and serviced concurrently or pipelined in consecutive cycles.

Banks normally share command, address, and data buses to reduce pins and wiring. Thus internal bank operations may overlap even when completed transfers must take turns on a shared data bus. An `N`-bank memory can sustain up to `N` concurrent bank operations only when requests map to different banks and no other shared resource becomes the bottleneck.

The address-to-bank mapping is therefore a first-class design decision:
- *Low-order interleaving* places consecutive blocks in consecutive banks, providing bandwidth for sequential access.
- Mapping selected higher address bits to the bank can preserve row locality.
- XOR/hash-based mappings can spread regular access patterns but make mapping less transparent.
- Requests to the same bank serialize and can cause a *bank conflict* even if other banks are idle.

#figure(
  html.frame(dram-system-hierarchy()),
  caption: [Generalized memory structure. Each panel expands the highlighted object: a channel connects DIMMs, a DIMM contains ranks, a rank combines chips, a chip contains banks, and each bank is built from subarrays.],
)

The figure separates *activation granularity* from *I/O transfer granularity*. In the slide example, `ACTIVATE` moves a full 2KB row from the selected bank/subarray into its row buffer. A column command then contributes 8 bits from each x8 chip; eight chips in the selected rank combine those slices into a 64-bit (8-byte) channel transfer. Therefore a 64-byte cache block needs eight such transfers. A DIMM does not add the widths of its ranks: chip-select enables one rank at a time on the shared channel.

3D stacking places memory dies close to or above logic dies. Short, wide vertical connections can provide much more bandwidth than a conventional off-chip channel, but thermal constraints, cost, yield, and power delivery remain important.

== The DRAM Subsystem: Top-Down

#three-line-table(
  columns: (1.25fr, 2fr, 2.35fr),
  inset: 5pt,
  align: left,
)[
  | *Level* | *What it contains* | *What is shared or parallel* |
  | :-------- | :---------------- | :---------------------------- |
  | Channel | DIMMs connected to one memory-controller interface | Independent channels can transfer in parallel; devices on one channel share buses |
  | DIMM | A module carrying DRAM chips, often on both sides | Usually one or more ranks |
  | Rank | A set of chips selected together | Chips operate in lockstep and jointly provide the channel data width |
  | Chip | Multiple banks and shared chip-level I/O | Banks provide internal parallelism but share chip pins |
  | Bank | Rows, a row buffer, and column-selection logic | One open row per bank in the simple model; banks operate independently |
  | Subarray/mat | Cell arrays, local row decoder, bitlines, sense amplifiers | Shorter local wires; some designs exploit subarray-level parallelism |
]

The memory controller converts each physical address into channel, rank, bank, row, and column fields. It issues commands, observes timing constraints, schedules competing requests, performs refresh, and decides when each shared bus can be used.

=== Channel, DIMM, and Rank

A channel carries command/address signals from the controller and data in both directions. Multiple DIMMs or ranks can attach to it. Chip-select signals choose a rank; normally only the selected rank drives the shared data bus.

A common x64 rank uses eight x8 DRAM chips. Every chip receives the same command and row/column address, but contributes a different eight-bit slice:

`chip 0 -> data[7:0], chip 1 -> data[15:8], ..., chip 7 -> data[63:56]`

The rank therefore transfers 64 bits, or 8 bytes, per I/O transfer. ECC DIMMs often add another chip to carry check bits.

=== Chip, Bank, and Row Buffer

A chip contains several banks. A bank is logically a row-column array, but physically it is composed of subarrays with local row decoders, cell arrays, and sense amplifiers. The sense amplifiers also form the bank's *row buffer*.

The example in the slides uses a bank with roughly 32K rows, a 2KB row, and a one-byte column from one x8 chip. Activating a row moves the entire 2KB row into the row buffer, even though a later column command exports only a small part of it.

At most one row is open in a bank in the basic abstraction. Different banks can have different rows open simultaneously.

== DRAM Bank Operation

#figure(
  html.frame(dram-bank-operation()),
  caption: [The three-command DRAM access sequence. ACTIVATE opens a row in the sense amplifiers, READ/WRITE selects columns, and PRECHARGE closes the row and restores the bitlines.],
)

=== ACTIVATE: Open a Row

`ACTIVATE` supplies a row address. The row decoder raises one wordline, every cell on that row shares charge with a bitline, and the sense amplifiers detect and amplify the tiny voltage differences. The amplified row remains in the row buffer. Because a DRAM read disturbs the capacitor, sensing also restores the cells' values.

=== READ or WRITE: Select Columns

With a row open, `READ` or `WRITE` supplies a column address. The column mux moves only the selected burst of bytes between the row buffer and bank I/O. Several column commands may access the same open row without activating it again.

=== PRECHARGE: Close the Row

`PRECHARGE` writes back/restores the open row as needed and equalizes the bitlines, leaving the bank ready for another `ACTIVATE`. Precharge is recovery work: it consumes time and energy without directly returning requested data.

=== Row-Buffer Locality

#three-line-table(
  columns: (1.15fr, 2fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *State* | *Required command sequence* | *Consequence* |
  | :-------- | :-------------------------- | :------------ |
  | Empty/closed | `ACTIVATE -> READ/WRITE` | Must first open the requested row |
  | Row-buffer hit | `READ/WRITE` | Requested row is already open; lowest latency and energy |
  | Row-buffer conflict | `PRECHARGE -> ACTIVATE -> READ/WRITE` | A different row is open; highest latency and extra energy |
]

For the access stream `(row 0, col 0)`, `(row 0, col 1)`, `(row 0, col 85)`, `(row 1, col 0)`, the first access opens row 0, the next two are row hits, and the final access conflicts with the open row. A memory scheduler often prioritizes row hits for throughput, but doing so can hurt fairness or latency predictability.

== Example: Transferring a 64-Byte Cache Block

#figure(
  html.frame(rank-cache-block-transfer()),
  caption: [A 64-byte block maps through one channel and DIMM to a selected rank. In every 8-bit-I/O chip, the same bank, row, and column are selected; the chips contribute separate 8-bit lanes to each 8-byte transfer, and eight consecutive column reads deliver the complete block.],
)

Suppose a 64-byte cache block maps to one channel, rank, bank, and row. Each x8 chip contributes one byte per transfer, so the eight chips together provide 8 bytes. The rank must perform eight I/O transfers and read eight consecutive column positions to return all 64 bytes: $(64 B) / (8 " B per transfer") = 8 " transfers"$

The row activation moves much more data internally into every chip's row buffer than crosses the channel. This mismatch is why row-buffer locality, burst transfers, and cache-block size strongly affect bandwidth and energy.

== Memory Technology: SRAM and DRAM

=== SRAM Cell

Static RAM normally stores one bit in a 6-transistor cell:
- Four transistors form two cross-coupled inverters. Positive feedback retains the bit as long as power is supplied.
- Two access transistors connect the two internal nodes to complementary bitlines when the wordline is asserted.
- Differential sensing is fast, reading is non-destructive, and no refresh is required.

SRAM is compatible with ordinary logic fabrication but has low density and high cost per bit. It is therefore used for register files, caches, queues, and scratchpads rather than large main memory.

=== DRAM Cell

Dynamic RAM stores one bit using one access transistor and one capacitor (`1T1C`). The wordline connects the capacitor to a bitline; the capacitor's charged or discharged state represents the bit.

The capacitor is tiny and cannot directly drive external logic. Before access, the bitline is precharged to an intermediate voltage. Connecting the cell creates only a small voltage deviation; a cross-coupled sense amplifier drives that deviation to a full 0 or 1 and restores the cell.

DRAM has two kinds of data loss:
- *Destructive read*: charge sharing perturbs the cell, so the sense amplifier must regenerate its value during every activation.
- *Retention loss*: leakage gradually discharges the capacitor even when it is not accessed.

The DRAM controller must therefore refresh every row within the retention interval, typically on the order of tens of milliseconds. Refresh consumes bandwidth, latency, and energy and can temporarily make banks unavailable.

=== SRAM/DRAM Read Timing

Both technologies decode a row, drive a wordline, sense the selected bitlines, select columns, and precharge. The important differences are:
- SRAM cells actively drive differential bitlines and retain their state after sensing.
- DRAM cells only perturb precharged bitlines; sense amplifiers must both amplify and restore the row.
- In SRAM, access latency is dominated largely by wordline and bitline delay. Cycle time also includes precharge.
- In DRAM, activation, sensing/restoration, column access, and precharge are exposed as longer, constrained phases.

=== Address Delivery: SRAM versus DRAM

An SRAM macro normally receives the complete address at once. For an array with `2^n` rows and `2^m` column positions, the `n+m` address bits are available concurrently: `n` bits select one wordline through the row decoder while `m` bits control the column mux. The row and column paths can therefore begin in the same address phase.

Commodity DRAM reduces package pin count by *multiplexing* row and column addresses onto the same external address pins. The controller first supplies the bank and row with an `ACTIVATE` command; the row-address state is captured on the row-address-strobe phase traditionally called *RAS*. Later, a `READ` or `WRITE` supplies the bank and column; the column state is captured on the phase traditionally called *CAS*.

#figure(
  html.frame(sram-dram-addressing()),
  caption: [SRAM presents row and column address fields together. DRAM reuses its address pins: the RAS/ACTIVATE phase selects and opens a row, then the CAS/READ-WRITE phase selects columns from the sensed row.],
)

`RAS` and `CAS` are useful conceptual names even though modern synchronous DRAM encodes operations as commands rather than exposing the simple legacy waveforms shown in older asynchronous interfaces. Bank-select bits and burst details are omitted from the simplified diagram. The essential distinction remains: SRAM exposes a direct full-address lookup, whereas DRAM separates row activation from later column transfers.

#three-line-table(
  columns: (1.25fr, 2fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Property* | *SRAM* | *DRAM* |
  | :----------- | :----- | :----- |
  | Cell | typically 6T | 1 transistor + 1 capacitor |
  | Access | faster, non-destructive | slower, destructive sensing followed by restore |
  | Density/cost | lower density, higher cost/bit | higher density, lower cost/bit |
  | Refresh | not required while powered | periodic refresh required |
  | Manufacturing | compatible with logic process | capacitor requires specialized integration |
  | Typical role | registers, caches, scratchpads | main memory and large buffers |
]

== Emerging and Nonvolatile Memories

=== Charge versus Resistive Storage

Charge memories such as DRAM and flash write by storing charge `Q` and read by detecting a voltage `V`. Resistive memories write by applying current and read by detecting resistance `R`.

- *Phase-change memory (PCM)* changes chalcogenide material between a high-resistance amorphous state and a low-resistance crystalline state. It is dense and nonvolatile, but writes require heating/cooling, consume more energy, are slower, and wear cells.
- *STT-MRAM* changes magnetic polarity using current; resistance depends on the relative magnetic state.
- *RRAM/ReRAM/memristive memory* changes an atomic or conductive-filament structure; resistance depends on that structure.

PCM illustrates the general hybrid-memory problem. A pure PCM main memory needs mechanisms to tolerate slower writes, higher write energy, and limited endurance. A DRAM+PCM system needs policies for placement, migration, wear, and deciding which technology should hold each page or block.

=== Flash Memory and SSDs

NAND flash is dense, nonvolatile, and inexpensive, but it has asymmetric operations: data is read and programmed in pages, erased in larger blocks, and cells endure only a limited number of program/erase cycles.

An SSD therefore needs much more than raw flash chips. Its controller provides:
- A host interface and request queues.
- Logical-to-physical address mapping in the flash translation layer.
- DRAM buffers and metadata storage.
- Parallel scheduling across channels, packages, dies, and planes.
- Error correction, scrambling, bad-block management, wear leveling, and garbage collection.

These mechanisms make flash appear block-addressable and reliable, but they also create variable latency, write amplification, and background traffic.

== Memory-System Perspective

The memory system must balance cost, latency, bandwidth, parallelism, power, energy, reliability, and security. Improving one metric can worsen another: larger rows improve locality when hits occur but waste more activation energy; aggressive row-hit scheduling raises throughput but can delay old requests; more banks improve parallelism but add area and control complexity.

Memory behavior also shapes every execution model: pipelines stall on dependent loads; OoO windows and fine-grained multithreading tolerate latency; VLIW compilers schedule memory and disambiguate banks; SIMD/GPU machines need conflict-free banking and bandwidth; systolic arrays need high reuse and a sustained data supply.

Processing-in-memory and near-memory acceleration perform selected operations where data is stored. They can improve bandwidth and energy efficiency, but raise questions about programmability, coherence, consistency, protection, reliability, and which computations are worth moving.


#series-navbar("en", nav)
