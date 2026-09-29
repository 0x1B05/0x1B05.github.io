#import "@preview/cetz:0.5.2"
#import "@preview/algorithmic:1.0.7"
#import algorithmic: algorithm-figure, style-algorithm

#let flashattention-matrix-tiles() = cetz.canvas(length: .58cm, {
    import cetz.draw: *

    let base-fill = rgb("#f4f7f8")
    let base-stroke = rgb("#7b8794")
    let q-fill = rgb("#dff2e4")
    let q-stroke = rgb("#318353")
    let kv-fill = rgb("#dcecf8")
    let kv-stroke = rgb("#2878b5")
    let s-fill = rgb("#fff0c7")
    let s-stroke = rgb("#bc7e17")
    let ink = rgb("#43515f")

    content((.6, 10.55), anchor: "west", text(
      size: 8pt,
    )[*HBM: matrices partitioned by rows*])

    // Full HBM matrices. The colored row is the tile selected in this iteration.
    content((1.95, 10.0), text(size: 7pt)[$bold(Q) in RR^(N times d)$])
    rect(
      (.7, 6.75),
      (3.2, 9.65),
      fill: base-fill,
      stroke: .8pt + base-stroke,
      radius: .08,
    )
    line((.7, 8.9), (3.2, 8.9), stroke: .5pt + base-stroke)
    line((.7, 8.2), (3.2, 8.2), stroke: .5pt + base-stroke)
    rect(
      (.72, 7.48),
      (3.18, 8.18),
      fill: q-fill,
      stroke: .8pt + q-stroke,
      radius: .04,
    )
    line((.7, 7.45), (3.2, 7.45), stroke: .5pt + base-stroke)
    content((1.95, 9.28), text(size: 6.5pt)[$bold(Q)_1$])
    content((1.95, 8.55), text(size: 6.5pt)[...])
    content((1.95, 7.83), text(
      size: 6.5pt,
      fill: q-stroke,
    )[$bold(Q)_i$: $B_r times d$])
    content((1.95, 7.1), text(size: 6.5pt)[...])

    content((5.65, 10.0), text(size: 7pt)[$bold(K) in RR^(N times d)$])
    rect(
      (4.4, 6.75),
      (6.9, 9.65),
      fill: base-fill,
      stroke: .8pt + base-stroke,
      radius: .08,
    )
    line((4.4, 8.9), (6.9, 8.9), stroke: .5pt + base-stroke)
    line((4.4, 8.2), (6.9, 8.2), stroke: .5pt + base-stroke)
    rect(
      (4.42, 7.48),
      (6.88, 8.18),
      fill: kv-fill,
      stroke: .8pt + kv-stroke,
      radius: .04,
    )
    line((4.4, 7.45), (6.9, 7.45), stroke: .5pt + base-stroke)
    content((5.65, 9.28), text(size: 6.5pt)[$bold(K)_1$])
    content((5.65, 8.55), text(size: 6.5pt)[...])
    content((5.65, 7.83), text(
      size: 6.5pt,
      fill: kv-stroke,
    )[$bold(K)_j$: $B_c times d$])
    content((5.65, 7.1), text(size: 6.5pt)[...])

    content((9.35, 10.0), text(size: 7pt)[$bold(V) in RR^(N times d)$])
    rect(
      (8.1, 6.75),
      (10.6, 9.65),
      fill: base-fill,
      stroke: .8pt + base-stroke,
      radius: .08,
    )
    line((8.1, 8.9), (10.6, 8.9), stroke: .5pt + base-stroke)
    line((8.1, 8.2), (10.6, 8.2), stroke: .5pt + base-stroke)
    rect(
      (8.12, 7.48),
      (10.58, 8.18),
      fill: kv-fill,
      stroke: .8pt + kv-stroke,
      radius: .04,
    )
    line((8.1, 7.45), (10.6, 7.45), stroke: .5pt + base-stroke)
    content((9.35, 9.28), text(size: 6.5pt)[$bold(V)_1$])
    content((9.35, 8.55), text(size: 6.5pt)[...])
    content((9.35, 7.83), text(
      size: 6.5pt,
      fill: kv-stroke,
    )[$bold(V)_j$: $B_c times d$])
    content((9.35, 7.1), text(size: 6.5pt)[...])

    // The two on-chip tile calculations. Shapes are schematic, but dimensions are explicit.
    line((.6, 6.15), (17.4, 6.15), stroke: .6pt + ink)
    content((.6, 6.42), anchor: "west", text(
      size: 8pt,
    )[*On-chip SRAM: work on one selected tile pair*])

    rect(
      (.7, 4.4),
      (3.2, 5.55),
      fill: q-fill,
      stroke: .9pt + q-stroke,
      radius: .1,
    )
    content((1.95, 4.98), text(size: 6pt)[$bold(Q)_i$ ($B_r times d$)])
    content((3.65, 4.98), [$times$])
    rect(
      (4.3, 4.4),
      (6.9, 5.55),
      fill: kv-fill,
      stroke: .9pt + kv-stroke,
      radius: .1,
    )
    content((5.6, 4.98), text(size: 6pt)[$bold(K)_j^T$ ($d times B_c$)])
    content((7.55, 4.98), [$=$])
    rect(
      (8.2, 4.4),
      (10.8, 5.55),
      fill: s-fill,
      stroke: .9pt + s-stroke,
      radius: .1,
    )
    content((9.5, 4.98), text(size: 6pt)[$bold(S)_(i j)$ ($B_r times B_c$)])

    // Use Typst arrow glyphs rather than CetZ's triangular markers: the latter
    // look like detached triangles when the connector is short.
    line((9.5, 4.32), (9.5, 3.22), stroke: .8pt + s-stroke)
    content((9.5, 3.0), text(size: 11pt, fill: s-stroke)[↓])
    content((9.9, 3.6), anchor: "west", text(
      size: 6.5pt,
      fill: s-stroke,
    )[row-wise Softmax, in place])

    rect(
      (8.2, 1.7),
      (10.8, 2.85),
      fill: s-fill,
      stroke: .9pt + s-stroke,
      radius: .1,
    )
    content((9.5, 2.28), text(
      size: 6pt,
    )[$tilde(bold(P))_(i j)$ ($B_r times B_c$)])
    content((11.45, 2.28), [$times$])
    rect(
      (12.1, 1.7),
      (14.7, 2.85),
      fill: kv-fill,
      stroke: .9pt + kv-stroke,
      radius: .1,
    )
    content((13.4, 2.28), text(size: 6pt)[$bold(V)_j$ ($B_c times d$)])
    content((15.35, 2.28), [$=$])
    rect(
      (16.0, 1.7),
      (18.6, 2.85),
      fill: q-fill,
      stroke: .9pt + q-stroke,
      radius: .1,
    )
    content((17.3, 2.28), text(size: 6pt)[$Delta bold(O)_i$ ($B_r times d$)])
    line(
      (18.6, 2.28),
      (19.42, 2.28),
      stroke: .8pt + q-stroke,
      mark: (end: ">>", fill: q-stroke, scale: .75),
    )
    content((19.65, 2.28), anchor: "west", text(
      size: 6.5pt,
    )[merge with old state])

    content((14.0, 9.2), anchor: "west", text(
      size: 7pt,
      fill: q-stroke,
    )[green: query/output row tile])
    content((14.0, 8.55), anchor: "west", text(
      size: 7pt,
      fill: kv-stroke,
    )[blue: key/value row tile])
    content((14.0, 7.9), anchor: "west", text(
      size: 7pt,
      fill: s-stroke,
    )[orange: score/probability scratch tile])
    content((14.0, 7.25), anchor: "west", text(
      size: 6.5pt,
      fill: ink,
    )[Not to scale])
  })

#let kv-cache-decode() = cetz.canvas(length: .52cm, {
    import cetz.draw: *

    let neutral = rgb("#60666d")
    let neutral-line = rgb("#aeb3b8")
    let panel = rgb("#f4f6f7")
    let q-fill = rgb("#edcbcb")
    let q-stroke = rgb("#c95b5b")
    let k-fill = rgb("#c9dee5")
    let k-new = rgb("#83b2c1")
    let k-stroke = rgb("#4f8fa5")
    let v-fill = rgb("#f9d9c3")
    let v-new = rgb("#f3b789")
    let v-stroke = rgb("#d57f42")
    let out-fill = rgb("#dcd5e9")
    let out-stroke = rgb("#8a74b5")

    let arrow(from, to, paint: neutral, points: ()) = on-layer(-1, {
      line(
        from,
        ..points,
        to,
        stroke: .8pt + paint,
        mark: (end: ">>", fill: paint, scale: .68),
      )
    })

    content((.5, 6.55), anchor: "west", text(
      size: 7pt,
      weight: "semibold",
      fill: neutral,
    )[CURRENT TOKEN])
    rect(
      (.5, 4.05),
      (2.45, 5.25),
      fill: q-fill,
      stroke: .8pt + q-stroke,
      radius: .1,
      name: "x-new",
    )
    content((1.475, 4.65), text(size: 7pt)[$bold(x)_t$])

    rect(
      (3.35, 3.35),
      (5.75, 5.95),
      fill: panel,
      stroke: .7pt + neutral-line,
      radius: .1,
      name: "project",
    )
    content((4.55, 5.28), text(size: 6.2pt)[$bold(W)_Q$])
    content((4.55, 4.74), text(size: 6.2pt)[$bold(W)_K$])
    content((4.55, 4.20), text(size: 6.2pt)[$bold(W)_V$])
    content((4.55, 3.68), text(size: 5.6pt, fill: neutral)[project once])

    rect(
      (6.7, 5.35),
      (8.35, 6.15),
      fill: q-fill,
      stroke: .75pt + q-stroke,
      radius: .08,
      name: "q-new",
    )
    content((7.525, 5.75), text(size: 6.5pt)[$bold(q)_t$])
    rect(
      (6.7, 4.15),
      (8.35, 4.95),
      fill: k-new,
      stroke: .75pt + k-stroke,
      radius: .08,
      name: "k-new",
    )
    content((7.525, 4.55), text(size: 6.5pt)[$bold(k)_t$])
    rect(
      (6.7, 2.95),
      (8.35, 3.75),
      fill: v-new,
      stroke: .75pt + v-stroke,
      radius: .08,
      name: "v-new",
    )
    content((7.525, 3.35), text(size: 6.5pt)[$bold(v)_t$])

    arrow("x-new.east", "project.west", paint: q-stroke)
    arrow("project.east", "q-new.west", paint: q-stroke)
    arrow("project.east", "k-new.west", paint: k-stroke)
    arrow("project.east", "v-new.west", paint: v-stroke)

    content((9.35, 6.55), anchor: "west", text(
      size: 7pt,
      weight: "semibold",
      fill: neutral,
    )[KV CACHE AFTER APPEND])

    for i in range(5) {
      let x = 9.7 + i * 1.35
      let label = if i == 0 {
        $bold(k)_1$
      } else if i == 1 {
        $bold(k)_2$
      } else if i == 2 {
        $dots.h$
      } else if i == 3 {
        $bold(k)_(t-1)$
      } else {
        $bold(k)_t$
      }
      rect(
        (x, 4.25),
        (x + 1.2, 5.05),
        fill: if i == 4 { k-new } else { k-fill },
        stroke: .65pt + k-stroke,
        radius: .05,
        name: if i == 4 { "k-tail" } else { none },
      )
      content(
        (x + .6, 4.65),
        text(size: 5.6pt, label),
      )
    }
    rect(
      (9.62, 4.17),
      (16.38, 5.13),
      fill: none,
      stroke: .45pt + k-stroke,
      radius: .07,
      name: "k-cache",
    )

    for i in range(5) {
      let x = 9.7 + i * 1.35
      let label = if i == 0 {
        $bold(v)_1$
      } else if i == 1 {
        $bold(v)_2$
      } else if i == 2 {
        $dots.h$
      } else if i == 3 {
        $bold(v)_(t-1)$
      } else {
        $bold(v)_t$
      }
      rect(
        (x, 2.75),
        (x + 1.2, 3.55),
        fill: if i == 4 { v-new } else { v-fill },
        stroke: .65pt + v-stroke,
        radius: .05,
        name: if i == 4 { "v-tail" } else { none },
      )
      content(
        (x + .6, 3.15),
        text(size: 5.6pt, label),
      )
    }
    rect(
      (9.62, 2.67),
      (16.38, 3.63),
      fill: none,
      stroke: .45pt + v-stroke,
      radius: .07,
      name: "v-cache",
    )

    arrow("k-new.east", "k-cache.west", paint: k-stroke)
    arrow("v-new.east", "v-cache.west", paint: v-stroke)

    rect(
      (17.65, 3.15),
      (20.1, 4.65),
      fill: panel,
      stroke: .75pt + neutral,
      radius: .1,
      name: "attend",
    )
    content((18.875, 4.05), text(size: 6.5pt, weight: "semibold")[Attention])
    content((18.875, 3.68), text(size: 4.8pt, fill: neutral)[positions $1 ... t$])

    arrow(
      "q-new.east",
      (18.875, 4.65),
      paint: q-stroke,
      points: ((18.875, 5.75),),
    )
    arrow("k-cache.east", (17.65, 4.28), paint: k-stroke)
    arrow("v-cache.east", (17.65, 3.52), paint: v-stroke)

    rect(
      (21.25, 3.5),
      (22.9, 4.3),
      fill: out-fill,
      stroke: .75pt + out-stroke,
      radius: .08,
      name: "y-out",
    )
    content((22.075, 3.9), text(size: 6.5pt)[$bold(y)_t$])
    arrow("attend.east", "y-out.west", paint: out-stroke)

    content((9.7, 2.18), anchor: "west", text(
      size: 5.6pt,
      fill: neutral,
    )[light cells: reused history])
    content((9.7, 1.78), anchor: "west", text(
      size: 5.6pt,
      fill: neutral,
    )[dark tail: appended at step $t$])
    content((.5, .85), anchor: "west", text(
      size: 6.2pt,
      fill: neutral,
    )[$bold(q)_t$ is temporary; only $bold(k)_t$ and $bold(v)_t$ extend the persistent cache.])
  })

#let flash-decoding-parallel-reduction() = cetz.canvas(length: .46cm, {
    import cetz.draw: *

    let neutral = rgb("#60666d")
    let neutral-line = rgb("#aeb3b8")
    let panel = rgb("#f4f6f7")
    let q-fill = rgb("#edcbcb")
    let q-stroke = rgb("#c95b5b")
    let k-fill = rgb("#c9dee5")
    let k-stroke = rgb("#4f8fa5")
    let v-fill = rgb("#f9d9c3")
    let v-stroke = rgb("#d57f42")
    let out-fill = rgb("#dcd5e9")
    let out-stroke = rgb("#8a74b5")

    let arrow(from, to, paint: neutral, points: ()) = on-layer(-1, {
      line(
        from,
        ..points,
        to,
        stroke: .72pt + paint,
        mark: (end: ">>", fill: paint, scale: .62),
      )
    })

    let lane(base-y, rank) = {
      let lane-name = "lane-" + str(rank)
      let q-name = "q-" + str(rank)
      let k-name = "k-" + str(rank)
      let v-name = "v-" + str(rank)
      let kernel-name = "kernel-" + str(rank)
      let partial-name = "partial-" + str(rank)

      rect(
        (3.72, base-y - .02),
        (18.42, base-y + 2.65),
        fill: none,
        stroke: (
          paint: neutral-line,
          thickness: .45pt,
          dash: "dashed",
        ),
        radius: .08,
        name: lane-name,
      )
      content((18.08, base-y + 2.42), anchor: "east", text(
        size: 4.8pt,
        weight: "semibold",
        fill: neutral,
      )[PARALLEL LANE $#rank$])

      rect(
        (4.08, base-y + 1.72),
        (5.88, base-y + 2.28),
        fill: q-fill,
        stroke: .6pt + q-stroke,
        radius: .05,
        name: q-name,
      )
      content((4.98, base-y + 2.0), text(
        size: 5pt,
        fill: q-stroke,
      )[same $bold(q)_t$])

      content((7.35, base-y + 2.0), text(
        size: 4.8pt,
        weight: "semibold",
        fill: neutral,
      )[KV view $I_#rank$])
      rect(
        (4.08, base-y + .16),
        (8.88, base-y + 1.55),
        fill: none,
        stroke: (
          paint: neutral-line,
          thickness: .5pt,
          dash: "dashed",
        ),
        radius: .07,
      )
      rect(
        (4.27, base-y + .91),
        (8.69, base-y + 1.39),
        fill: k-fill,
        stroke: .55pt + k-stroke,
        radius: .04,
        name: k-name,
      )
      content((6.48, base-y + 1.15), text(
        size: 4.9pt,
      )[$bold(K)_#rank: T_#rank times d_h$])
      rect(
        (4.27, base-y + .36),
        (8.69, base-y + .84),
        fill: v-fill,
        stroke: .55pt + v-stroke,
        radius: .04,
        name: v-name,
      )
      content((6.48, base-y + .60), text(
        size: 4.9pt,
      )[$bold(V)_#rank: T_#rank times d_v$])

      rect(
        (9.55, base-y + .29),
        (14.35, base-y + 1.65),
        fill: panel,
        stroke: .65pt + neutral,
        radius: .08,
        name: kernel-name,
      )
      content((11.95, base-y + 1.20), text(
        size: 5.3pt,
        weight: "semibold",
      )[Local FlashAttention])
      content((11.95, base-y + .75), text(
        size: 4.7pt,
        fill: neutral,
      )[online Softmax over $I_#rank$])

      rect(
        (15.23, base-y + .31),
        (18.08, base-y + 1.63),
        fill: out-fill,
        stroke: .62pt + out-stroke,
        radius: .07,
        name: partial-name,
      )
      content((16.655, base-y + 1.30), text(
        size: 5.2pt,
        weight: "semibold",
      )[$(bold(o)_#rank, z_#rank)$])
      content((16.655, base-y + .88), text(
        size: 4.7pt,
      )[$bold(o)_#rank: 1 times d_v$])
      content((16.655, base-y + .51), text(
        size: 4.5pt,
        fill: neutral,
      )[$z_#rank$: logsumexp])

      // Query traffic uses the clear channel above the cache-view box.
      arrow(
        q-name + ".east",
        kernel-name + ".north",
        paint: q-stroke,
        points: (
          (6.15, base-y + 2.0),
          (6.15, base-y + 2.42),
          (11.95, base-y + 2.42),
        ),
      )
      // K and V enter the kernel horizontally at their respective row centers.
      arrow(k-name + ".east", (9.55, base-y + 1.15), paint: k-stroke)
      arrow(v-name + ".east", (9.55, base-y + .60), paint: v-stroke)
      arrow(kernel-name + ".east", partial-name + ".west", paint: out-stroke)
    }

    content((.42, 11.42), anchor: "west", text(
      size: 6.4pt,
      weight: "semibold",
      fill: neutral,
    )[ONE DECODE QUERY])
    rect(
      (.42, 10.02),
      (2.72, 11.04),
      fill: q-fill,
      stroke: .7pt + q-stroke,
      radius: .08,
      name: "query",
    )
    content((1.57, 10.73), text(size: 5.8pt, weight: "semibold")[$bold(q)_t$])
    content((1.57, 10.34), text(size: 5pt, fill: neutral)[$1 times d_h$])

    // The broadcast trunk is outside every lane; its branches end at query replicas.
    line(
      "query.east",
      (3.18, 10.53),
      (3.18, 3.18),
      stroke: .72pt + q-stroke,
    )
    content((3.4, 10.63), anchor: "west", text(
      size: 4.9pt,
      fill: q-stroke,
    )[broadcast one query])

    lane(7.38, 1)
    lane(4.28, 2)
    lane(1.18, 3)

    arrow((3.18, 9.38), "q-1.west", paint: q-stroke)
    arrow((3.18, 6.28), "q-2.west", paint: q-stroke)
    arrow((3.18, 3.18), "q-3.west", paint: q-stroke)

    content((11.07, 11.42), text(
      size: 5.7pt,
      weight: "semibold",
      fill: neutral,
    )[at step $t$: $T = t$ cached positions])
    content((11.07, 10.92), text(
      size: 4.9pt,
      fill: neutral,
    )[$T_r > 0$; views $I_r$ and $I_s$ do not overlap for $r != s$])

    rect(
      (19.43, 3.55),
      (24.96, 8.55),
      fill: panel,
      stroke: .72pt + neutral,
      radius: .1,
      name: "combine",
    )
    content((22.195, 8.08), text(
      size: 5.8pt,
      weight: "semibold",
    )[COMBINE SPLITS])
    content((22.195, 6.38), text(size: 5.4pt)[
      $
        z &:= "logsumexp"_r(z_r) \
        alpha_r &:= e^(z_r - z) \
        bold(o)_t &:= sum_r alpha_r bold(o)_r
      $
    ])
    content((22.195, 4.25), align(center, text(
      size: 4.8pt,
      fill: neutral,
    )[
      global Softmax output
      #linebreak()
      $bold(o)_t: 1 times d_v$
    ]))

    // Partial-state traffic has one clear horizontal route per lane.
    arrow("partial-1.east", (19.43, 7.62), paint: out-stroke, points: ((18.72, 8.35), (18.72, 7.62)))
    arrow("partial-2.east", (19.43, 6.05), paint: out-stroke, points: ((18.72, 5.25), (18.72, 6.05)))
    arrow("partial-3.east", (19.43, 4.22), paint: out-stroke, points: ((18.72, 2.15), (18.72, 4.22)))

    content((.42, .63), anchor: "west", text(
      size: 5.2pt,
      fill: neutral,
    )[Illustration: $S = 3$; each split is a KV-cache view, so K/V is not copied.])
    content((13.7, .63), anchor: "west", text(
      size: 5.2pt,
      fill: neutral,
    )[Each lane streams tiles; the score row is never materialized.])
    content((.42, .18), anchor: "west", text(
      size: 4.8pt,
      fill: neutral,
    )[One token is decoded exactly; this is KV-sequence parallelism, not speculative decoding.])
  })

#let mha-gqa-mqa-head-sharing() = cetz.canvas(length: .53cm, {
    import cetz.draw: *

    let neutral = rgb("#60666d")
    let neutral-line = rgb("#aeb3b8")
    let q-fill = rgb("#edcbcb")
    let q-stroke = rgb("#c95b5b")
    let k-fill = rgb("#c9dee5")
    let k-stroke = rgb("#4f8fa5")
    let v-fill = rgb("#f9d9c3")
    let v-stroke = rgb("#d57f42")
    let out-fill = rgb("#dcd5e9")
    let out-stroke = rgb("#8a74b5")

    let panel(x0, title, hkv, group-size, cache-size) = {
      let panel-width = 7.1
      let left = x0 + .65
      let row-width = 5.8
      let q-gap = .08
      let q-width = (row-width - 7 * q-gap) / 8
      let group-gap = .14
      let group-width = (row-width - (hkv - 1) * group-gap) / hkv

      content((x0 + panel-width / 2, 7.35), text(
        title,
        size: 7pt,
        weight: "semibold",
      ))
      content((x0 + panel-width / 2, 6.92), text(
        size: 5.5pt,
        fill: neutral,
      )[$H_q = 8$, $H_"kv" = #hkv$])

      content((x0 + .12, 6.2), anchor: "east", text(
        size: 5.2pt,
        fill: q-stroke,
      )[Q])
      for i in range(8) {
        let x = left + i * (q-width + q-gap)
        rect(
          (x, 5.78),
          (x + q-width, 6.42),
          fill: q-fill,
          stroke: .55pt + q-stroke,
          radius: .04,
        )
        content(
          (x + q-width / 2, 6.1),
          text("q" + str(i), size: 4.5pt),
        )

        let group = calc.floor(i / group-size)
        let group-center = left + group * (group-width + group-gap) + group-width / 2
        on-layer(-1, {
          line(
            (x + q-width / 2, 5.78),
            (group-center, 4.77),
            stroke: .45pt + neutral-line,
          )
        })
      }

      rect(
        (left - .15, 3.23),
        (left + row-width + .15, 4.92),
        fill: none,
        stroke: (
          paint: neutral-line,
          thickness: .55pt,
          dash: "dashed",
        ),
        radius: .08,
      )
      content((left + row-width / 2, 3.02), text(
        size: 4.9pt,
        fill: neutral,
      )[persistent KV cache])
      for group in range(hkv) {
        let x = left + group * (group-width + group-gap)
        rect(
          (x, 4.08),
          (x + group-width, 4.77),
          fill: k-fill,
          stroke: .55pt + k-stroke,
          radius: .04,
        )
        content(
          (x + group-width / 2, 4.425),
          text("K" + str(group), size: 4.8pt),
        )
        rect(
          (x, 3.38),
          (x + group-width, 4.07),
          fill: v-fill,
          stroke: .55pt + v-stroke,
          radius: .04,
        )
        content(
          (x + group-width / 2, 3.725),
          text("V" + str(group), size: 4.8pt),
        )
      }

      content((x0 + .12, 2.42), anchor: "east", text(
        size: 5.2pt,
        fill: out-stroke,
      )[O])
      for i in range(8) {
        let x = left + i * (q-width + q-gap)
        rect(
          (x, 2.1),
          (x + q-width, 2.74),
          fill: out-fill,
          stroke: .55pt + out-stroke,
          radius: .04,
        )
        content(
          (x + q-width / 2, 2.42),
          text("o" + str(i), size: 4.5pt),
        )
      }
      content((x0 + panel-width / 2, 1.58), text(
        size: 5.2pt,
        fill: neutral,
      )[8 independent Softmax states and outputs])
      content((x0 + panel-width / 2, .95), text(
        size: 5.6pt,
        weight: "semibold",
      )[cache: #cache-size])
    }

    panel(.0, [MHA], 8, 1, [$16 d_h$])
    panel(7.85, [GQA ($g = 4$)], 2, 4, [$4 d_h$])
    panel(15.7, [MQA], 1, 8, [$2 d_h$])

    line((7.5, .65), (7.5, 7.55), stroke: .45pt + neutral-line)
    line((15.35, .65), (15.35, 7.55), stroke: .45pt + neutral-line)
    content((11.55, .3), text(
      size: 5.5pt,
      fill: neutral,
    )[Association lines mean “uses”; sharing K/V does not share attention weights or outputs.])
  })

#let pagedattention-block-table() = cetz.canvas(length: .51cm, {
    import cetz.draw: *

    let neutral = rgb("#60666d")
    let neutral-line = rgb("#aeb3b8")
    let free-fill = rgb("#f4f6f7")
    let k-fill = rgb("#c9dee5")
    let v-fill = rgb("#f9d9c3")
    let shared-fill = rgb("#dcd5e9")
    let shared-stroke = rgb("#8a74b5")
    let private-fill = rgb("#edcbcb")
    let private-stroke = rgb("#c95b5b")
    let allocated-stroke = rgb("#4f8fa5")

    let arrow(from, to, paint: neutral, points: (), dashed: false) = on-layer(-1, {
      line(
        from,
        ..points,
        to,
        stroke: (
          paint: paint,
          thickness: .7pt,
          dash: if dashed { "dashed" } else { "solid" },
        ),
        mark: (end: ">>", fill: paint, scale: .62),
      )
    })

    let logical-block(x, label, tokens, valid: 4, stroke: allocated-stroke) = {
      content((x + 1.55, 9.62), text(label, size: 5.8pt, weight: "semibold"))
      for slot in range(4) {
        let sx = x + .15 + slot * .72
        let is-valid = slot < valid
        rect(
          (sx, 8.35),
          (sx + .64, 9.17),
          fill: if is-valid { k-fill } else { white },
          stroke: (
            paint: if is-valid { stroke } else { neutral-line },
            thickness: .55pt,
            dash: if is-valid { "solid" } else { "dashed" },
          ),
          radius: .035,
        )
        content(
          (sx + .32, 8.76),
          text(tokens.at(slot), size: 4.7pt, fill: if is-valid { black } else { neutral }),
        )
      }
      rect(
        (x, 8.16),
        (x + 3.1, 9.35),
        fill: none,
        stroke: .55pt + stroke,
        radius: .07,
      )
    }

    let physical-block(x, y, id, origin: none, valid: 0, stroke: neutral-line, name: none) = {
      rect(
        (x, y),
        (x + 2.65, y + 1.25),
        fill: if valid == 0 { free-fill } else { white },
        stroke: .6pt + stroke,
        radius: .06,
        name: name,
      )
      content((x + .12, y + 1.06), anchor: "west", text(
        if origin == none {
          "#" + str(id) + "  free"
        } else {
          "#" + str(id) + "  <- " + origin
        },
        size: 4.8pt,
        fill: if valid == 0 { neutral } else { stroke },
        weight: if valid == 0 { "regular" } else { "semibold" },
      ))
      if valid > 0 {
        for row in range(2) {
          for slot in range(4) {
            let sx = x + .14 + slot * .59
            let sy = y + .12 + row * .35
            let is-valid = slot < valid
            rect(
              (sx, sy),
              (sx + .52, sy + .28),
              fill: if is-valid {
                if row == 1 { k-fill } else { v-fill }
              } else {
                white
              },
              stroke: (
                paint: if is-valid { stroke } else { neutral-line },
                thickness: .4pt,
                dash: if is-valid { "solid" } else { "dashed" },
              ),
              radius: .02,
            )
          }
        }
      }
    }

    content((.45, 10.6), anchor: "west", text(
      size: 6.8pt,
      weight: "semibold",
    )[A. LOGICAL ORDER TO PHYSICAL KV BLOCKS])
    content((.45, 10.18), anchor: "west", text(
      size: 5.2pt,
      fill: neutral,
    )[$P = 4$, $T_A = 10$; one physical block contains aligned K and V rows.])

    logical-block(.55, [$L_0$], ($u_0$, $u_1$, $u_2$, $u_3$), stroke: shared-stroke)
    logical-block(4.1, [$L_1$], ($u_4$, $u_5$, $u_6$, $u_7$))
    logical-block(7.65, [$L_2$], ($u_8$, $u_9$, $times$, $times$), valid: 2, stroke: private-stroke)

    content((.9, 7.165), anchor: "east", text(
      size: 5.2pt,
      fill: neutral,
    )[$"BT"_A = $])
    let table-entries = (
      (x: 1.05, id: 7, stroke: shared-stroke, name: "bt-7"),
      (x: 4.6, id: 1, stroke: allocated-stroke, name: "bt-1"),
      (x: 8.15, id: 5, stroke: private-stroke, name: "bt-5"),
    )
    for entry in table-entries {
      rect(
        (entry.x, 6.78),
        (entry.x + 2.05, 7.55),
        fill: white,
        stroke: .65pt + entry.stroke,
        radius: .05,
        name: entry.name,
      )
      content((entry.x + 1.025, 7.165), text(
        "#" + str(entry.id),
        size: 5.6pt,
        weight: "semibold",
        fill: entry.stroke,
      ))
    }
    line((2.1, 8.16), (2.1, 7.55), stroke: .45pt + shared-stroke)
    line((5.65, 8.16), (5.65, 7.55), stroke: .45pt + allocated-stroke)
    line((9.2, 8.16), (9.2, 7.55), stroke: .45pt + private-stroke)

    content((.55, 5.78), anchor: "west", text(
      size: 5.5pt,
      weight: "semibold",
      fill: neutral,
    )[PHYSICAL BLOCK POOL])
    content((.55, 5.42), anchor: "west", text(
      size: 4.7pt,
      fill: neutral,
    )[physical-ID order])

    let phys-x = (.55, 3.65, 6.75, 9.85)
    physical-block(phys-x.at(0), 3.75, 0)
    physical-block(phys-x.at(1), 3.75, 1, origin: "L1", valid: 4, stroke: allocated-stroke, name: "phys-1")
    physical-block(phys-x.at(2), 3.75, 2)
    physical-block(phys-x.at(3), 3.75, 3)
    physical-block(phys-x.at(0), 1.85, 4)
    physical-block(phys-x.at(1), 1.85, 5, origin: "L2", valid: 2, stroke: private-stroke, name: "phys-5")
    physical-block(phys-x.at(2), 1.85, 6)
    physical-block(phys-x.at(3), 1.85, 7, origin: "L0", valid: 4, stroke: shared-stroke, name: "phys-7")

    arrow(
      "bt-7.south",
      "phys-7.south",
      paint: shared-stroke,
      points: (
        (2.075, 6.25),
        (.15, 6.25),
        (.15, 1.55),
        (11.175, 1.55),
      ),
    )
    arrow(
      "bt-1.south",
      "phys-1.north",
      paint: allocated-stroke,
      points: ((5.625, 5.2), (4.975, 5.2)),
    )
    arrow(
      "bt-5.south",
      "phys-5.north",
      paint: private-stroke,
      points: (
        (9.175, 5.15),
        (9.62, 5.15),
        (9.62, 3.35),
        (4.975, 3.35),
      ),
    )
    content((.55, 1.28), anchor: "west", text(
      size: 5.2pt,
      fill: neutral,
    )[The kernel follows $[7, 1, 5]$ in logical order; dashed white slots are invalid.])

    line((13.75, 1.2), (13.75, 10.65), stroke: .55pt + neutral-line)

    content((14.35, 10.6), anchor: "west", text(
      size: 6.8pt,
      weight: "semibold",
    )[B. SHARED PREFIX AND COPY-ON-WRITE])
    content((14.35, 10.18), anchor: "west", text(
      size: 5.2pt,
      fill: neutral,
    )[Two branches initially reference the same prefix and partially filled tail.])

    let table-row(y, label, ids, second-stroke: shared-stroke) = {
      content((14.55, y + .39), anchor: "east", text(
        label,
        size: 5.5pt,
        weight: "semibold",
      ))
      for i in range(2) {
        let x = 14.85 + i * 1.55
        let stroke = if i == 0 { shared-stroke } else { second-stroke }
        rect(
          (x, y),
          (x + 1.3, y + .78),
          fill: if stroke == private-stroke { private-fill } else { shared-fill },
          stroke: .6pt + stroke,
          radius: .045,
        )
        content((x + .65, y + .39), text(
          "#" + str(ids.at(i)),
          size: 5.3pt,
          fill: stroke,
          weight: "semibold",
        ))
      }
    }

    content((14.35, 9.42), anchor: "west", text(
      size: 5.2pt,
      weight: "semibold",
      fill: neutral,
    )[BEFORE APPEND])
    table-row(8.35, [A], (7, 1))
    table-row(7.32, [B], (7, 1))
    content((18.5, 8.68), anchor: "west", text(
      "ref(#1) = 2",
      size: 5.1pt,
      fill: shared-stroke,
    ))

    arrow(
      (17.7, 8.74),
      (17.7, 5.04),
      paint: private-stroke,
      points: ((18.1, 8.74), (18.1, 5.04)),
    )
    content((18.45, 6.62), anchor: "west", text(
      size: 5.1pt,
      fill: private-stroke,
    )[A appends $u_6$])

    content((14.35, 5.72), anchor: "west", text(
      size: 5.2pt,
      weight: "semibold",
      fill: neutral,
    )[AFTER COW])
    table-row(4.65, [A], (7, 3), second-stroke: private-stroke)
    table-row(3.62, [B], (7, 1), second-stroke: allocated-stroke)
    content((18.4, 4.95), anchor: "west", text(
      "shared #7: ref = 2",
      size: 4.8pt,
      fill: neutral,
    ))
    content((18.4, 4.55), anchor: "west", text(
      "#1: ref = 1; #3: ref = 1",
      size: 4.8pt,
      fill: neutral,
    ))

    let tail-block(x, id, labels, valid, fill, stroke, name) = {
      content((x, 2.67), anchor: "west", text(
        "#" + str(id),
        size: 5.2pt,
        fill: stroke,
        weight: "semibold",
      ))
      for slot in range(4) {
        let sx = x + slot * .79
        let is-valid = slot < valid
        rect(
          (sx, 1.65),
          (sx + .69, 2.4),
          fill: if is-valid { fill } else { white },
          stroke: (
            paint: if is-valid { stroke } else { neutral-line },
            thickness: .5pt,
            dash: if is-valid { "solid" } else { "dashed" },
          ),
          radius: .035,
          name: if slot == 0 { name } else { none },
        )
        content((sx + .345, 2.025), text(
          labels.at(slot),
          size: 4.5pt,
          fill: if is-valid { black } else { neutral },
        ))
      }
    }

    content((14.45, 3.12), anchor: "west", text(
      size: 4.8pt,
      fill: neutral,
    )[Each slot represents paired K/V rows.])
    tail-block(
      14.45,
      1,
      ($u_4$, $u_5$, $times$, $times$),
      2,
      shared-fill,
      allocated-stroke,
      "tail-1",
    )
    tail-block(
      19.0,
      3,
      ($u_4$, $u_5$, $A_6$, $times$),
      3,
      private-fill,
      private-stroke,
      "tail-3",
    )
    arrow(
      (17.65, 2.4),
      (19.0, 2.4),
      paint: private-stroke,
      dashed: true,
    )
    content((14.45, 1.12), anchor: "west", text(
      size: 5.0pt,
      fill: neutral,
    )[Dashed arrow: copy occupied K/V slots; the complete prefix is not duplicated.])
  })

#let mla-decode-dataflow() = cetz.canvas(length: .50cm, {
    import cetz.draw: *

    let neutral = rgb("#60666d")
    let neutral-line = rgb("#aeb3b8")
    let panel = rgb("#f4f6f7")
    let q-fill = rgb("#edcbcb")
    let q-stroke = rgb("#c95b5b")
    let latent-fill = rgb("#dcd5e9")
    let latent-stroke = rgb("#8a74b5")
    let rope-fill = rgb("#c9dee5")
    let rope-stroke = rgb("#4f8fa5")
    let value-fill = rgb("#f9d9c3")
    let value-stroke = rgb("#d57f42")

    let arrow(from, to, paint: neutral, points: (), dashed: false) = on-layer(-1, {
      line(
        from,
        ..points,
        to,
        stroke: (
          paint: paint,
          thickness: .7pt,
          dash: if dashed { "dashed" } else { "solid" },
        ),
        mark: (end: ">>", fill: paint, scale: .62),
      )
    })

    content((.45, 10.45), anchor: "west", text(
      size: 6.8pt,
      weight: "semibold",
    )[A. WHAT MLA CACHES])
    content((.45, 10.02), anchor: "west", text(
      size: 4.9pt,
      fill: neutral,
    )[Persistent: joint KV latent + decoupled RoPE key.])

    rect(
      (.55, 7.05),
      (1.95, 7.95),
      fill: panel,
      stroke: .65pt + neutral,
      radius: .07,
      name: "mla-h",
    )
    content((1.25, 7.5), text(size: 5.8pt)[$bold(h)_t$])

    rect(
      (2.65, 6.65),
      (4.25, 8.35),
      fill: panel,
      stroke: .65pt + neutral,
      radius: .07,
      name: "mla-project",
    )
    content((3.45, 7.84), text(size: 5.0pt)[$bold(W)_("DQ")$])
    content((3.45, 7.47), text(size: 5.0pt)[$bold(W)_("DKV")$])
    content((3.45, 7.04), text(
      size: 4.3pt,
      fill: neutral,
    )[low-rank])

    rect(
      (4.95, 8.15),
      (8.05, 9.0),
      fill: q-fill,
      stroke: .65pt + q-stroke,
      radius: .06,
      name: "mla-cq",
    )
    content((6.5, 8.67), text(size: 5.7pt)[$bold(c)_t^Q$])
    content((6.5, 8.37), text(size: 4.3pt, fill: q-stroke)[query only; temporary])

    rect(
      (4.95, 6.25),
      (6.35, 7.15),
      fill: latent-fill,
      stroke: .65pt + latent-stroke,
      radius: .06,
      name: "mla-ckv-new",
    )
    content((5.65, 6.7), text(size: 5.4pt)[$bold(c)_t^"KV"$])

    rect(
      (2.65, 5.35),
      (4.25, 6.2),
      fill: rope-fill,
      stroke: .65pt + rope-stroke,
      radius: .06,
      name: "mla-kr-new",
    )
    content((3.45, 5.775), text(size: 5.4pt)[$bold(k)_t^R$])

    rect(
      (.55, 5.35),
      (2.1, 6.2),
      fill: panel,
      stroke: .65pt + neutral,
      radius: .06,
      name: "mla-kr-project",
    )
    content((1.325, 5.87), text(size: 5.0pt)[$bold(W)_("KR")$])
    content((1.325, 5.55), text("+ RoPE", size: 4.2pt, fill: neutral))

    arrow("mla-h.east", "mla-project.west")
    arrow("mla-h.south", "mla-kr-project.north", paint: rope-stroke)
    arrow("mla-project.east", "mla-cq.west", paint: q-stroke)
    arrow("mla-project.east", "mla-ckv-new.west", paint: latent-stroke)
    arrow("mla-kr-project.east", "mla-kr-new.west", paint: rope-stroke)

    rect(
      (.55, 1.15),
      (8.35, 5.1),
      fill: none,
      stroke: (
        paint: neutral-line,
        thickness: .6pt,
        dash: "dashed",
      ),
      radius: .08,
      name: "mla-cache",
    )
    content((.85, 4.68), anchor: "west", text(
      size: 5.0pt,
      weight: "semibold",
      fill: neutral,
    )[PREFIX CACHE (AFTER APPEND)])

    let latent-labels = (
      $bold(c)_1^"KV"$,
      $bold(c)_2^"KV"$,
      $dots.h$,
      $bold(c)_t^"KV"$,
    )
    let rope-labels = (
      $bold(k)_1^R$,
      $bold(k)_2^R$,
      $dots.h$,
      $bold(k)_t^R$,
    )
    for i in range(4) {
      let x = 1.05 + i * 1.72
      rect(
        (x, 3.05),
        (x + 1.5, 3.83),
        fill: latent-fill,
        stroke: .55pt + latent-stroke,
        radius: .04,
      )
      content((x + .75, 3.44), text(latent-labels.at(i), size: 4.8pt))
      rect(
        (x, 1.75),
        (x + 1.5, 2.53),
        fill: rope-fill,
        stroke: .55pt + rope-stroke,
        radius: .04,
      )
      content((x + .75, 2.14), text(rope-labels.at(i), size: 4.8pt))
    }
    arrow("mla-ckv-new.south", (5.65, 5.1), paint: latent-stroke)
    arrow("mla-kr-new.south", (3.45, 5.1), paint: rope-stroke)
    content((4.45, .62), text(
      size: 5.2pt,
      fill: neutral,
    )[cache per token: $d_c + d_h^R$ elements])

    line((8.85, .55), (8.85, 10.55), stroke: .55pt + neutral-line)

    content((9.35, 10.45), anchor: "west", text(
      size: 6.8pt,
      weight: "semibold",
    )[B. HOW QUERY HEAD $i$ READS THE CACHE])
    content((9.35, 10.02), anchor: "west", text(
      size: 5.1pt,
      fill: neutral,
    )[Repeat this lane for $i = 0, ..., H_q - 1$; every head keeps its own Softmax state.])

    rect(
      (9.7, 8.15),
      (13.15, 9.2),
      fill: q-fill,
      stroke: .65pt + q-stroke,
      radius: .06,
      name: "mla-q-content",
    )
    content((11.425, 8.88), text(size: 5.4pt)[$hat(bold(q))_i^C$])
    content((11.425, 8.43), text(size: 4.2pt, fill: q-stroke)[absorbed content query])

    rect(
      (9.7, 6.7),
      (13.15, 7.75),
      fill: latent-fill,
      stroke: .65pt + latent-stroke,
      radius: .06,
      name: "mla-c-cache-read",
    )
    content((11.425, 7.43), text(size: 5.3pt)[$bold(C)_(1:t)^"KV"$])
    content((11.425, 6.98), text(size: 4.2pt, fill: latent-stroke)[$t times d_c$ cached latent])

    rect(
      (14.15, 7.55),
      (16.75, 8.4),
      fill: panel,
      stroke: .65pt + neutral,
      radius: .06,
      name: "mla-content-score",
    )
    content((15.45, 8.09), text(size: 5.5pt)[$bold(s)_i^C$])
    content((15.45, 7.77), text(size: 4.2pt, fill: neutral)[content scores])
    arrow("mla-q-content.east", (14.15, 8.18), paint: q-stroke)
    arrow("mla-c-cache-read.east", (14.15, 7.78), paint: latent-stroke)

    rect(
      (9.7, 5.15),
      (13.15, 6.2),
      fill: q-fill,
      stroke: .65pt + q-stroke,
      radius: .06,
      name: "mla-q-rope",
    )
    content((11.425, 5.88), text(size: 5.4pt)[$bold(q)_i^R$])
    content((11.425, 5.43), text(size: 4.2pt, fill: q-stroke)[current RoPE query])

    rect(
      (9.7, 3.7),
      (13.15, 4.75),
      fill: rope-fill,
      stroke: .65pt + rope-stroke,
      radius: .06,
      name: "mla-k-rope-read",
    )
    content((11.425, 4.43), text(size: 5.3pt)[$bold(K)_(1:t)^R$])
    content((11.425, 3.98), text(size: 4.2pt, fill: rope-stroke)[$t times d_h^R$ cached keys])

    rect(
      (14.15, 4.55),
      (16.75, 5.4),
      fill: panel,
      stroke: .65pt + neutral,
      radius: .06,
      name: "mla-rope-score",
    )
    content((15.45, 5.09), text(size: 5.5pt)[$bold(s)_i^R$])
    content((15.45, 4.77), text(size: 4.2pt, fill: neutral)[position scores])
    arrow("mla-q-rope.east", (14.15, 5.18), paint: q-stroke)
    arrow("mla-k-rope-read.east", (14.15, 4.78), paint: rope-stroke)

    rect(
      (17.55, 6.05),
      (18.45, 6.95),
      fill: panel,
      stroke: .65pt + neutral,
      radius: .45,
      name: "mla-score-sum",
    )
    content((18.0, 6.5), text(size: 7pt)[+])
    arrow(
      "mla-content-score.east",
      "mla-score-sum.north",
      points: ((17.1, 7.975), (18.0, 7.975)),
    )
    arrow(
      "mla-rope-score.east",
      "mla-score-sum.south",
      points: ((17.1, 4.975), (18.0, 4.975)),
    )

    rect(
      (19.15, 6.05),
      (21.3, 6.95),
      fill: panel,
      stroke: .65pt + neutral,
      radius: .06,
      name: "mla-softmax",
    )
    content((20.225, 6.64), text(size: 5.0pt)[Softmax])
    content((20.225, 6.34), text(
      size: 4.1pt,
      fill: neutral,
    )[over $s = 1, ..., t$])
    rect(
      (22.0, 6.05),
      (23.35, 6.95),
      fill: value-fill,
      stroke: .65pt + value-stroke,
      radius: .06,
      name: "mla-weights",
    )
    content((22.675, 6.5), text(size: 5.5pt)[$bold(a)_i$])
    arrow("mla-score-sum.east", "mla-softmax.west")
    arrow("mla-softmax.east", "mla-weights.west", paint: value-stroke)

    content((9.7, 3.22), anchor: "west", text(
      size: 5.1pt,
      weight: "semibold",
      fill: neutral,
    )[VALUE PATH: REDUCE IN LATENT SPACE, THEN UP-PROJECT])
    rect(
      (9.7, 2.05),
      (13.1, 2.85),
      fill: latent-fill,
      stroke: .65pt + latent-stroke,
      radius: .06,
      name: "mla-c-value",
    )
    content((11.4, 2.45), text(size: 5.2pt)[$bold(C)_(1:t)^"KV"$])
    rect(
      (9.7, .85),
      (13.1, 1.65),
      fill: value-fill,
      stroke: .65pt + value-stroke,
      radius: .06,
      name: "mla-a-value",
    )
    content((11.4, 1.25), text(size: 5.2pt)[$bold(a)_i$])
    rect(
      (14.15, 1.45),
      (17.55, 2.35),
      fill: panel,
      stroke: .65pt + neutral,
      radius: .06,
      name: "mla-z",
    )
    content((15.85, 1.98), text(size: 5.4pt)[$bold(z)_i$])
    content((15.85, 1.66), text(size: 4.2pt, fill: neutral)[$d_c$ weighted latent])
    arrow("mla-c-value.east", (14.15, 2.14), paint: latent-stroke)
    arrow("mla-a-value.east", (14.15, 1.66), paint: value-stroke)

    rect(
      (18.25, 1.45),
      (20.55, 2.35),
      fill: panel,
      stroke: .65pt + neutral,
      radius: .06,
      name: "mla-wuv",
    )
    content((19.4, 1.9), text(size: 5.2pt)[$bold(W)_("UV",i)$])
    rect(
      (21.25, 1.45),
      (22.75, 2.35),
      fill: value-fill,
      stroke: .65pt + value-stroke,
      radius: .06,
      name: "mla-output",
    )
    content((22.0, 1.9), text(size: 5.5pt)[$bold(o)_i$])
    arrow("mla-z.east", "mla-wuv.west")
    arrow("mla-wuv.east", "mla-output.west", paint: value-stroke)
    content((19.95, .62), text(
      size: 5.0pt,
      fill: neutral,
    )[Full historical content K/V tensors are neither cached nor materialized.])
  })

#let flashattention-forward() = {
  show: style-algorithm.with(breakable: true, caption-style: strong)
  text(size: 10pt)[
#algorithm-figure(
  "FlashAttention forward pass",
  inset: .38em,
  indent: .65em,
  vstroke: .4pt + luma(210),
  {
    import algorithmic: *

    Line[
      *Require:* $bold(Q), bold(K), bold(V) in RR^(N times d)$ in HBM; on-chip SRAM capacity $M$.
    ]
    Line[
      Set $B_c = ceil(M / (4d))$ and $B_r = min(ceil(M / (4d)), d)$.
    ]
    Line[
      Initialize $bold(O) = bold(0)_(N times d)$, $bold(l) = bold(0)_N$, and $bold(m) = -infinity_N$ in HBM.
    ]
    Line[
      Partition $bold(Q)$ into $T_r = ceil(N / B_r)$ query tiles; partition $bold(K)$ and $bold(V)$ into $T_c = ceil(N / B_c)$ tiles.
    ]
    Line[
      Partition $bold(O)$, $bold(l)$, and $bold(m)$ into $T_r$ row-aligned state tiles.
    ]
    For($1 <= j <= T_c$, {
      Line[Load $bold(K)_j$ and $bold(V)_j$ from HBM into on-chip SRAM.]
      For($1 <= i <= T_r$, {
        Line[Load $bold(Q)_i$, $bold(O)_i$, $bold(l)_i$, and $bold(m)_i$ from HBM into on-chip SRAM.]
        Line[Compute $bold(S)_(i j) = bold(Q)_i bold(K)_j^T in RR^(B_r times B_c)$.]
        Line[Compute $tilde(m)_(i j) = "rowmax"(bold(S)_(i j))$ and $tilde(bold(P))_(i j) = exp(bold(S)_(i j) - tilde(m)_(i j))$.]
        Line[Compute $tilde(l)_(i j) = "rowsum"(tilde(bold(P))_(i j))$.]
        Line[
          Update $bold(m)_i^"new" = max(bold(m)_i, tilde(m)_(i j))$ and $bold(l)_i^"new" = e^(bold(m)_i-bold(m)_i^"new") bold(l)_i + e^(tilde(m)_(i j)-bold(m)_i^"new") tilde(l)_(i j)$.
        ]
        Line[
          Update $bold(O)_i <- "diag"(bold(l)_i^"new")^(-1) ("diag"(bold(l)_i) e^(bold(m)_i-bold(m)_i^"new") bold(O)_i + e^(tilde(m)_(i j)-bold(m)_i^"new") tilde(bold(P))_(i j) bold(V)_j)$.
        ]
        Line[Write $bold(O)_i$, $bold(l)_i^"new"$, and $bold(m)_i^"new"$ from SRAM back to HBM.]
      })
    })
    Return[$bold(O)$]
  },
)
]
}
