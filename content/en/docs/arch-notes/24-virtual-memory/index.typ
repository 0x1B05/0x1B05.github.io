#import "../../index.typ": *
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#import "../_diagrams/virtual-memory.typ": (
  shadow-vs-nested-paging, skylake-mmu-overview, software-vs-hardware-ptw,
  tlb-lookup-example, vipt-cache-lookup, virtualized-address-translation,
)
#import "../_diagrams/virtual-memory-flows.typ": (
  page-fault-dma-flow, page-fault-flow, page-hit-flow,
)
#show: series-chapter.with(
  arch-notes-series,
  route: "docs/arch-notes/24-virtual-memory/",
  title: "Virtual Memory",
)

== Why Virtual Memory?

The programmer sees a large private address space. The system maps virtual addresses to physical memory and automatically manages placement.

Virtual memory enables:
- A large apparent capacity backed by disk/SSD.
- Relocation of code and data.
- Multiple processes with separate address spaces.
- Sharing of code/data when desired.
- Protection and access control.

Without virtual memory, every program must know which physical addresses are free, fit into the installed DRAM, avoid other programs, and be rewritten or relocated when placement changes. Address indirection moves these responsibilities to coordinated hardware and operating-system mechanisms.

== Indirection and Mapping Decisions

Any virtual-memory design must answer four questions:

#three-line-table(
  columns: (1.2fr, 2.1fr, 2.35fr),
  inset: 5pt,
  align: left,
)[
  | *Question* | *Virtual-memory decision* | *Typical answer* |
  | :--------- | :------------------------ | :--------------- |
  | When to map? | Allocate on first touch, load time, or earlier | Demand paging with optional prefetch |
  | Where to place? | Select a physical frame | Any free frame because the page table provides full associativity |
  | What to replace? | Select a victim when DRAM is full | OS approximation of recency/frequency plus policy constraints |
  | Who manages it? | Divide mechanism and policy | MMU/TLB hardware plus OS page-fault handler |
]

Virtual memory works because most references hit in physical memory and exhibit locality. A page fault is extremely expensive, so the system uses large pages, fully associative placement, and sophisticated replacement rather than a simple direct mapping.

== Pages and Frames

Virtual address space is divided into fixed-size *pages*. Physical memory is divided into same-size *frames*. A virtual page maps to a physical frame. If an accessed page is not in memory, it resides on disk and causes a page fault.

A *page table* stores virtual-page to physical-frame mappings. Physical memory is a cache for pages stored on disk.

#three-line-table(
  columns: (1.45fr, 1.65fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Term* | *Meaning* | *Analogy* |
  | :---- | :------- | :------- |
  | Virtual page number (VPN) | High address bits | Cache block tag |
  | Page offset | Low address bits | Block offset; unchanged by translation |
  | Physical page number (PPN/PFN) | Frame selected by PTE | Physical tag |
  | Page table entry (PTE) | Mapping and permissions | Translation-cache line |
]

=== Physical Memory as a Cache

#three-line-table(
  columns: (1.35fr, 2.15fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Property* | *Hardware cache* | *Paged virtual memory* |
  | :--------- | :--------------- | :--------------------- |
  | Cached object | Cache block | Page |
  | Backing store | Lower cache/DRAM | SSD or disk |
  | Tag/mapping | Cache tag array | Page table |
  | Hit accelerator | Tag lookup | TLB caches PTEs |
  | Placement | Set constrained | Effectively any physical frame |
  | Miss handling | Mostly hardware | OS plus storage I/O |
  | Replacement state | Compact hardware policy | Rich OS policy and reference/dirty bits |
  | Miss latency | Tens to hundreds of cycles | Millions or more cycles |
]

The page table is analogous to the tag store, while DRAM frames are the data store. Unlike an ordinary cache tag array, the page table is itself stored in memory and can be paged, protected, cached, and walked hierarchically.

== Address Translation

The MMU splits a virtual address into VPN and offset, indexes the page table with the VPN, obtains the PPN, and concatenates PPN with the unchanged offset to form the physical address.

For page size `2^p` bytes:

- The low `p` virtual-address bits are the page offset.
- The remaining bits form the virtual page number.
- Translation replaces the VPN with a physical page number.
- The byte offset is copied unchanged because virtual and physical pages have the same size and alignment.

Example: a 16-bit virtual address, 1KB pages, and 8KB physical memory give a 10-bit offset, 6-bit VPN, and 3-bit PPN. Virtual address `0x1234` has VPN `4` and offset `0x234`. If PTE 4 maps to physical frame 6, the physical address is `6 * 0x400 + 0x234 = 0x1A34`.

The translation can end in three fundamentally different results:

1. *TLB hit*: the cached PTE directly supplies the PPN and permissions.
2. *TLB miss, resident page*: a page-table walk finds a present PTE, fills the TLB, and retries.
3. *Page fault or protection fault*: the PTE is absent or disallows the access, so the processor traps to software.

== Page Table Size

Where do we store it?
+ In hardware?
+ In physical memory? (Where is the PTBR?)
+ In virtual memory? (Where is the PTBR?)

How can we store it efficiently without requiring physical memory that can store all page tables?
- Idea: multi-level page tables
- Only the first-level page table has to be in physical memory
- Remaining levels are in virtual memory (but get cached in physical memory when accessed)

==== Page Table Access

Page Table Base Register && Page Table Limit Register

Page Table Base Register is part of a process’s context:
- Just like PC, status registers, general purpose registers, needs to be loaded when the process is context-switched in

With a 64-bit virtual address, 4 KB pages, and 4-byte PTEs, a flat page table would need `2^52` entries and `2^54` bytes. This is impractical.

Multi-level page tables organize the table hierarchically. Only needed lower-level tables are allocated. For an N-level page table, a translation may require N memory accesses, unless entries are cached.

In x86-64, CR3 points to the root and four levels (PML4, PDPT, PD, PT) translate 4 KB pages. Large pages use fewer levels.

If VPN is out of the bounds (exceeds PTLR) then the process did not allocate the virtual page => access control exception

=== Why Multi-Level Tables Save Space

Each non-leaf entry either points to a lower-level table or says that the covered virtual region has no mapping. A sparse address space allocates leaf tables only for populated regions. The tradeoff is latency: following one pointer per level serializes memory references on a TLB miss.

For the common four-level x86-64 arrangement with 4KB pages and 8-byte entries, each page-table page contains `4096 / 8 = 512 = 2^9` entries. A canonical 48-bit virtual address is divided as:

#three-line-table(
  columns: (1.3fr, 1fr, 1.25fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Field* | *Bits* | *Level* | *What the selected entry points to* |
  | :------ | :----- | :------ | :-------------------------------- |
  | VA 47:39 | 9 | PML4 | Page-directory-pointer table |
  | VA 38:30 | 9 | PDPT | Page directory, or a 1GB page |
  | VA 29:21 | 9 | PD | Page table, or a 2MB page |
  | VA 20:12 | 9 | PT | 4KB physical page |
  | VA 11:0 | 12 | Offset | Byte within the page |
]

CR3 contains the physical base of the root table and address-space control information. Each next-level address is formed from the PPN in the current entry plus the next 9-bit index.

=== Multiple Page Sizes

A leaf can appear before the last level:

- 4KB page: walk all four levels; 12 offset bits.
- 2MB page: the page-directory entry is a leaf; 21 offset bits.
- 1GB page: the PDPT entry is a leaf; 30 offset bits.

Larger pages increase TLB reach and shorten page walks, but waste memory through internal fragmentation, increase copy/migration cost, and require large aligned physical regions. Operating systems often promote and demote pages dynamically.

== Translation Lookaside Buffer(TLB)

*Page table accesses have temporal and spatial locality*
+ Memory accesses have temporal and spatial locality
+ Large page sizes better exploit spatial locality (KBs, MBs, GBs)
+ Consecutive instructions and loads/stores are likely to access same page

A TLB is a small hardware cache of page-table entries. It avoids page-table memory accesses on most translations.
+ Small: accessed in a few cycles
+ Typically 16 - 512 entries at level 1
+ Usually high associativity
+ > 90-99 % hit rates typical (depends on workload)
+ Reduces the number of memory accesses for most instruction fetches and loads/stores to only one TLB access

#three-line-table(
  columns: (1.3fr, 2fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *TLB field* | *Role* | *Analogy* |
  | :--------- | :---- | :------- |
  | VPN tag | Identifies the virtual page | Cache tag |
  | PPN data | Physical frame number | Cache data |
  | Valid/permission bits | Presence and access control | Status bits |
]

#figure(
  html.frame(tlb-lookup-example()),
  caption: [A two-entry fully associative TLB lookup example. ],
)

On a TLB miss, the system walks the page table and inserts a PTE. TLBs are small, so misses are inevitable. Better TLB management and prefetching reduce the cost.

*All issues we discussed in caching and prefetching lectures apply to TLBs*
+ Instruction vs. Data TLBs
+ Multi-level TLBs
+ Associativity and size choices and tradeoffs
+ Insertion, promotion, replacement policies
+ What to keep in which TLB and how to decide that
+ Prefetching into the TLBs
+ TLB coherence
+ Shared vs. private TLBs across cores/threads
+ …

=== Supporting Virtual Memory

Virtual memory *requires both HW+SW support*
- Page Table is in memory; it can be cached in special hardware structures called Translation Lookaside Buffers (TLBs)
- *OS & HW both know Page Table organization & structure (ISA)*

The hardware component is called the *MMU (memory management unit)*, which includes Page Table Base Register(s), TLBs, page walkers

It is the job of the software (e.g., the Operating System) to:
+ Populate page tables, decide what to replace in physical memory
+ Change the Page Table Base Register on context switch (to use the running thread’s page table)
+ Handle page faults and ensure correct virtual => physical mapping

==== Virtual Memory is Part of the ISA

Page size, page-table format, PTE permission bits, privilege levels, and page-table base registers are ISA-visible choices. x86-64 supports multiple page sizes and uses CR3 as the page-table base.

The ISA must also specify which faults are precise, how software invalidates translations, which PTE bits hardware sets, whether TLB misses are hardware- or software-managed, and the memory-ordering rules around page-table changes. An operating system cannot choose an arbitrary page-table format independently of the processor.

=== What Is in a Page Table Entry (PTE)?

Page table is the “tag store” for the physical memory data store: A mapping table between virtual memory and physical memory

PTE is the “tag store entry” for a virtual page in memory
- Need a *valid* bit => to indicate validity/presence in physical memory
- Need *tag* bits (PFN) => to support translation
- Need bits to support *replacement*
- Need a *dirty* bit to support “write back caching”
- Need *protection* bits to enable access control and protection

=== Page Hit

+ Processor sends the virtual address to the MMU.
+ The MMU fetches the PTE through the cache/memory hierarchy.
+ The present PTE shows that the page is resident in physical memory; this does not imply a TLB or cache hit.
+ The MMU forms the physical address and sends it to the L1 cache.
+ The memory hierarchy returns the requested data word to the processor.

#figure(
  html.frame(page-hit-flow()),
  caption: [Page-hit path. The page-table lookup returns a present PTE, so the MMU forms a physical address and the memory hierarchy returns the requested data.],
)

=== TLB miss

The TLB is small; it cannot hold all PTEs, So some translation requests will inevitably miss in the TLB, which must access memory to find the required PTE
- Called walking the page table
- Large performance penalty

Better TLB management & prefetching can reduce TLB misse

HW && SW can both handle TLB miss.

==== Hardware-Managed (e.g., x86)

- The hardware does the *page walk*
- The hardware fetches the PTE and inserts it into the TLB
  - If the TLB is full, the entry *replaces* another entry
- Done transparently to system software
- Can employ specialized structures and caches
  - E.g., page walkers and page walk caches

Advantages
+ No exception on TLB miss. Instruction just stalls
+ Independent instructions may execute and help tolerate latency
+ No extra instructions/data brought into caches

Disadvantages
+ Page directory/table organization is etched into the system: OS has little flexibility in deciding these

==== Software-Managed (e.g., MIPS)

- The hardware raises an exception
- The operating system does the *page walk*
- The operating system fetches the PTE
- The operating system inserts/evicts entries in the TLB

Advantages
+ The OS can define the page table oganization
+ More sophisticated TLB replacement policies are possible

Disadvantages
- Need to generate an exception à performance overhead due to pipeline flush, exception handler execution, extra instructions brought to caches

==== Page Replacement Algorithm

If physical memory is full (i.e., list of free physical pages is empty), which physical frame to replace on a page fault?

Modern system use approximation of LRU(e.g. CLOCK algorithm, easy to impl).And, more sophisticated algorithms to take into account “frequency” of use(E.g., the ARC algorithm)

The CLOCK algorithm *keeps a circular list of frames and a hand pointer to the last-examined frame in the list*; reference bits allow recently used pages to receive a second chance. For each candidate frame:
1. If its reference/accessed bit is 1, clear the bit and advance the hand.
2. If the bit is 0 and the frame is eligible, select it as a victim.
3. If dirty, schedule writeback before reuse.

CLOCK approximates recency without maintaining a precise total order over all frames. Multi-queue and working-set algorithms can distinguish hot, cold, file-backed, anonymous, and unevictable pages more accurately.

===== Cache versus Page Replacement

*Physical memory (DRAM) is a cache for disk* which is managed by system software via the virtual memory subsystem

Page replacement is similar to cache replacement. Page table is the “tag store” for physical memory data store. What is the difference?
+ Required speed of access to cache vs. physical memory
+ Number of blocks in a cache vs. physical memory
+ “Tolerable” amount of time to find a replacement candidate (disk versus memory access latency)
+ Role of hardware versus software

==== Page Fault

+ Processor sends the virtual address to the MMU.
+ The MMU fetches the PTE through the cache/memory hierarchy.
+ The present bit is zero, so the MMU raises a page-fault exception.
+ The handler identifies a victim and, if it is dirty, writes it to backing storage.
+ The handler reads the requested page into memory and updates its PTE.
+ The handler returns to the original process and restarts the faulting instruction.

#figure(
  html.frame(page-fault-flow()),
  caption: [Page-fault path. A non-present PTE traps to the OS; the handler optionally writes back a dirty victim, reads the demanded page, updates the PTE, and retries the faulting instruction.],
)

If a page is on disk rather than in physical memory:
- Page table entry indicates virtual page not in memory
- Access to such a page triggers a page fault exception
- OS exception handler invoked to move data from disk into memory
  - Other processes can continue executing
  - OS has full control over page placement

===== Servicing a Page Fault

1. Processor signals I/O controller
  - Read block of length P starting at disk address X and store starting at memory address Y
2. Disk-to-memory read occurs
  - Direct Memory Access (DMA)
  - Under control of I/O controller
3. Controller signals completion
  - Interrupts processor
  - OS resumes suspended process

#figure(
  html.frame(page-fault-dma-flow()),
  caption: [Servicing a page fault with DMA. The processor programs the transfer, the DMA engine moves the page from storage directly into its destination frame, and an interrupt reports completion.],
)

== Protection

- *Multiple programs (i.e., processes) run concurrently*
  - Each process has its own page table
  - Each process can use its entire virtual address space without worrying about where other programs are
- A process can only access physical pages mapped in its page table – cannot overwrite memory of another process
  - Provides *protection and isolation* between processes
  - Enables *access control mechanisms per page*

=== Page-Level Access Control (Protection)

Not every process is allowed to access every page
- E.g., need supervisor (i.e., kernel) level privilege to access system pages
- E.g., may not be able to execute “instructions” in some pages

Idea: *Store access control information* on a page basis in the process’s page table

Enforce access control at the same time as translation(In fact, access control takes priority. If don't have access, forget about the translation)

Virtual memory therefore has two functions:
- Address translation, providing the illusion of a large memory.
- Access protection and isolation.

Extend Page Table Entries (PTEs) with permission bits, check bits on each access and during a page fault: If violated, generate exception (Access Protection exception)

Protection is only as trustworthy as the underlying hardware state. If a DRAM disturbance flips a PTE bit, an attacker may change a physical mapping or permission without writing the page through the MMU. RowHammer therefore connects circuit reliability directly to virtual-memory isolation.

=== x86 Page Table Entries

An x86-64 PTE contains a physical page number and status/protection flags, such as valid/present, writable, user, executable-disable, accessed, and dirty. The page offset is unchanged by translation.

#three-line-table(
  columns: (1.25fr, 1.6fr, 2.5fr),
  inset: 5pt,
  align: left,
)[
  | *Field* | *Meaning* | *Use* |
  | :------ | :-------- | :---- |
  | Present | Translation is resident/usable | Zero can encode nonresident or invalid state for the OS |
  | R/W | Writes permitted | Combines with upper-level permissions |
  | U/S | User access permitted | Separates user and supervisor mappings |
  | PPN | Physical frame or next-table base | Meaning depends on whether entry is a leaf |
  | Accessed | Page/entry was referenced | Replacement and aging |
  | Dirty | Leaf page was written | Decide whether victim needs writeback |
  | XD/NX | Instruction fetch prohibited | Data/executable separation |
  | Page-size bit | Entry is a large-page leaf | End walk at PD or PDPT level |
]

Reserved-bit violations cause faults. Software-defined bits can store OS metadata only where the ISA permits; treating arbitrary unused-looking bits as free can break on newer processors.

=== Food for Thought: What If?

The hardware is unreliable and someone can flip the access protection bits such that a user-level program can gain supervisor-level access (i.e., access to all data on the system) by flipping the access control bit from user to supervisor!

RowHammer(repeatedly activating a row before memory gets refreshed can flip bits in neighboring victim rows) is one can *predicatably induce errors in most dram memory chips*.

- The root of security and trust is at the very low levels…
  - in the hardware itself
  - RowHammer, Spectre, Meltdown are recent key examples…
- What should we assume the hardware provides?
- How do we keep hardware reliable?
- How do we design secure hardware?
- How do we design secure hardware with high performance, high energy efficiency, low cost, convenient programming?

==== A Simple Program Can Induce Many Errors

```asm
#    _______
# X->_______
#    _______
# Y->_______

loop:
  mov (X), %eax
  mov (Y), %ebx
  clflush (X)
  clflush (Y)
  mfence
  jmp loop
```

+ Avoid *cache hits*: flush X from cache
+ Avoid *row hits* to X: Read Y in another row from cache

== Virtual Memory in Virtualized Environments

Virtualized environments(e.g. Virtual machines) need to have an additional level of address translation

`guest virtual -> guest-physical(or host-virtual) -> host physical`

The guest OS manages guest page tables; the hypervisor/host manages the mapping to host physical memory. Nested or extended page tables and TLBs cache the combined translation.

#figure(
  html.frame(virtualized-address-translation()),
  caption: [Two-stage address translation in a virtual machine. The guest OS maps a guest virtual address to a guest physical address; the hypervisor maps that intermediate address to a host physical frame. A TLB can cache the combined GVA-to-HPA result.],
)

There are two main implementation strategies:

=== Shadow Paging

The hypervisor constructs a shadow page table that directly maps guest virtual addresses to host physical frames. Hardware walks this ordinary table, so a TLB miss has one page walk. However, the hypervisor must intercept guest page-table updates and keep the shadow mapping synchronized, which is expensive and complex.

=== Nested Paging

Hardware first walks the guest page table to translate guest virtual to guest physical, then uses a nested/extended page table to translate each guest-physical address to host physical. The guest OS can manage its own tables with fewer traps, but a miss can require many dependent memory references.

#figure(
  html.frame(shadow-vs-nested-paging()),
  caption: [Shadow paging pre-composes GVA-to-HPA mappings into one hardware-visible page table but requires the hypervisor to synchronize it. Nested paging keeps guest and host mappings independent, but a TLB miss performs a two-dimensional walk because every guest-PTE address is itself a GPA.],
)

For an `N`-level guest table and `M`-level nested table, each guest PTE address itself needs an `M`-level translation followed by the guest-PTE read. A naive walk therefore requires up to `N*(M+1) + M = N*M + N + M` translation-related memory references before the final data access. With four guest levels and four nested levels, this is `5 + 5 + 5 + 5 + 4 = 24` references, or 25 when the final demand-data access is included. TLBs, combined translations, page-walk caches, and caching ordinary PTEs in the data hierarchy are essential.

Nested paging also introduces two page sizes and two permission checks. The effective access must be allowed by both guest and host mappings, and a fault must be attributed to the correct layer.

== Address Translation and Caching

Translation can occur before or after accessing the L1 cache:
- Virtually addressed cache: use VA for lookup.
- Physically addressed cache: translate first, then use PA.
- Virtually indexed, physically tagged (VIPT): index with page-offset VA bits while checking a physical tag from the TLB.

Virtually addressed caches face:
- *Homonyms*: the same VA maps to different PAs in different processes.
  - can return another process's data unless tags include an ASID or the cache is flushed on a context switch.
- *Synonyms*: different VAs map to the same PA, for example through shared pages.
  - can create two cache lines for one physical block; a write through one alias leaves the other stale unless the cache detects/forbids duplicates.

VIPT caches avoid synonyms when the index bits plus block-offset bits fit within the page offset. This implies: `cache size <= page size * associativity`

Solutions include limiting cache size, searching all possible indices on a write, and page coloring, where the OS constrains page placement so VA and PA indices agree.

=== PIPT, VIVT, and VIPT

#three-line-table(
  columns: (1.05fr, 1.8fr, 1.85fr, 1.7fr),
  inset: 5pt,
  align: left,
)[
  | *Cache* | *Lookup order* | *Advantage* | *Problem* |
  | :------ | :------------- | :---------- | :-------- |
  | PIPT | Translate, then physical index/tag | Simple coherence and no aliases | TLB latency precedes cache lookup |
  | VIVT | Virtual index and virtual tag | Cache can start immediately | Homonyms, synonyms, context-switch handling |
  | VIPT | Virtual index in parallel with TLB; physical tag comparison | Hides much of TLB latency | Index must stay within page offset or aliases need handling |
]

#figure(
  html.frame(vipt-cache-lookup()),
  caption: [A VIPT L1 starts TLB lookup and cache-set access in parallel.],
)

For a cache of capacity $C$, associativity $A$, line size $B$, and page size $P$: $"sets" = C / (A B)$, and VIPT avoids using translated bits for set selection when $log("sets") + log(B) <= log(P)$, equivalently $C <= A P$.

=== Translation before Coherence

Coherence protocols normally operate on physical addresses. A virtually addressed private cache must translate or otherwise canonicalize an address before communicating coherence requests, and synonyms must not create multiple independently coherent copies in one core.

== Modern MMU Organization

The Memory Management Unit (MMU) is responsible for resolving address translation requests
- One MMU per core (usually)

MMU typically has three key components:
+ *TLB* that cache recently-used virtual-to-physical translations (PTEs)
+ *Page Table Walk Caches* that offer *fast access to the intermediate levels of a multi-level page table*
+ *Hardware Page Table Walker* that sequentially accesses the different levels of the Page Table to fetch the required PTE

=== Intel Skylake: MMU

#figure(
  html.frame(skylake-mmu-overview()),
  caption: [Skylake's per-core MMU hierarchy. Separate L1 instruction and data TLBs share the logical unified L2 TLB tier; an L2 miss invokes the hardware page-table walker, whose page-walk caches retain intermediate page-table entries.],
)

==== L1 Data TLB

Separate L1 Data TLB structures for 4KB, 2MB, and 1GB pages. During a translation request, all three L1 TLBs are looked up in parallel
- *4KB*: 64-entry, 4-way, 1 cycle access, 9 cycle miss(256KB total)
- *2MB*: 32-entry, 4-way, 1 cycle access, 9 cycle miss(64MB total)
- *1GB*: 4 entry, fully-associative(4GB total)

Virtual-to-physical mappings are inserted in the corresponding TLB after a TLB miss

==== L2 Unified TLB: Accessing the TLB

L2 Unified TLB caches translations for both instr. and data(private per individual core)

2 separate L2 TLB structures for 4KB/2MB and 1GB pages
- 4KB/2MB: 1536-entry, 12-way, 14 cycle access, 9 cycle miss
- 1GB: 16-entry, 4-way, 1 cycle access, 9 cycle miss penalty

Challenge: How can the L2 TLB support both 4KB and 2MB pages using a single structure? (Not enough publicly available information for Intel Skylake)

The 4KB/2MB structure of the L2 TLB is probed in 2 steps

+ Step 1: Assume the page size is 4KB, calculate the index bits and access the L2 TLB
  - If the tag matches, it is a hit. If the tag does not match, go to Step 2.
+ Step 2: Assume the page size is 2MB, re-calculate the index and access the L2 TLB.
  - If the tag matches, it is a hit. If the tag does not match, it is an L2 TLB miss.

General algorithm: *Re-calculate index and probe TLB for all remaining page sizes*(do it many times to get very high levels of associativity or support any number of pages sizes)

Pros:
+ Simple and practical implementation
Cons:
+ Varying L2 TLB hit latency (faster for 4KB, slower for 2MB)
+ Slower identification of L2 TLB Miss as all page sizes need to be tested

Potential Optimizations:
+ *Parallel Lookup*: Look up for 4KB and 2MB pages in parallel
+ *Page Size Prediction*: Predict the probing order

Tradeoffs are similar to “associativity in time” (also called pseudo-associativity)

=== Hardware Page-Table Walker

A per-core hardware component that *walks the multi-level page table to avoid expensive context switches & SW handling*

HW PTW consists of 2 components:
- A state machine that is designed to be aware of the architecture’s page table structure
- Registers that keep track of outstanding TLB misses

+ PTW accesses the CR3 register that maintains information about the physical address of the root of the page table (PML4)
+ PTW concatenates the content of CR3 with the first 9 bits of the virtual address

Pros:
+ Avoids the need for context switch on TLB miss
+ Overlaps TLB misses with useful computation
+ Supports concurrent TLB misses
Cons:
+ Hardware area and power overheads
+ Limited flexibility compared to software page table walk

#figure(
  html.frame(software-vs-hardware-ptw()),
  caption: [Software- versus hardware-managed page-table walks. A software TLB miss traps into a handler and can delay the next access; a hardware walker performs the walk without a context switch, allowing an independent access to overlap the miss latency.],
)

== Page-Walk Caches

- Page Walk Caches *cache translations from non-leaf levels of a multi-level page table* to accelerate page table walks
- Page Walk Caches are low-latency caches that *provide faster access to the page table levels*
  - compared to accessing the regular cache/memory hierarchy for every page table walk

