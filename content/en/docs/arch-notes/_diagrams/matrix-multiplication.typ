#import "@preview/cetz:0.5.2" as cetz
#import "tensor-viz.typ": palette, neutral, neutral-dark, neutral-line, panel-fill

#let _matrix-multiplication-diagram(tiled: false) = cetz.canvas(
  length: .72cm,
  padding: .2,
  {
    import cetz.draw: *

    // The shared physical lengths make the contracted and free dimensions
    // line up across A (M x P), B (P x N), and C (M x N).
    let p = 5.0
    let m = 4.0
    let n = 4.3
    let gap = .25
    let bx = p + gap
    let by = m + gap
    let right = bx + n
    let ink = rgb("#202124")

    let horizontal-dimension(x1, x2, y, body) = {
      line(
        (x1, y),
        (x2, y),
        stroke: (paint: neutral-dark, thickness: .62pt),
        mark: (start: ">", end: ">", scale: .42),
      )
      content(
        ((x1 + x2) / 2, y - .32),
        box(fill: white, inset: 1.2pt, text(size: 6.3pt, fill: neutral-dark, body)),
      )
    }

    let vertical-dimension(x, y1, y2, body) = {
      line(
        (x, y1),
        (x, y2),
        stroke: (paint: neutral-dark, thickness: .62pt),
        mark: (start: ">", end: ">", scale: .42),
      )
      content(
        (x + .36, (y1 + y2) / 2),
        box(fill: white, inset: 1.2pt, text(size: 6.3pt, fill: neutral-dark, body)),
      )
    }

    // Matrix bodies are placed below arrows and labels.
    on-layer(-2, {
      rect(
        (0, 0),
        (p, m),
        fill: palette.teal.light,
        stroke: (paint: palette.teal.dark, thickness: .75pt),
        name: if tiled { "tiled-a" } else { "naive-a" },
      )
      rect(
        (bx, by),
        (right, by + p),
        fill: palette.orange.light,
        stroke: (paint: palette.orange.dark, thickness: .75pt),
        name: if tiled { "tiled-b" } else { "naive-b" },
      )
      rect(
        (bx, 0),
        (right, m),
        fill: palette.coral.light,
        stroke: (paint: palette.coral.dark, thickness: .75pt),
        name: if tiled { "tiled-c" } else { "naive-c" },
      )
    })

    // Matrix names and global shape annotations are identical in both views.
    content((.28, m - .34), text(size: 8.5pt, weight: "bold", fill: ink)[A])
    content((bx + .28, by + p - .34), text(size: 8.5pt, weight: "bold", fill: ink)[B])
    content((bx + .28, m - .34), text(size: 8.5pt, weight: "bold", fill: ink)[C])

    horizontal-dimension(0, p, -.58, [$P$])
    horizontal-dimension(bx, right, -.58, [$N$])
    vertical-dimension(right + .58, 0, m, [$M$])
    vertical-dimension(right + .58, by, by + p, [$P$])

    if not tiled {
      let row-y = 1.55
      let col-x = bx + 2.45

      on-layer(-1, {
        // The selected A row and B column meet at one output element.
        line((0, row-y), (p, row-y), stroke: (paint: palette.teal.dark, thickness: 2.2pt))
        line((col-x, by), (col-x, by + p), stroke: (paint: palette.orange.dark, thickness: 2.2pt))
        line(
          (p, row-y),
          (col-x, row-y),
          stroke: (paint: neutral-line, thickness: .65pt, dash: "dashed"),
        )
        line(
          (col-x, by),
          (col-x, row-y),
          stroke: (paint: neutral-line, thickness: .65pt, dash: "dashed"),
        )
        line(
          (.65, row-y - .43),
          (p - .48, row-y - .43),
          stroke: (paint: neutral-dark, thickness: .68pt),
          mark: (end: ">", scale: .48),
        )
        line(
          (col-x - .43, by + p - .65),
          (col-x - .43, by + .55),
          stroke: (paint: neutral-dark, thickness: .68pt),
          mark: (end: ">", scale: .48),
        )
      })

      circle((col-x, row-y), radius: .13, fill: palette.coral.dark, stroke: white)
      content((p - .22, row-y + .34), text(size: 6pt, weight: "bold", fill: palette.teal.dark)[$i$])
      content((col-x + .34, .34), text(size: 6pt, weight: "bold", fill: palette.coral.dark)[$j$])
      content((p / 2, row-y - .72), text(size: 6pt, weight: "bold", fill: neutral-dark)[$k: 0 arrow.r P-1$])
      content((col-x - .77, by + p / 2), text(size: 6pt, weight: "bold", fill: neutral-dark)[$k$])
      content(
        (col-x + .33, row-y + .34),
        text(size: 6pt, weight: "bold", fill: palette.coral.dark)[$C_(i,j)$],
        anchor: "west",
      )

      content(
        (p / 2, by + p / 2),
        box(
          fill: panel-fill,
          stroke: (paint: neutral-line, thickness: .55pt),
          radius: 2pt,
          inset: (x: 6pt, y: 5pt),
        )[
          #align(center)[
            #text(size: 7pt, weight: "bold")[$C_(i,j) = sum_(k=0)^(P-1) A_(i,k) B_(k,j)$]\
            #text(size: 5.4pt, fill: neutral-dark)[one row of $A$ $times$ one column of $B$]
          ]
        ],
      )
    } else {
      let tile = 1.55
      let i0 = .9
      let k0 = 1.7
      let j0 = 1.05
      let element-y = i0 + .88 * tile
      let element-x = bx + j0 + .78 * tile
      let element-color = rgb("#B97874")
      let element-label = rgb("#744845")

      on-layer(-1, {
        // I and J stay fixed while K advances through the contracted axis.
        rect((0, i0), (p, i0 + tile), fill: palette.teal.mid, stroke: none)
        rect((bx + j0, by), (bx + j0 + tile, by + p), fill: palette.orange.mid, stroke: none)
        rect(
          (k0, i0),
          (k0 + tile, i0 + tile),
          fill: palette.teal.dark,
          stroke: (paint: neutral-dark, thickness: .72pt),
          name: "a-current-tile",
        )
        rect(
          (bx + j0, by + k0),
          (bx + j0 + tile, by + k0 + tile),
          fill: palette.orange.dark,
          stroke: (paint: neutral-dark, thickness: .72pt),
          name: "b-current-tile",
        )
        rect(
          (bx + j0, i0),
          (bx + j0 + tile, i0 + tile),
          fill: palette.coral.mid,
          stroke: (paint: palette.coral.dark, thickness: .9pt),
          name: "c-output-tile",
        )

        // Projection through the small matrix gaps identifies the output tile.
        line((p, i0), (bx, i0), stroke: (paint: neutral-line, thickness: .6pt, dash: "dashed"))
        line((p, i0 + tile), (bx, i0 + tile), stroke: (paint: neutral-line, thickness: .6pt, dash: "dashed"))
        line((bx + j0, m), (bx + j0, by), stroke: (paint: neutral-line, thickness: .6pt, dash: "dashed"))
        line((bx + j0 + tile, m), (bx + j0 + tile, by), stroke: (paint: neutral-line, thickness: .6pt, dash: "dashed"))

        // A single scalar row/column remains visible inside the selected tiles.
        line((0, element-y), (p, element-y), stroke: (paint: element-color, thickness: .82pt))
        line((element-x, by), (element-x, by + p), stroke: (paint: element-color, thickness: .82pt))
        line(
          (p, element-y),
          (element-x, element-y),
          stroke: (paint: element-color, thickness: .52pt, dash: "dashed"),
        )
        line(
          (element-x, by),
          (element-x, element-y),
          stroke: (paint: element-color, thickness: .52pt, dash: "dashed"),
        )

        line(
          (k0 - .4, i0 + tile + .34),
          (k0 + tile + .4, i0 + tile + .34),
          stroke: (paint: neutral-dark, thickness: .68pt),
          mark: (end: ">", scale: .48),
        )
        line(
          (bx + j0 - .36, by + k0 + tile + .4),
          (bx + j0 - .36, by + k0 - .4),
          stroke: (paint: neutral-dark, thickness: .68pt),
          mark: (end: ">", scale: .48),
        )
      })

      // tile_dim is shown once; the same physical edge is reused in all tiles.
      line(
        (k0, i0 - .3),
        (k0 + tile, i0 - .3),
        stroke: (paint: neutral-dark, thickness: .58pt),
        mark: (start: ">", end: ">", scale: .38),
      )
      content(
        (k0 + tile / 2, i0 - .58),
        text(size: 5.5pt, fill: neutral-dark)[tile_dim],
      )
      line(
        (-.34, i0),
        (-.34, i0 + tile),
        stroke: (paint: neutral-dark, thickness: .58pt),
        mark: (start: ">", end: ">", scale: .38),
      )
      content(
        (-.67, i0 + tile / 2),
        text(size: 5.5pt, fill: neutral-dark)[tile_dim],
        angle: 90deg,
      )

      content((k0 + tile / 2, i0 + tile / 2), text(size: 5.7pt, weight: "bold", fill: white)[$A_(I,K)$])
      content((bx + j0 + tile / 2, by + k0 + tile / 2), text(size: 5.7pt, weight: "bold", fill: white)[$B_(K,J)$])
      content((bx + j0 + tile / 2, i0 + tile / 2), text(size: 5.7pt, weight: "bold")[$C_(I,J)$])
      circle((element-x, element-y), radius: .085, fill: element-color, stroke: white)
      content((p - .18, element-y + .22), text(size: 5.2pt, weight: "bold", fill: element-label)[$i$])
      content((element-x + .22, by + .26), text(size: 5.2pt, weight: "bold", fill: element-label)[$j$])
      content((element-x, element-y - .3), text(size: 5.6pt, weight: "bold", fill: element-label)[$C_(i,j)$])
      content((.28, i0 + tile / 2), text(size: 5.8pt, weight: "bold", fill: neutral-dark)[$I$ rows], anchor: "west")
      content((right - .22, by + .38), text(size: 5.8pt, weight: "bold", fill: neutral-dark)[$J$ columns], anchor: "east")
      content((k0 + tile / 2, i0 + tile + .62), text(size: 5.7pt, weight: "bold", fill: neutral-dark)[advance $K$])
      content((bx + j0 - .68, by + k0 + tile / 2), text(size: 5.7pt, weight: "bold", fill: neutral-dark)[$K$])

      content(
        (2.3, by + p / 2),
        box(
          fill: panel-fill,
          stroke: (paint: neutral-line, thickness: .55pt),
          radius: 2pt,
          inset: (x: 6pt, y: 5pt),
        )[
          #align(center)[
            #text(size: 6.7pt, weight: "bold")[$C_(I,J) += A_(I,K) B_(K,J)$]\
            #text(size: 5.2pt, fill: neutral-dark)[keep the output tile resident; advance $K$]
          ]
        ],
      )
    }
  },
)

#let naive-matrix-multiplication() = _matrix-multiplication-diagram()
#let tiled-matrix-multiplication() = _matrix-multiplication-diagram(tiled: true)
