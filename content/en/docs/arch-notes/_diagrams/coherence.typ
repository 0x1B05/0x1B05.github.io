#import "@preview/finite:0.5.0": automaton

#let _ink = rgb("#202124")
#let _muted = rgb("#68707A")
#let _blue = rgb("#2457A6")
#let _blue-fill = rgb("#EAF1FB")
#let _green = rgb("#16724A")
#let _green-fill = rgb("#E7F4ED")
#let _red = rgb("#B42318")
#let _red-fill = rgb("#FDECEC")

#let simple-vi-coherence() = align(center, [
  #automaton(
    (
      valid: (
        valid: ("PrRd / --", "PrWr / BusWr"),
        invalid: "snoop BusWr / --",
      ),
      invalid: (
        valid: "PrRd / BusRd",
        invalid: "PrWr / BusWr",
      ),
    ),
    initial: none,
    final: none,
    layout: (
      valid: (0, 2.15),
      invalid: (0, -2.15),
    ),
    labels: (
      valid: [Valid],
      invalid: [Invalid],
    ),
    input-format: inputs => inputs.map(input => [#input]).join(linebreak()),
    style: (
      state: (
        radius: 1.05,
        stroke: (paint: _ink, thickness: .75pt),
        label: (size: 7.5pt, fill: _ink),
      ),
      valid: (
        fill: _green-fill,
        stroke: (paint: _green, thickness: .9pt),
      ),
      invalid: (
        fill: _red-fill,
        stroke: (paint: _red, thickness: .9pt),
      ),
      transition: (
        stroke: (paint: _ink, thickness: .72pt),
        label: (size: 6.2pt, fill: _ink, dist: .42),
      ),
      loop: (
        stroke: (paint: _blue, thickness: .78pt),
        label: (size: 5.9pt, fill: _blue, dist: .4),
      ),
      "valid-valid": (
        anchor: top,
        curve: 1.25,
      ),
      "invalid-invalid": (
        anchor: bottom,
        curve: 1.25,
      ),
      "invalid-valid": (
        curve: 1.9,
        stroke: (paint: _blue, thickness: .78pt),
        label: (size: 6.1pt, fill: _blue, dist: 1.35, angle: 0deg),
      ),
      "valid-invalid": (
        curve: 1.9,
        stroke: (paint: _red, thickness: .78pt),
        label: (size: 6.1pt, fill: _red, dist: 1.35, angle: 0deg),
      ),
    ),
    length: .72cm,
    padding: .25,
  )

  #v(2pt)
  #text(size: 7.2pt, fill: _muted)[
    Transition label: observed event / emitted bus transaction; -- means no bus transaction.
  ]
])
