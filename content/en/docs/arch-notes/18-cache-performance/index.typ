#import "../../index.typ": *
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#import "../_diagrams/matrix-multiplication.typ": (
  naive-matrix-multiplication, tiled-matrix-multiplication,
)
#show: series-chapter.with(
  arch-notes-series,
  route: "docs/arch-notes/18-cache-performance/",
  title: "Cache Performance",
)

- Cache size
- Block size
- Associativity
- Replacement policy
- Insertion/Placement policy
- Promotion Policy

== Cache Size

- Cache size: total data (not including tag) capacity
  - bigger can exploit temporal locality better
- *Too large* a cache adversely affects hit and miss latency
  - bigger is slower
- *Too small* a cache
  + does not exploit temporal locality well
  + useful data replaced often
- Working set: entire set of data the executing application references within a time interval

Benefits of cache size widely varies across applications

== Block Size

- Block size is the data that is associated with an address tag
  - not necessarily the unit of transfer between hierarchies
    - Sub-blocking: A block divided into multiple pieces (each w/ V/D bits)

Assuming the cache size is constant
- Too small blocks
  + do not exploit spatial locality well
  + have larger tag overhead
- Too large blocks
  + too few total blocks -> exploit temporal locality not well
  + waste cache space and bandwidth/energy if spatial locality is not high

=== Large Blocks: Critical-Word and Subblocking

- Large cache blocks can take a long time to fill into the cache
  - Idea: Fill cache block *critical-word first*(*know this load needs requires xxx word* in this block, try to *fetch that word first* from the mem and *bring that first* as opposed to the entire block)
  - Supply the critical data to the processor immediately
- Large cache blocks can waste bus bandwidth
  - Idea: Divide a block into *subblocks*
  - Associate separate valid and dirty bits for each subblock
  - *Recall: When is this useful?*

#figure(
  table(
    columns: (
      .42fr,
      .42fr,
      1.35fr,
      .42fr,
      .42fr,
      1.35fr,
      .55fr,
      .42fr,
      .42fr,
      1.35fr,
      1.2fr,
    ),
    align: center + horizon,
    stroke: 0.55pt + rgb("#87909C"),
    table.cell(colspan: 3, fill: rgb("#EAF1FB"))[*Subblock 0*],
    table.cell(colspan: 3, fill: rgb("#EAF1FB"))[*Subblock 1*],
    table.cell(fill: rgb("#F6F7F9"))[...],
    table.cell(colspan: 3, fill: rgb("#EAF1FB"))[*Subblock k - 1*],
    table.cell(fill: rgb("#F0F2F5"))[*Shared metadata*],
    table.cell(fill: rgb("#E7F4ED"))[*V*],
    table.cell(fill: rgb("#FFF0DF"))[*D*],
    [data],
    table.cell(fill: rgb("#E7F4ED"))[*V*],
    table.cell(fill: rgb("#FFF0DF"))[*D*],
    [data],
    table.cell(fill: rgb("#F6F7F9"))[...],
    table.cell(fill: rgb("#E7F4ED"))[*V*],
    table.cell(fill: rgb("#FFF0DF"))[*D*],
    [data],
    table.cell(fill: rgb("#F0F2F5"))[*Tag*],
  ),
  caption: [A subblocked cache line.],
)

== Associativity

How many blocks can be present in the same index (i.e., set)?

- Larger associativity
  - lower miss rate (reduced conflicts)
  - higher hit latency and area cost
- Smaller associativity
  - lower cost
  - lower hit latency
    - Especially important for L1 caches

Is power of 2 associativity required? 5-way or 3-way?
- No, because associativity is not about indexing, we do it for comparison.

=== Alternatives and Enhancements to Associativity

- A *victim cache* is a small fully associative buffer holding lines recently evicted from a direct-mapped or low-associativity cache. On a primary-cache miss, hardware probes the victim cache and can swap a matching line back. It targets short-term conflict misses without lengthening every primary lookup as much as full associativity would.
- A *pseudo-associative cache* checks a preferred location first and an alternate location on a first-probe miss. It has a fast common hit and a slower alternate hit.
- *Hashed/randomized indexing* mixes address bits so simple power-of-two strides do not repeatedly collide at one index.
- A *skewed-associative cache* uses a different index hash for each way, making it less likely that the same group of blocks conflicts in every way.
- *Way prediction* predicts which way will match and reads only that data way first. A correct prediction saves mux/energy or latency; a misprediction requires another lookup.

These schemes trade uniform hit latency and simple indexing for fewer conflicts, less lookup energy, or lower area.

== Classification of Cache Misses

The traditional *3C model* classifies demand misses by comparing the actual cache with progressively more flexible reference models.

#three-line-table(
  columns: (1.15fr, 2.5fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Miss type* | *Definition* | *Representative remedies* |
  | :---------- | :----------- | :------------------------ |
  | Compulsory / cold | First reference to a memory block in the observed execution | Prefetching, larger blocks when spatial locality exists, software warmup |
  | Capacity | The misses that would occur even in a fully-associative cache (with optimal replacement) of the same capacity  | Larger/effectively larger cache, tiling/blocking, compression, avoid retaining dead data |
  | Conflict | Neither compulsory nor capacity; restricted set placement caused the miss | More associativity, victim cache, alternate hashing/skewing, better placement |
]

The strict capacity definition matters: a miss in a full set is not automatically a capacity miss. If a fully associative cache of the same capacity would hit, the miss is a conflict miss.

Real systems also observe coherence misses, translation effects, prefetch interactions, and policy misses relative to an ideal replacement oracle. The 3C model remains useful because it connects symptoms to different remedies.

== Improve Cache Performance

Cache optimization has three distinct goals:

#three-line-table(
  columns: (1.45fr, 2fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Goal* | *Representative techniques* | *Common tradeoff* |
  | :----- | :-------------------------- | :---------------- |
  | Reduce miss rate | Capacity, associativity, victim/skewed structures, prefetching, insertion/replacement, software locality | May increase hit time, energy, pollution, or bandwidth |
  | Reduce miss latency/cost | More levels, critical-word-first, early restart, non-blocking operation, MLP, faster interconnect/memory | Adds tracking state and lower-level contention |
  | Reduce hit latency/cost | Direct mapping, way prediction, banked/pipelined arrays, serial or selective data-way access | A fast/cheap hit design can raise miss rate or variable hit latency |
]

== Software Approaches to Locality

Hardware cannot recover locality that the program's access order destroys. Software can change traversal order and data layout while preserving program semantics.

=== Loop Interchange and Fusion

Example: If column-major
- `x[i+1,j]` follows `x[i,j]` in memory
- `x[i,j+1]` is far away from `x[i,j]`

```py
// poor code
for i = 1, rows
  for j = 1, columns
    sum = sum + x[i, j]

// better code
for j = 1, columns
  for i = 1, rows
    sum = sum + x[i, j]
```

For a row-major matrix, traversing columns in the inner loop accesses elements far apart, while traversing rows in the inner loop consumes consecutive elements from each fetched line. Interchanging legal loop nests can convert a large stride into unit-stride access.

Loop fusion combines loops over the same data so a value remains hot between operations. Loop fission can instead separate streams when interleaving them exceeds cache capacity or prevents vectorization. Dependence analysis determines whether either transformation is legal.

=== Blocking or Tiling

Blocking *partitions a computation into phases whose active data fits in a cache or scratchpad*. Naive matrix multiplication repeatedly streams rows/columns through the hierarchy. A tiled version operates on small submatrices so elements of $A$ and $B$ are reused many times before their tiles leave fast storage.

Tile size must account for all simultaneously live arrays, associativity, alignment, and other users of the cache. A tile whose nominal byte count equals cache capacity can still thrash one set or leave no room for instructions, stack data, and metadata.

GPU programs often copy a tile from global memory into shared memory, synchronize a thread block, reuse the tile for many arithmetic operations, and then load the next tile. This is software-managed caching with explicit placement and lifetime.

===== Matrix Multiplication

Matrix multiplication: $C = A times B$
Consier two input matrices $A$ and $B$ in *row-major layout*
- $A$ size is $M times P$
- $B$ size is $P times N$
- $C$ size is $M times N$

#figure(
  html.frame(naive-matrix-multiplication()),
  caption: [Naïve traversal. For fixed $i$ and $j$, $k$ scans a contiguous row of $A$ but a column of row-major $B$ with stride $N$, while accumulating $C_(i,j)$.],
)

*Naïve implementation* of matrix multiplication has poor cache locality

```c
#define A(i,j) matrix_A[i * P + j]
#define B(i,j) matrix_B[i * N + j]
#define C(i,j) matrix_C[i * N + j]
for (i = 0; i < M; i++){ // i = row index
  for (j = 0; j < N; j++){ // j = column index
    C(i, j) = 0; // Set to zero
    for (k = 0; k < P; k++) // Row x Col
      C(i, j) += A(i, k) * B(k, j);
  }
}
```

Consecutive accesses to $B$ are far from each other, in different cache lines. *Every access to $B$ is likely to cause a cache miss.*

We can achieve better cache locality by computing on *smaller tiles or blocks that fit in the cache* (Or in the *scratchpad memory and register file* if we compute on a GPU). Calculate the partial sum and then move.

#figure(
  html.frame(tiled-matrix-multiplication()),
  caption: [Tiled traversal. Keep $C_(I,J)$ resident while stepping through $K$; each loaded $A_(I,K)$ and $B_(K,J)$ tile is reused for many multiply--accumulate operations before the next tiles are fetched.],
)

*Tiled implementation* operates on submatrices (tiles or blocks) that fit fast memories (cache, scratchpad, RF)

```c
#define A(i,j) matrix_A[i * P + j]
#define B(i,j) matrix_B[i * N + j]
#define C(i,j) matrix_C[i * N + j]

for (I = 0; I < M; I += tile_dim){
  for (J = 0; J < N; J += tile_dim){
    Set_to_zero(&C(I, J)); // Set to zero
    for (K = 0; K < P; K += tile_dim)
      Multiply_tiles(&C(I, J), &A(I, K), &B(K, J));
  }
}
```

=== Data-Layout Transformation

A pointer-linked node may contain a small frequently used key and next pointer plus a large rarely used payload. Keeping them in one structure causes every traversal to fetch cold bytes. Hot/cold field separation places traversal fields densely and moves the payload elsewhere, increasing useful bytes per cache block.

General idea: *Separate frequently-accessed(hot) data from rarely-accessed(cold) data so that they are not in the same cache block.*

==== Example: Linked-list

Pointer based traversal (e.g., of a linked list). Assume a huge linked list (1B nodes) and unique keys.

```c
struct Node {
  // frequently accessed
  struct Node* next;
  int key;
  // rarely accessed
  char [256] name;
  char [256] school;
}
while (node) {
  if (node->key == input-key) { // frequently accessed
    // access other fields of node(rarely accessed)
  }
  node = node->next;  // frequently accessed
}
```

Poor hit rate. `name` and `school` occupy most of the cache line even though they are rarely accessed! When traversing this linked list, access one node, and then will get a cache miss to access the next(every node incur the cache miss).

Here *separate rarely-accessed fields of a data structure and pack them into a separate data structure*

```c
struct Node {
  struct Node* next;
  int key;
  struct Node-data* node-data;
}

struct Node-data {
  char [256] name;
  char [256] school;
}

while (node) {
  if (node->key == input-key) { // frequently accessed
    // access other fields of node(rarely accessed)
  }
  node = node->next;  // frequently accessed
}
```

Who should do this?
- Programmer
- Compiler: Profiling vs. dynamic
- Hardware?
- *Who can determine what is frequently accessed?*


