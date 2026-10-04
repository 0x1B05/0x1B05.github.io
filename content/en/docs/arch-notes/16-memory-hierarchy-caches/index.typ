#import "../../index.typ": *
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#import "../_diagrams/cache.typ": (
  cache-hit-data-path, cache-placement-organizations,
)
#show: series-chapter.with(
  arch-notes-series,
  route: "docs/arch-notes/16-memory-hierarchy-caches/",
  title: "Memory Hierarchy and Caches",
)

== The Fundamental Problem

Ideal memory requirements oppose one another:
- Bigger is slower because locating data takes longer.
- Faster memory is more expensive in monetary cost and chip area.
- Higher bandwidth requires more banks, ports, channels, frequency, or faster technology.

The hierarchy combines progressively larger and slower levels so that *most data used by the processor remains in fast levels*.

#three-line-table(
  columns: (1.45fr, 1.25fr, 1.25fr, 1.35fr),
  inset: 5pt,
  align: left,
)[
  | *Device* | *Capacity* | *Latency* | *Role* |
  | :------ | :-------- | :------- | :---- |
  | Register/SRAM | tiny to MB | sub-ns to ns | Closest to the pipeline |
  | DRAM | GB | about 50 ns | Main memory |
  | PCM/NVM | GB to TB | hundreds of ns to us | Dense persistent storage |
  | Flash | GB to TB | tens of us | Solid-state storage |
  | Disk | TB | about 10 ms | Large backing store |
]

== Locality

A recent reference predicts the near future:

- *Temporal locality*: if a location was used recently, it is likely to be used again soon. Loop instructions, induction variables, accumulators, stack frames, and repeatedly used array elements exhibit temporal locality.
- *Spatial locality*: if a location was used, nearby locations are likely to be used soon. Sequential instruction fetch and traversal of contiguous arrays exhibit spatial locality.

A cache exploits temporal locality by retaining a referenced block and spatial locality by fetching an entire block containing neighboring bytes. A block is useful only if enough of its bytes are reused before eviction; blindly increasing block size can fetch data the program never touches.

Locality is a property of an access stream over a time interval, not a permanent property of an address. A phase change can replace one working set with another, and two interleaved streams can destroy each other's locality even when each stream is regular in isolation.

=== Working Set

The *working set* is the set of blocks referenced during a chosen recent interval. If it fits in a cache and placement conflicts are limited, most references can hit. If it exceeds effective capacity, useful blocks are repeatedly displaced and later refetched.

Working-set size changes across program phases. This is why a larger cache may greatly help one application, saturate early for another, and provide almost no benefit for a streaming workload with no reuse.

== Cache Hierarchy

The first-level cache is tightly integrated into the pipeline, so it must be small and fast. Larger outer caches can trade latency for capacity. First-level instruction and data caches are usually split; outer caches are usually unified.

Data movement can be managed automatically by a cache or explicitly by software through a scratchpad:

#three-line-table(
  columns: (1.25fr, 2.1fr, 2.1fr),
  inset: 5pt,
  align: left,
)[
  | *Property* | *Hardware cache* | *Scratchpad / local memory* |
  | :--------- | :--------------- | :-------------------------- |
  | Placement | Address mapping and hardware policy | Compiler/program explicitly transfers and places data |
  | Replacement | Automatic, normally transparent | Software decides when storage is reused |
  | Strength | General-purpose and easy to program | Predictable capacity and data movement; no tags |
  | Weakness | Misses, metadata, pollution, and policy uncertainty | Requires mapping, synchronization, and portable software support |
]

Many GPUs allow a physical SRAM budget to be partitioned between L1 cache and software-managed shared memory. This exposes the locality-management choice to software rather than making cache organization purely microarchitectural.

== Recursive Latency

At hierarchy level i, $t_i$ is intrinsic access time and $T_i$ is perceived access time. Except at the outermost level, a miss adds the perceived latency of the next level:

$T_i = (1−m_i)t_i+m_i(t_i+T_(i+1)) = t_i + m_i times T_(i+1)$

Here $m_i$ is the *local* or conditional miss rate among requests that actually reach level i. For two cache levels and memory,

$ T_1 = t_1 + m_1 (t_2 + m_2 t_3) $

The fraction of original L1 requests that reach memory is the *global* miss rate $m_1 m_2$, not $m_2$ alone. An outer cache sees a stream already filtered by inner levels, so its locality and best management policy can differ.

=== AMAT Definitions

When *miss penalty* excludes the lookup already paid at the current level,

$ "AMAT" = t_("hit") + m times p_("miss") $

When *total miss latency* includes that lookup, the equivalent weighted form is

$ "AMAT" = h times t_("hit") + m times t_("miss,total") $

where $h=1-m$. Mixing the two definitions double-counts or omits hit lookup time, so every calculation must say which convention it uses.

AMAT is an average service metric. Execution time also depends on whether misses overlap, whether they are on the critical path, queueing, and how much independent work the processor can execute.

=== Pentium 4 Latency Example

The slides use a 3.6GHz Pentium 4 example with a 4-cycle integer L1 hit, an 18-cycle L2 hit, and roughly 180-cycle main-memory access. With $T_2=18+m_2 dot 180$ and $T_1=4+m_1 T_2$:

#three-line-table(
  columns: (1fr, 1fr, 1.25fr, 1.25fr),
  inset: 5pt,
  align: center,
)[
  | *$m_1$* | *$m_2$* | *$T_2$* | *$T_1$* |
  | :------ | :------ | :------ | :------ |
  | 0.10 | 0.10 | 36 cycles | 7.6 cycles |
  | 0.01 | 0.01 | 19.8 cycles | 4.20 cycles |
  | 0.05 | 0.01 | 19.8 cycles | 4.99 cycles |
  | 0.01 | 0.50 | 108 cycles | 5.08 cycles |
]

Even a poor local L2 miss rate can have modest average impact when few references miss L1, but each individual memory access remains very expensive.

== What Is a Cache?

*A cache memoizes used or produced data.* Main memory is divided into fixed-size blocks or cache lines. A cache holds a limited number of those blocks plus metadata describing what is present and how it should be managed.

Every cache design answers five questions:

1. *Placement*: which cache locations may hold a memory block?
2. *Identification*: how does hardware determine whether the requested block is present?
3. *Replacement*: which resident block leaves when the allowed locations are full?
4. *Write handling*: when does modified data reach the next level, and is a write miss allocated?
5. *Management granularity*: which bytes share one tag, valid state, dirty state, and transfer?

On a hit, the tag and validity check succeeds and the requested bytes are returned. On a miss, the cache allocates miss-tracking state, chooses a destination and possible victim, obtains the block from a lower level, installs metadata and data, and wakes or replays the waiting request.

$ "Cache hit rate" = "# hits" / ("# hits" + "# misses") $

$ "Cache miss rate" = 1 - "hit rate" $

=== Cache Terminology

For data capacity $C$, block size $b$, associativity $N$, number of blocks $B$, and number of sets $S$:

$ B = C / b, quad S = B / N = C / (b N) $

- A *set* is the group of candidate entries for one address.
- A *way* is one entry position within every set.
- Associativity $N$ is the number of ways per set.
- Data capacity normally excludes tags, valid/dirty bits, replacement state, coherence state, ECC, and other metadata.

== Cache Organizations

Main-memory block number $q=floor(a/b)$ maps to

$ "set" = q mod S, quad "tag" = floor(q/S) $

For an $A$-bit byte address, power-of-two block size, and power-of-two set count:

$ o = log_2 b, quad s = log_2 S, quad t = A - s - o $

where the low $o$ bits are the block/byte offset, the next $s$ bits select a set, and the remaining $t$ bits are the tag. Associativity itself need not be a power of two; slides use 3-way and 7-way examples to emphasize that it is a count of candidate entries.

#three-line-table(
  columns: (1.25fr, 1.45fr, 1.1fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Organization* | *Placement freedom* | *Sets / ways* | *Hardware and behavior* |
  | :------------- | :------------------ | :------------ | :---------------------- |
  | Direct-mapped | Lowest: exactly one entry | $S=B$, $N=1$ | One tag comparison and no victim choice; lowest hit latency, most placement conflicts |
  | N-way set-associative | One of N entries in one set | $S=B/N$ | N parallel tag comparisons and a way mux; replacement within the set |
  | Fully associative | Highest: any entry | $S=1$, $N=B$ | Compare against every tag; no conflict misses, but expensive for large caches |
]

#figure(
  html.frame(cache-placement-organizations()),
  caption: [Address decomposition and placement choices for the same byte address $a=10110_2$, with 4-byte blocks and four total cache entries. Its block number is $q=floor(a/4)=5$. A direct-mapped cache permits only line 1; a 2-way cache permits either way of set 1; a fully associative cache permits any entry. As associativity grows, index bits become tag bits while the offset stays unchanged. Highlighted entries are alternative legal destinations, not duplicate copies.],
)

Higher associativity reduces conflict misses but adds comparators, tag-array ports, a wider data mux, replacement metadata, lookup energy, and often hit latency. The tradeoff is especially important in an L1 critical path.

=== Address-Decomposition Example

Consider an 8-bit byte address, a 64-byte direct-mapped cache, and 8-byte blocks. Then $B=S=8$, so the address contains a 3-bit offset, 3-bit set index, and 2-bit tag.

Addresses separated by $S dot b = 64$ bytes have the same index and different tags. They cannot coexist in this direct-mapped cache even if all other sets are empty.

== A Basic Hardware Cache Design

#figure(
  html.frame(cache-hit-data-path()),
  caption: [N-way cache hit path. The set index reads one entry from every way, the address tag is compared with every valid stored tag, the matching way selects a data block, and the block offset selects the requested bytes.],
)

An N-way lookup proceeds as follows:

1. Split the address into tag, set index, and block offset.
2. Use the set index to read the selected tag and data entry from all N ways. A latency-oriented L1 commonly accesses tag and data arrays in parallel.
3. For each way, compute `way_hit = valid && (stored_tag == address_tag)`.
4. OR the way-hit signals to form the cache hit and use the one-hot matching way to select its data block.
5. Use the block offset and access size to select and align the requested bytes.

On a miss:

1. Merge with an already outstanding miss to the same block or allocate a new miss-tracking entry.
2. Choose an invalid way if one exists; otherwise consult replacement state.
3. If the victim is dirty, preserve or write back its data before overwriting it.
4. Request the missing block from the next level and reserve its destination.
5. Fill data and metadata, then wake, forward to, or replay waiting loads/stores.

=== Tag and Metadata State

#three-line-table(
  columns: (1.35fr, 2fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Field* | *Purpose* | *When it changes* |
  | :------ | :-------- | :---------------- |
  | Valid | Entry contains a meaningful block | Fill, invalidation, reset, or eviction |
  | Tag | Identifies which memory block occupies the entry | Fill/replacement |
  | Dirty | Cache copy differs from the next level | Write hit/fill and writeback |
  | Replacement priority | Estimates which way should leave | Hit, fill, insertion, or policy sampling |
  | Coherence state | Records permission and sharing/ownership | Coherence requests and local reads/writes |
  | ECC/parity | Detects or corrects metadata/data errors | Stored and checked with the entry |
]

Tag and data arrays can be accessed in parallel for low latency or serially for lower energy. In a serial outer-cache lookup, hardware first finds the matching way in the tag array and then reads only that data way.

== Worked Cache Traces

The slide examples use a cache holding eight 32-bit words. They show how temporal locality, conflicts, associativity, and block size change the same short access stream.

#three-line-table(
  columns: (1.55fr, 1.7fr, 1.2fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Organization* | *Repeated addresses* | *Miss rate* | *Reason* |
  | :------------- | :------------------- | :---------- | :------- |
  | Direct-mapped, one-word blocks | `0x04, 0x0C, 0x08`, repeated 5 times | $3/15=20%$ | Three compulsory misses, then temporal hits; addresses occupy different sets |
  | Direct-mapped, one-word blocks | `0x04, 0x24`, repeated 5 times | $10/10=100%$ | Both map to set 1 and continually evict each other |
  | 2-way, one-word blocks | `0x04, 0x24`, repeated 5 times | $2/10=20%$ | Both blocks coexist in the same two-way set |
  | Direct-mapped, four-word blocks | `0x04, 0x0C, 0x08`, repeated 5 times | $1/15=6.67%$ | One 16-byte fill contains all three requested words |
]

For the conflict pair with a four-byte block, block numbers are 1 and 9. An eight-set direct-mapped cache computes `1 mod 8 = 9 mod 8 = 1`, so the blocks have the same index but different tags. This is a placement conflict, not a lack of unused total capacity.

The larger-block example benefits from spatial locality, but it does not prove that larger blocks are universally better. A large line can reduce the number of resident lines, increase fill time, and transfer unused bytes.

== Replacement as Priority Management

On a miss, an invalid way is always preferable because no useful resident block must be discarded. A replacement policy is consulted only when every candidate way is valid.

Think of each block as carrying a priority that estimates its future value:

- *Insertion*: what priority should a newly filled block receive, and should it enter this level at all?
- *Promotion*: how should a hit change that priority?
- *Eviction/replacement*: which block should leave when the set is full?

=== LRU and Its Approximations

Least-recently used (LRU) evicts the block whose last access is oldest. A two-way set needs only one recency bit, but N ways have $N!$ possible total access orders. The state, update wiring, and timing of exact LRU become expensive at high associativity.

Common alternatives include:

- *Tree pseudo-LRU*: a binary tree records an approximate less-recently-used direction.
- *Not-most-recently-used (NMRU)*: avoid the most recent way and choose among the rest.
- *FIFO*: evict the oldest inserted block regardless of intervening hits.
- *Random*: require little state and avoid deterministic worst-case cycles.
- *Frequency/reuse/refetch-cost policies*: keep blocks expected to be reused or expensive to obtain again.
- *Hybrid policies*: use sampled sets or phase feedback to select between candidate policies.

LRU is not always superior to random. In a four-way set repeatedly accessing `A, B, C, D, E`, LRU evicts exactly the next block needed and can produce zero hits after warmup. Random replacement may preserve some block by chance.

Belady's OPT evicts the block whose next reference is furthest in the future. It is an offline miss-count oracle, not an implementable policy, and minimizing miss count still need not minimize execution time when miss latency and overlap differ.

== Write Policies

Write propagation on a hit and allocation on a miss are *orthogonal decisions*.

=== When Modified Data Reaches the Next Level

#three-line-table(
  columns: (1.25fr, 2.15fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Policy* | *Operation* | *Tradeoff* |
  | :------- | :---------- | :--------- |
  | Write-through | Update the cache and next level on every write hit | Next level stays current and control is simpler, but every store consumes lower-level bandwidth; a write buffer is usually needed |
  | Write-back | Update only the cache and set dirty state; send data down when evicted or explicitly cleaned | Multiple stores merge and save traffic/energy, but dirty eviction adds latency and requires writeback buffering |
]

=== Whether a Write Miss Enters the Cache

#three-line-table(
  columns: (1.25fr, 2.15fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Policy* | *Operation* | *Best fit and cost* |
  | :------- | :---------- | :------------------ |
  | Write-allocate | Obtain ownership and normally fetch the line, install it, then modify it | Good when later accesses reuse the line; fill traffic can be wasteful for streaming writes |
  | No-write-allocate / write-around | Forward the write to the next level without installing the line | Avoids pollution for low-reuse writes; later reads or writes may miss again |
]

Write-back is commonly paired with write-allocate and write-through with no-write-allocate, but neither pairing is required by definition.

Stores smaller than a block update bytes under a write mask. If a partial store misses and the cache allocates, the unchanged bytes must still be obtained from the old line unless per-sector validity is supported. A known full-line overwrite can avoid reading the old line because no old byte survives.

Write buffers decouple processor stores from lower-level latency. They can merge writes to the same block, but loads must search or forward from buffered writes so they do not observe stale data.


