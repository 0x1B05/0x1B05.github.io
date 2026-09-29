#import "../../index.typ": doc-toc, example, template
#import "@preview/tablem:0.3.0": three-line-table
#import "./_diagrams/ai-inference.typ": (
  flash-decoding-parallel-reduction, flashattention-forward,
  flashattention-matrix-tiles, kv-cache-decode, mha-gqa-mqa-head-sharing,
  mla-decode-dataflow, pagedattention-block-table,
)
#show: template.with(locale: "en", route: "docs/ai-inference/", title: "AI Inference")

= AI Inference

#doc-toc("en")

== FlashAttention

- Reduce memory access during training:
  - avoid reading and writing the attention matrix from/to HBM.

Attention: $Q, K, V in RR^(N times d)$ are stored in HBM, where $N$ is the sequence length and $d$ the embedding dimension.
+ *Load Q, K from HBM to SRAM*
+ Compute $S = Q K^T$
+ *Store S into HBM*
+ *Load S from HBM to SRAM*
+ Compute $P = "softmax"(S)$
+ *Store $P$ into HBM*
+ *Load P, V from HBM to SRAM*
+ Compute $O = P V$
+ *Store O into HBM*
+ Return O

As the sequence length $N$ grows, the cache grows as $N^2$.

+ Compute-bound: large matrix multiplications, many-channel convolutions.
+ Memory-bound: elementwise ops (ReLU, Dropout); reduction ops (sum, softmax).
  + Memory-bound ops are usually optimized by fusion: intermediates are not cached, reducing HBM traffic. Fusion helps, but training still needs the intermediates for the backward pass.

Goal: avoid reading and writing the attention matrix from/to HBM.
+ Compute in tiles and fuse the operations without caching intermediates.
+ Recompute the intermediates during backpropagation.

Tile $S$; each tile runs the whole attention pipeline and accumulates straight into the output matrix, writing back only once after all steps are done.

Softmax is computed one row at a time. The question is how to recover the global row Softmax from partial tile results.

=== Block-wise Softmax Identities

For one row $bold(x) = [x_1, ..., x_N]$, retain three pieces of state instead of the complete score row:

$
  & m(bold(x)) := max(bold(x)) \
  & bold(p)(bold(x)) := [e^(x_1-m(bold(x))), ..., e^(x_N-m(bold(x)))] \
  & l(bold(x)) := sum_i bold(p)(bold(x))_i \
  & "softmax"(bold(x)) := (bold(p(x))) / l(bold(x))
$

Here $bold(p)$ is the *unnormalized* exponential vector, not the final probability vector. $m$ prevents overflow, and $l$ is the scalar normalizer.

Now split the row into two blocks, $bold(x) = [bold(x)^(1), bold(x)^(2)]$. Compute $(m, bold(p), l)$ locally for each block, then merge them as follows:

$
  &m(bold(x)) := max(m(bold(x)^(1)), m(bold(x)^(2))) \
  &bold(p)(bold(x)) := [e^(m(bold(x)^(1))-m(bold(x))) bold(p)(bold(x)^(1)), e^(m(bold(x)^(2))-m(bold(x))) bold(p)(bold(x)^(2))] \
  &l(bold(x)) := e^(m(bold(x)^(1))-m(bold(x))) l(bold(x)^(1)) + e^(m(bold(x)^(2))-m(bold(x))) l(bold(x)^(2))
$

The scaling factors convert both local states to the same global maximum. This is the exact online Softmax invariant used when FlashAttention adds one score tile at a time.

#example(title: "Online Softmax: Numerical Example")[
  The following example explains how FlashAttention obtains an *exact* row-wise Softmax while processing the row in blocks. The input row is
  $bold(x) = [1, 3, -2, 3, 1, 4, 5, 0, 1]$.

  *Full Softmax (reference result).* Let the global maximum be $m = 5$. Subtracting $m$ before exponentiation is numerically stable and does not change the final probabilities.

    #three-line-table(
    [
      | Quantity | $x_1$ | $x_2$ | $x_3$ | $x_4$ | $x_5$ | $x_6$ | $x_7$ | $x_8$ | $x_9$ |
      | :------- | ----: | ----: | ----: | ----: | ----: | ----: | ----: | ----: | ----: |
      | Input $x_i$ | 1 | 3 | -2 | 3 | 1 | 4 | 5 | 0 | 1 |
      | Shifted input $x_i - m$ | -4 | -2 | -7 | -2 | -4 | -1 | 0 | -5 | -4 |
      | Numerator $e^(x_i - m)$ | 0.018316 | 0.135335 | 0.000912 | 0.135335 | 0.018316 | 0.367879 | 1.000000 | 0.006738 | 0.018316 |
      | Softmax output $p_i$ | 0.010767 | 0.079555 | 0.000536 | 0.079555 | 0.010767 | 0.216254 | 0.587839 | 0.003961 | 0.010767 |
    ],
  )

  Here the global normalizer is $l = sum_i e^(x_i - m) = 1.701147$, and $p_i = e^(x_i-m) / l$.

  *Block-wise computation.* Split the same row into block 1, $[x_1, ..., x_5]$, and block 2, $[x_6, ..., x_9]$. Each block is first normalized with its own local maximum; its local normalizer is then rescaled to the global maximum before the two blocks are merged.

    #three-line-table(
    [
      | Block | Elements | Local maximum | Local normalizer | Rescale to $m = 5$ | Contribution to global $l$ |
      | :---- | :------- | ------------: | ---------------: | -----------------: | -------------------------: |
      | Block 1 | $[1, 3, -2, 3, 1]$ | $m_1 = 3$ | $l_1 = 2.277409$ | $e^(m_1-m) = 0.135335$ | $0.135335 times l_1 = 0.308214$ |
      | Block 2 | $[4, 5, 0, 1]$ | $m_2 = 5$ | $l_2 = 1.392933$ | $e^(m_2-m) = 1$ | $1 times l_2 = 1.392933$ |
      | Merge | Both blocks | $m = max(m_1, m_2) = 5$ | -- | -- | $l = 0.308214 + 1.392933 = 1.701147$ |
    ],
  )

    #three-line-table(
    [
      | Quantity | $x_1$ | $x_2$ | $x_3$ | $x_4$ | $x_5$ | $x_6$ | $x_7$ | $x_8$ | $x_9$ |
      | :------- | ----: | ----: | ----: | ----: | ----: | ----: | ----: | ----: | ----: |
      | Block | 1 | 1 | 1 | 1 | 1 | 2 | 2 | 2 | 2 |
      | Local numerator $e^(x_i-m_b)$ | 0.135335 | 1.000000 | 0.006738 | 1.000000 | 0.135335 | 0.367879 | 1.000000 | 0.006738 | 0.018316 |
      | After rescaling $e^(m_b-m)e^(x_i-m_b)$ | 0.018316 | 0.135335 | 0.000912 | 0.135335 | 0.018316 | 0.367879 | 1.000000 | 0.006738 | 0.018316 |
      | Final output $p_i$ | 0.010767 | 0.079555 | 0.000536 | 0.079555 | 0.010767 | 0.216254 | 0.587839 | 0.003961 | 0.010767 |
    ],
  )

  The rescaled numerator row is identical to the full-Softmax numerator row. Therefore block-wise merging gives exactly the same Softmax result, without materializing the complete attention-score matrix in HBM.
]

=== FlashAttention Forward Algorithm

The outer loop retains one key/value tile in SRAM. The inner loop visits each query tile, updates its running maximum $bold(m)_i$, normalizer $bold(l)_i$, and output $bold(O)_i$, then writes only those states back to HBM. `rowmax` and `rowsum` operate independently on every row; `exp` is elementwise.

#figure(html.frame(flashattention-forward()))

The algorithm never writes the full score matrix $bold(S)$ or probability matrix $bold(P)$ to HBM. It keeps only one tile of each in SRAM, while $(bold(m)_i, bold(l)_i, bold(O)_i)$ carries the exact state required to merge the next tile.

==== SRAM Budget and Buffer Reuse

Let $M$ be the SRAM capacity measured in scalar elements (or bytes after dividing by the element size), and let $d$ be the head dimension. The block-size rule is a four-way budget:

$B_c approx M / (4d)$

$B_r = min(B_c, d)$

*Concrete matrix tiles.* The highlighted row blocks below are the exact operands in one inner-loop iteration. The matrices in HBM are partitioned by rows; the on-chip operations use only $bold(Q)_i$, $bold(K)_j$, and $bold(V)_j$.

#figure(
  html.frame(flashattention-matrix-tiles()),
  caption: [Concrete row blocking and the two tile-level matrix products in one FlashAttention inner-loop iteration.],
) <fig-flashattention-matrix-tiles>

Consequently, the major tile sizes are bounded as follows:

#three-line-table(
  [
    | Storage | Tile shape | Approximate SRAM budget | Reason |
    | :------ | :--------- | ----------------------: | :----- |
    | $bold(K)_j$ | $B_c times d$ | $M / 4$ | One key tile is retained across all query tiles. |
    | $bold(V)_j$ | $B_c times d$ | $M / 4$ | The matching value tile is retained with $bold(K)_j$. |
    | $bold(Q)_i$ *or* old $bold(O)_i$ | $B_r times d$ | at most $M / 4$ | Their physical buffer can be reused after score computation. |
    | $bold(S)_(i j)$ *or* $tilde(bold(P))_(i j)$ | $B_r times B_c$ | at most $M / 4$ | The score tile is overwritten in place by the local exponential tile. |
  ],
)

The cap $B_r <= d$ is essential: it gives $B_r B_c <= d B_c approx M / 4$, so the score tile cannot grow beyond the SRAM budget. Without this cap, choosing both dimensions as $M / (4d)$ would make the score tile grow quadratically with $M$.

*Logical state versus physical buffers.* In Algorithm 1, line 8 logically loads both $bold(Q)_i$ and the old $bold(O)_i$. They are different tensors and cannot occupy the same buffer at the same instant. The four-way budget above describes an optimized kernel schedule, which delays the load of the old output until $bold(Q)_i$ is no longer live:

#three-line-table(
  [
    | Phase | Data live in addition to retained $bold(K)_j, bold(V)_j$ | Action | Buffer reuse |
    | :---- | :------------------------------------------------------- | :----- | :----------- |
    | 1 | $bold(Q)_i$, $bold(S)_(i j)$ | Compute $bold(S)_(i j) = bold(Q)_i bold(K)_j^T$. | $bold(Q)_i$ is needed only for this step. |
    | 2 | $tilde(bold(P))_(i j)$, $tilde(bold(m))_(i j)$, $tilde(bold(l))_(i j)$ | Compute local row maximum, exponential values, and row sums. | Overwrite $bold(S)_(i j)$ with $tilde(bold(P))_(i j)$; release $bold(Q)_i$. |
    | 3 | $tilde(bold(P))_(i j)$, old $bold(O)_i$, old $bold(l)_i$, old $bold(m)_i$ | Merge the new score tile into the running output state. | Load old output state into the released $bold(Q)_i$ buffer. |
    | 4 | new $bold(O)_i$, new $bold(l)_i$, new $bold(m)_i$ | Write the updated state to HBM. | Reuse the same state buffer in the next inner-loop iteration. |
  ],
)

Thus $bold(Q)_i$ and $bold(O)_i$ are *logically distinct* but can have non-overlapping physical lifetimes in a scheduled implementation. Likewise, $bold(S)_(i j)$ becomes $tilde(bold(P))_(i j)$ in place. The paper's block-size formula specifies the right asymptotic scale for IO analysis; a real GPU kernel additionally rounds tiles down for hardware alignment and reserves space for registers, vector states, and possible double buffering.

== KV Cache

During autoregressive generation, the model produces one new token at a time. The new
token needs to attend to all previous tokens, but the old tokens do not change. Therefore
their key and value vectors should not be projected again at every step. Each Transformer
layer stores those vectors in a KV cache.

For one attention head, the new token $bold(x)_t$ produces

$ bold(q)_t = bold(x)_t bold(W)_Q $

$ bold(k)_t = bold(x)_t bold(W)_K $

$ bold(v)_t = bold(x)_t bold(W)_V $

and appends only the new key and value:

$ bold(K)_("cache")^(t) = [bold(K)_("cache")^(t-1); bold(k)_t] $

$ bold(V)_("cache")^(t) = [bold(V)_("cache")^(t-1); bold(v)_t] $

The query has length one, while the cache has length $t$. The output for the new token is

$ bold(s)_t = bold(q)_t (bold(K)_("cache")^(t))^T / sqrt(d_h) $

$ bold(a)_t = "softmax"(bold(s)_t) $

$ bold(y)_t = bold(a)_t bold(V)_("cache")^(t) $

#figure(
  html.frame(kv-cache-decode()),
  caption: [Decode step $t$: compute one new Q/K/V triple, append only K/V, and reuse the complete historical cache for attention.],
) <fig-kv-cache-decode>

The causal mask is implicit here: at step $t$, the cache contains positions $1$ through
$t$ and no future positions. A short sequence makes the reuse visible:

#three-line-table(
  [
    | Moment | New computation | Reused data |
    | :----- | :-------------- | :---------- |
    | Prefill prompt $x_1, ..., x_T$ | Compute the prompt's Q/K/V and attention outputs. | None yet. |
    | Generate $x_(T+1)$ | Compute only $q_(T+1), k_(T+1), v_(T+1)$; attend to positions $1, ..., T+1$. | $bold(K)_(1:T)$ and $bold(V)_(1:T)$. |
    | Generate $x_(T+2)$ | Compute only the new Q/K/V; attend to positions $1, ..., T+2$. | The entire previous cache. |
  ],
)

KV caching removes the repeated historical projection work and avoids rerunning attention for all old output positions. It does *not* make decoding constant-time: at step $t$, the new query still reads $t$ cached keys and values. The bottleneck therefore shifts toward reading the cache from HBM. With $L$ layers, batch size $B$, $H_"kv"$ cached heads, sequence length $T$, head dimension $d_h$, and $s$ bytes per scalar, the cache footprint is

$ "KV-cache bytes" = 2 L B T H_"kv" d_h s $

The factor 2 is for $bold(K)$ and $bold(V)$. KV cache and FlashAttention address different temporary data:

- KV cache keeps historical *inputs to attention* so they are not recomputed.
- FlashAttention avoids writing the temporary score/probability matrix to HBM.

During decode, FlashAttention can stream the cached K/V along the sequence axis. The new query row is multiplied with one K tile at a time, and the online Softmax state $(bold(m), bold(l), bold(O))$ merges those tiles without materializing the full score row.

== Flash-Decoding

KV caching removes repeated projections, but one operation still grows with the prefix: the
new query must read every cached key and value. Ordinary FlashAttention obtains parallelism
mainly from the batch, attention heads, and blocks of query rows. This works well during
prefill or training, where the query length is large. During autoregressive decode, however,
the query length $L_q$ is usually one. With a small batch, there may be too few query blocks
to occupy all GPU streaming multiprocessors, while each active block sequentially traverses
a long KV cache.

Flash-Decoding adds the cached sequence length as another parallel axis. At decode step $t$,
let $T = t$ be the current cache length. For one query row, choose $1 <= S <= T$ and split
the $T$ cached positions into $S$ nonempty, disjoint contiguous ranges:

$ I_1 union I_2 union dots.c union I_S = {1, ..., T} $

$ I_r inter I_k = emptyset quad "for" quad r != k $

Write $T_r$ for the number of positions in $I_r$, so $T_r > 0$ and $sum_r T_r = T$.
These splits are *views* of the existing KV cache. They do not copy or duplicate K/V data.
The same current query $bold(q)_t$ is broadcast to all splits, and each split independently
runs a local FlashAttention computation.

For split $r$, let $j in I_r$ and define

$
        s_j & := (bold(q)_t bold(k)_j^T) / sqrt(d_h) \
        m_r & := max_(j in I_r) s_j \
        l_r & := sum_(j in I_r) e^(s_j - m_r) \
  bold(u)_r & := sum_(j in I_r) e^(s_j - m_r) bold(v)_j
$

The split writes a locally normalized partial output and one log-sum-exp scalar:

$
  bold(o)_r & := bold(u)_r / l_r \
        z_r & := m_r + ln l_r
$

Here $bold(o)_r in RR^(d_v)$ is normalized only over positions in $I_r$. The scalar
$z_r$ records the total exponential mass of that split:

$ e^(z_r) = sum_(j in I_r) e^(s_j) $

After all splits finish in parallel, a second kernel computes

$
          z & := "logsumexp"_r(z_r) \
    alpha_r & := e^(z_r - z) \
  bold(o)_t & := sum_r alpha_r bold(o)_r
$

The weights satisfy $sum_r alpha_r = 1$. This merge is mathematically exact: it introduces
no approximation to the attention rule, although a different floating-point reduction order
can change the last few bits. The weight $alpha_r$ is the fraction of the *global* Softmax
denominator contributed by split $r$. Flash-Decoding therefore does not average independently
normalized partial outputs. A split containing larger scores must contribute more strongly.

#example(title: "Why the Partial Outputs Are Not Averaged")[
  Suppose two splits have exponential masses $e^(z_1) = 1$ and $e^(z_2) = 3$.
  Their correct merge weights are

  $ alpha_1 = 1 / 4 quad "and" quad alpha_2 = 3 / 4 $

  so the full output is

  $ bold(o)_t = (1 / 4) bold(o)_1 + (3 / 4) bold(o)_2 $

  The equal average $(bold(o)_1 + bold(o)_2) / 2$ would be wrong because it would
  pretend that the two splits contributed equal amounts to the full Softmax denominator.
]

The same merge can be written directly with the online-Softmax state used earlier:

$
          m & := max_r m_r \
          l & := sum_r e^(m_r - m) l_r \
    bold(u) & := sum_r e^(m_r - m) bold(u)_r \
  bold(o)_t & := bold(u) / l
$

Thus Flash-Decoding applies the online Softmax invariant at two levels: first within each
KV split, then once more across the split results.

#figure(
  html.frame(flash-decoding-parallel-reduction()),
  caption: [Flash-Decoding splits one decode query across disjoint KV-cache views, computes local attention states in parallel, and combines them without approximating the attention rule.],
) <fig-flash-decoding-parallel-reduction>

=== Kernel Schedule and Cost

The execution has three logical steps:

1. Partition the cached token axis into $S$ ranges. This is metadata only; the ranges are
  views, so no GPU kernel copies K/V.
2. Launch the local attention kernel over batch, heads, query rows, *and KV splits*.
  Each work item writes one partial output vector $bold(o)_r$ and one LSE scalar $z_r$.
3. Launch a small combine kernel that reduces the $S$ partial states for each query row.

The metadata-only partition is not a GPU kernel, so the computation itself uses two kernels:
one for local split attention and one for the final reduction.

Let $N_q = B H_q L_q$ be the total number of query rows across the batch and heads. The
  main attention work and KV traffic still scale with the cached length $T$:

  $
          "main work" & := Theta(N_q T (d_h + d_v)) \
       "combine work" & := Theta(N_q S d_v) \
    "temporary state" & := Theta(N_q S (d_v + 1))
  $

The temporary state contains one $d_v$-element partial output plus one LSE scalar for each
query row and split. It is much smaller than an $N_q times T$ score matrix, but it is not
free: too many splits increase partial-output traffic and reduction work. A runtime should
therefore choose enough splits to occupy the GPU, and use $S = 1$ when the existing batch,
head, and query-row parallelism is already sufficient.

#three-line-table(
  [
    | Property | FlashAttention | Flash-Decoding |
    | :------- | :------------- | :------------- |
    | Main parallel axes | Batch, head, and query-row blocks. | The same axes plus KV-sequence splits. |
    | One work item's KV range | Sequentially streams the full relevant KV range. | Streams one disjoint KV split. |
    | Intermediate state | One online Softmax state per query row. | One partial output and LSE per query row and split. |
    | Final reduction | Not needed across KV splits. | LSE-weighted reduction over splits. |
    | Best workload | Prefill, training, or enough query parallelism. | Very short Q, small batch, and a long KV cache. |
    | Attention result | Mathematically exact, up to floating-point roundoff. | The same; split reduction may change the last few bits. |
  ],
)

Flash-Decoding does not reduce the KV-cache capacity, total K/V bytes that must eventually
be read, or the asymptotic attention work. It reduces latency by exposing more independent
work to the GPU. It is most useful for one or a few decode queries with long contexts; for
short contexts, large batches, prefill, training, or short sliding windows, the extra
partial writes and combine kernel may provide little benefit or may be slower.

It can be combined conceptually with GQA, PagedAttention, or MLA, but the serving stack still
needs a split-KV kernel that supports the concrete head mapping and cache layout.

It is also unrelated to speculative decoding: Flash-Decoding still generates one
autoregressive token at a time. It changes how one token attends to the existing cache,
not how many future tokens are proposed. The original CodeLlama-34B experiment reported
up to an 8x end-to-end generation speedup for very long sequences on its tested A100
configuration; this is a workload-specific result, not a constant-time guarantee.

Source: #link("https://princeton-nlp.github.io/flash-decoding/")[Flash-Decoding for Long-Context Inference].

Flash-Decoding changes how the existing cache is consumed; GQA changes how many K/V heads
are stored.

== Grouped-Query Attention (GQA)

KV cache size is proportional to the number of cached K/V heads. Standard multi-head attention (MHA) gives every query head a separate K/V head. GQA keeps many query heads but shares one K/V head across a group of query heads. This reduces cache traffic without removing the separate query heads.

Let

$ H_q = "number of query heads" $

$ H_"kv" = "number of K/V heads" $

$ g = H_q / H_"kv" $

where $g$ is the group size. The tensor shapes are:

#three-line-table(
  [
    | Tensor | Shape | Meaning |
    | :----- | :---- | :------- |
    | $bold(Q)$ | $B times T times H_q times d_h$ | Every query head has its own query vectors. |
    | $bold(K)$ | $B times T times H_"kv" times d_h$ | One key head is shared by $g$ query heads. |
    | $bold(V)$ | $B times T times H_"kv" times d_h$ | One value head is shared by $g$ query heads. |
    | $bold(O)$ | $B times T times H_q times d_h$ | Output still has one result per query head. |
  ],
)

The logical mapping from a query head to its shared K/V head is

$ r(h) = floor(h / g) $

$ h in {0, ..., H_q-1} $

so query head $h$ uses $bold(K)^(r(h))$ and $bold(V)^(r(h))$:

$ bold(s)^h = bold(Q)^h (bold(K)^(r(h)))^(T) / sqrt(d_h) $

$ bold(O)^h = "softmax"(bold(s)^h) bold(V)^(r(h)) $

The K/V tensors may be *logically repeated* to match the query-head dimension, but an efficient implementation does not physically copy them. It broadcasts one cached K/V head to the $g$ query heads in its group.

#three-line-table(
  [
    | Attention variant | Query heads | K/V heads | Group size $g$ | KV-cache size |
    | :---------------- | ----------: | --------: | --------------: | :------------ |
    | MHA | $H_q$ | $H_q$ | 1 | Baseline |
    | GQA | $H_q$ | $H_q / g$ | $g$ | $1/g$ of MHA |
    | MQA | $H_q$ | 1 | $H_q$ | $1/H_q$ of MHA |
  ],
)

GQA reduces the K/V projection work, cache capacity, and K/V memory traffic by roughly the factor $g$, while retaining the separate query projections and output heads. Its trade-off is that all query heads in one group must share the same K/V representation, which can reduce model quality if the number of K/V heads is made too small.

For example, with $H_q = 8$ and $H_"kv" = 2$, the group size is $g = 4$:

#three-line-table(
  [
    | Query heads | Shared K/V head | Interpretation |
    | :---------- | --------------- | :------------- |
    | $q^0, q^1, q^2, q^3$ | $k^0, v^0$ | Four query heads read the first cached K/V head. |
    | $q^4, q^5, q^6, q^7$ | $k^1, v^1$ | Four query heads read the second cached K/V head. |
  ],
)

#figure(
  html.frame(mha-gqa-mqa-head-sharing()),
  caption: [Head sharing at decode time for $H_q = 8$: GQA and MQA reduce persistent K/V heads while preserving all query and output heads.],
) <fig-mha-gqa-mqa-head-sharing>

Source: #link("https://arxiv.org/abs/2305.13245")[GQA: Training Generalized Multi-Query Transformer Models from Multi-Head Checkpoints].

The cache stores only two K/V heads:

$ bold(K)_("cache"), bold(V)_("cache") in RR^(B times T times 2 times d_h) $

It does *not* store eight copies. The outputs still contain eight query-head results:

$ bold(O) in RR^(B times T times 8 times d_h) $

The important distinction is:

```text
Q heads:   still separate, so each query head has its own scores and Softmax weights
K/V heads: shared within a group, so one cached K/V tile serves several query heads
Outputs:   still separate, one output head for each query head
```

In a FlashAttention-style implementation, load one cached K/V tile for head $r$, then use it for the $g$ query heads mapped to $r$. Each query head independently updates its own online Softmax state and output; only the K/V tile is shared. Thus GQA preserves the exact tile-wise Softmax computation while reducing K/V storage and HBM traffic.

== PagedAttention

KV caching removes repeated computation, but a serving system still has to allocate and release a large cache for many requests whose lengths are unknown in advance. A naive implementation reserves one contiguous region for each sequence. This wastes space when the reservation is larger than the final sequence and creates fragmentation when requests finish at different times.

PagedAttention applies the virtual-memory idea to the KV cache. It divides each logical sequence into fixed-size token blocks, stores those blocks in any free physical locations, and keeps a block table for the address translation. The logical token order is unchanged; only the physical layout becomes non-contiguous.

Let $P$ be the number of tokens in one KV block and let the current sequence length be $T$. It needs $n = ceil(T / P)$ logical blocks. For a zero-based logical position $u in {0, ..., T-1}$, the logical block and its offset inside that block are

$ r(u) = floor(u / P) $

$ o(u) = u - P floor(u / P) $

If the block table maps logical block $r$ to physical block $b_r$, a K/V lookup is

$ bold(K)_("logical")[r, o] = bold(K)_("physical")[b_r, o] $

$ bold(V)_("logical")[r, o] = bold(V)_("physical")[b_r, o] $

Each physical block stores a fixed number of K/V rows:

$
  bold(K)_("physical")[b] , bold(V)_("physical")[b] in RR^(P times H_"kv" times d_h)
$

The last block may be only partially filled. When a new token arrives, the runtime writes it into the current tail block; it allocates one more physical block only when the old block becomes full. This avoids reserving the maximum context length for every request.

The block table also makes sharing explicit. Requests with a common prompt can point to the same read-only prefix blocks. During beam search or parallel sampling, several sequences can initially share all prefix blocks and allocate private blocks only after their tokens diverge. This is copy-on-write at the KV-block level, so sharing does not require copying the whole prefix.

#figure(
  html.frame(pagedattention-block-table()),
  caption: [PagedAttention preserves logical token order while translating each logical KV block to an arbitrary physical block; an append to a shared partial tail triggers block-level copy-on-write.],
) <fig-pagedattention-block-table>

Source: #link("https://arxiv.org/abs/2309.06180")[Efficient Memory Management for Large Language Model Serving with PagedAttention].

#three-line-table(
  [
    | Stage | Contiguous KV cache | PagedAttention |
    | :---- | :------------------ | :------------- |
    | Allocation | Reserve a large region per request. | Allocate fixed-size physical blocks on demand. |
    | Layout | One sequence is physically contiguous. | A block table maps logical blocks to arbitrary physical blocks. |
    | Growth | May require over-reservation or relocation. | Append into the tail block and allocate only at block boundaries. |
    | Sharing | Usually duplicates a shared prefix. | Share prefix blocks and copy only after divergence. |
  ],
)

PagedAttention does not reduce the number of K/V values required by one token. Its main benefit is higher utilization of the *same* GPU memory: less fragmentation, less over-reservation, and more sharing between requests. The attention kernel follows the block table and streams one physical K/V block at a time. It can therefore use the same online Softmax state $(bold(m), bold(l), bold(O))$ as FlashAttention even though the blocks are not contiguous in memory.

PagedAttention is especially useful with continuous batching. The scheduler can admit a new request, extend an existing request, or free finished blocks independently, while the attention kernel processes the currently active block tables. Prefix caching is a related optimization: hash complete KV blocks and reuse a matching prefix for a later request.

== Multi-head Latent Attention (MLA)

MLA is a model-architecture approach introduced by DeepSeek-V2. Its goal is to keep the quality of many attention heads while storing a much smaller representation in the KV cache. GQA shares complete K/V heads between query heads; MLA instead compresses the content of all K/V heads into one low-dimensional latent vector for each token.

For comparison, standard MHA projects the hidden state $bold(h)_t$ into one K and one V vector per head:

$ bold(k)_(t,i) = bold(h)_t bold(W)_(K,i) $

$ bold(v)_(t,i) = bold(h)_t bold(W)_(V,i) $

At decode time, these complete vectors must remain in the cache for every previous token. MLA factorizes the K and V projections through a shared latent representation:

$ bold(c)_t^"KV" = bold(h)_t bold(W)_("DKV") $

$ bold(k)_(t,i)^C = bold(c)_t^"KV" bold(W)_("UK",i) $

$ bold(v)_(t,i)^C = bold(c)_t^"KV" bold(W)_("UV",i) $

Here $bold(c)_t^"KV" in RR^d_c$ is the compressed K/V latent for token $t$, $bold(k)_(t,i)^C$ and $bold(v)_(t,i)^C$ are the content parts of head $i$, and $d_c$ is much smaller than the concatenated dimension of all K/V heads. The cache only needs $bold(c)_t^"KV"$; the per-head content K/V vectors can be produced when they are needed.

MLA can also use a low-rank query path:

$ bold(c)_t^Q = bold(h)_t bold(W)_("DQ") $

$ bold(q)_t^C = bold(c)_t^Q bold(W)_("UQ") $

Query compression mainly reduces activation and training memory. It is the K/V compression that determines the decode-time cache size.

*Why is RoPE separated?* Applying RoPE directly to the content key $bold(k)_(t,i)^C$ would place a position-dependent rotation between the up-projection $bold(W)_("UK",i)$ and the latent $bold(c)_t^"KV"$. Then the projection could no longer be absorbed into the query path, and the implementation would need to reconstruct prefix keys repeatedly. MLA therefore gives position its own small pathway:

$ bold(q)_t^R = "RoPE"(bold(c)_t^Q bold(W)_("QR")) $

$ bold(k)_t^R = "RoPE"(bold(h)_t bold(W)_("KR")) $

The query and key used by head $i$ are concatenations of content and positional parts:

$ bold(q)_(t,i) = [bold(q)_(t,i)^C; bold(q)_(t,i)^R] $

$ bold(k)_(t,i) = [bold(k)_(t,i)^C; bold(k)_t^R] $

The positional key $bold(k)_t^R$ is shared across heads. The output for the current
token is still ordinary causal attention:

$ bold(o)_(t,i) = sum_(s <= t) bold(a)_(t,s,i) bold(v)_(s,i)^C $
$
  bold(a)_(t,s,i) = "softmax"_s((bold(q)_(t,i) bold(k)_(s,i)^T) / sqrt(d_h + d_h^R))
$

The cache now stores two compact cached streams per token:

$ "MLA cache per token" = [bold(c)_t^"KV"; bold(k)_t^R] $

$ "MLA cache elements" = d_c + d_h^R $

There is no factor 2 in this expression. The single latent $bold(c)_t^"KV"$ is shared by the content K and V projections, while $bold(k)_t^R$ is the extra position-carrying key. With $B$ batches, $L$ layers, $T$ cached tokens, scalar size $s$, and the same dimensions at every layer:

$ "MLA-cache bytes" = B L T (d_c + d_h^R) s $

The reduction is not only conceptual. Because the content key is a linear projection of the latent, its score can be evaluated without materializing the full content key:

$
  bold(q)_(t,i)^C bold(k)_(s,i)^(C T)
  = bold(q)_(t,i)^C bold(W)_("UK",i)^T bold(c)_s^"KV"^T
$

The kernel can absorb $bold(W)_("UK",i)^T$ into the current query and then read the latent cache directly. The value path has a matching form:

$
  sum_s bold(a)_(t,s,i) bold(v)_(s,i)^C
  = (sum_s bold(a)_(t,s,i) bold(c)_s^"KV") bold(W)_("UV",i)
$

Thus a decode kernel can accumulate weighted latent vectors first and apply the per-head value projection afterward. In practice, implementations fuse these matrix operations into the attention kernel; the important point is that the large historical K/V tensors do not need to be stored.

#figure(
  html.frame(mla-decode-dataflow()),
  caption: [MLA decode stores a joint content latent and a decoupled RoPE key; each query head independently scores the two streams, normalizes them together, and up-projects its weighted latent.],
) <fig-mla-decode-dataflow>

#three-line-table(
  [
    | Attention | What is cached per token and layer | Elements |
    | :--------- | :-------------------------------- | --------: |
    | MHA | One complete $bold(k)$ and $bold(v)$ for every query head. | $2 H_q d_h$ |
    | GQA | Complete K/V vectors for $H_"kv"$ shared heads. | $2 H_"kv" d_h$ |
    | MQA | One complete K/V vector shared by all query heads. | $2 d_h$ |
    | MLA | One shared latent $bold(c)^"KV"$ plus one decoupled RoPE key. | $d_c + d_h^R$ |
  ],
)

For the DeepSeek-V2 configuration, $d_c = 4 d_h$ and $d_h^R = d_h / 2$, so MLA stores $4.5 d_h$ elements per token and layer. This is equivalent in cache size to GQA with about $2.25$ K/V groups, while retaining separate query-head computations. The exact quality and speed depend on the trained dimensions and the attention kernel; MLA is not a drop-in runtime switch for an arbitrary MHA checkpoint.

MLA and PagedAttention solve different parts of the system problem. MLA reduces the number of values that must be stored for each token; PagedAttention manages where those values live across many dynamic requests. They can be combined: the physical pages can store compressed latent blocks and decoupled RoPE-key blocks, while the attention kernel uses the page table and the same tile-wise online Softmax state as before.

Source: #link("https://arxiv.org/abs/2405.04434")[DeepSeek-V2: A Strong, Economical, and Efficient Mixture-of-Experts Language Model].

== How the Mainstream Techniques Fit Together

These techniques target different bottlenecks and can be composed in one serving stack:

#three-line-table(
  [
    | Technique | Main bottleneck | Core idea | Compatible with |
    | :-------- | :--------------- | :-------- | :--------------- |
    | FlashAttention | Temporary attention-matrix HBM traffic | Tile Q/K/V and merge Softmax online. | KV cache, GQA, PagedAttention |
    | Flash-Decoding | Low GPU occupancy for very short Q during decode | Split the KV sequence and reduce exact partial Softmax states. | KV cache, GQA, PagedAttention, MLA |
    | KV cache | Recomputing historical K/V | Store old keys and values for later decode steps. | All rows below |
    | GQA / MQA | K/V-head count and decode bandwidth | Share K/V heads across query heads. | FlashAttention, Flash-Decoding, PagedAttention |
    | PagedAttention | Fragmentation and dynamic allocation | Store KV in fixed-size blocks with a block table. | GQA, MLA, quantized KV |
    | MLA | KV-cache bytes per token | Cache a lower-dimensional latent representation. | PagedAttention, FlashAttention, Flash-Decoding |
    | KV quantization | Bytes and bandwidth per cached value | Store K/V with fewer bits and dequantize during attention. | GQA, PagedAttention |
    | Prefix caching / eviction | Repeated prefixes or very long contexts | Reuse shared blocks or retain only the most useful history. | PagedAttention |
  ],
)

FlashAttention, Flash-Decoding, KV cache, and PagedAttention are primarily execution and serving-system choices, so they can be combined for a fixed model. Flash-Decoding adds split-KV parallelism to the decode kernel, while PagedAttention determines where the cache blocks live. GQA and MQA change how K/V heads are produced and shared, while MLA changes the attention architecture more substantially; these choices normally belong to model training or conversion. KV quantization and eviction reduce memory further, but introduce numerical error or discard some history and must be evaluated for the target model and workload.

