#import "@preview/cetz:0.5.2"

#let _ink = rgb("#202124")
#let _muted = rgb("#68707A")
#let _rule = rgb("#CBD2DB")
#let _blue = rgb("#2457A6")
#let _blue-fill = rgb("#EAF1FB")
#let _orange = rgb("#B85C00")
#let _orange-fill = rgb("#FFF0DF")
#let _green = rgb("#16724A")
#let _green-fill = rgb("#E7F4ED")

#let direct-network() = cetz.canvas(length: .62cm, padding: .18, {
  import cetz.draw: *

  let endpoint(name, a, b, label) = {
    rect(a, b, name: name, radius: .06, fill: _blue-fill, stroke: _blue)
    content(name + ".center", align(center, text(size: 6pt, weight: "bold", fill: _blue)[#label]))
  }

  let interface(name, a, b) = {
    rect(a, b, name: name, radius: .04, fill: white, stroke: _muted)
    content(name + ".center", align(center, text(size: 5.5pt, weight: "bold")[NI]))
  }

  let router(name, a, b, label) = {
    rect(a, b, name: name, radius: .08, fill: _orange-fill, stroke: _orange)
    content(name + ".center", align(center, text(size: 6pt, weight: "bold", fill: _orange)[#label]))
  }

  endpoint("pe0", (0, 4.2), (1.55, 5.25), [PE 0])
  interface("ni0", (2.05, 4.28), (3.05, 5.17))
  endpoint("pe2", (0, 1.15), (1.55, 2.2), [PE 2])
  interface("ni2", (2.05, 1.23), (3.05, 2.12))

  router("r0", (4.05, 4.08), (5.45, 5.37), [R0])
  router("r1", (7.35, 4.08), (8.75, 5.37), [R1])
  router("r2", (4.05, 1.03), (5.45, 2.32), [R2])
  router("r3", (7.35, 1.03), (8.75, 2.32), [R3])

  interface("ni1", (9.75, 4.28), (10.75, 5.17))
  endpoint("pe1", (11.25, 4.2), (12.8, 5.25), [PE 1])
  interface("ni3", (9.75, 1.23), (10.75, 2.12))
  endpoint("pe3", (11.25, 1.15), (12.8, 2.2), [PE 3])

  line("pe0.east", "ni0.west", stroke: _blue, mark: (end: ">", scale: .42))
  line("ni0.east", "r0.west", stroke: _ink, mark: (end: ">", scale: .42))
  line("pe2.east", "ni2.west", stroke: _blue, mark: (end: ">", scale: .42))
  line("ni2.east", "r2.west", stroke: _ink, mark: (end: ">", scale: .42))
  line("r1.east", "ni1.west", stroke: _ink, mark: (end: ">", scale: .42))
  line("ni1.east", "pe1.west", stroke: _blue, mark: (end: ">", scale: .42))
  line("r3.east", "ni3.west", stroke: _ink, mark: (end: ">", scale: .42))
  line("ni3.east", "pe3.west", stroke: _blue, mark: (end: ">", scale: .42))

  line("r0.east", "r1.west", stroke: (paint: _orange, thickness: 1.15pt))
  line("r2.east", "r3.west", stroke: (paint: _orange, thickness: 1.15pt))
  line("r0.south", "r2.north", stroke: (paint: _orange, thickness: 1.15pt))
  line("r1.south", "r3.north", stroke: (paint: _orange, thickness: 1.15pt))

  content((6.4, 5.9), align(center, text(size: 5.5pt, weight: "bold", fill: _orange)[router-to-router links]))
  content((6.4, .35), align(center, text(size: 5.3pt, fill: _muted)[every router has a local endpoint through an NI]))
})

#let mecs-topology() = cetz.canvas(length: .55cm, padding: .2, {
  import cetz.draw: *

  let router(name, x, y, label, fill-color: white, line-color: _ink) = {
    rect((x - .55, y - .5), (x + .55, y + .5), name: name, radius: .06, fill: fill-color, stroke: line-color)
    content(name + ".center", align(center, text(size: 5.6pt, weight: "bold", fill: line-color)[#label]))
  }

  let drop(x, y, color) = {
    rect((x - .1, y - .1), (x + .1, y + .1), fill: color, stroke: color)
  }

  // Orange horizontal buses and blue vertical buses are shared multidrop
  // channels. Short taps make the injection/drop relationship explicit.
  for y in (2.0, 5.0, 8.0) {
    line((1.2, y + .85), (13.8, y + .85), stroke: (paint: _orange, thickness: 1.35pt), mark: (end: ">", scale: .38))
    for x in (3.0, 7.5, 12.0) {
      line((x, y + .85), (x, y + .5), stroke: _orange)
      drop(x, y + .85, _orange)
    }
  }

  for x in (3.0, 7.5, 12.0) {
    line((x + .85, .55), (x + .85, 9.45), stroke: (paint: _blue, thickness: 1.35pt), mark: (end: ">", scale: .38))
    for y in (2.0, 5.0, 8.0) {
      line((x + .55, y), (x + .85, y), stroke: _blue)
      drop(x + .85, y, _blue)
    }
  }

  for row in range(3) {
    for col in range(3) {
      let x = 3.0 + col * 4.5
      let y = 8.0 - row * 3.0
      let name = "r" + str(row) + str(col)
      let label = [R#row#col]
      if row == 1 and col == 0 {
        router(name, x, y, label, fill-color: _orange-fill, line-color: _orange)
      } else if row == 1 and col == 2 {
        router(name, x, y, label, fill-color: _green-fill, line-color: _green)
      } else {
        router(name, x, y, label)
      }
    }
  }

  content((.75, 10.05), text(size: 5.5pt, weight: "bold", fill: _orange)[shared row express channels], anchor: "west")
  content((14.65, 7.25), text(size: 5.5pt, weight: "bold", fill: _blue)[shared column\ express channels], anchor: "west")

  // Highlight one source-to-destination transfer on the middle row.
  line((3.0, 5.5), (3.0, 5.85), (12.0, 5.85), (12.0, 5.5), stroke: (paint: _green, thickness: 1.5pt), mark: (end: ">", scale: .45))
  content((7.5, 6.22), align(center, text(size: 5.2pt, weight: "bold", fill: _green)[one injection can reach a selected remote drop point]))

  rect((1.2, -.6), (13.8, .12), radius: .05, fill: rgb("#F7F8FA"), stroke: _rule)
  content((7.5, -.24), align(center, text(size: 5pt, fill: _muted)[small colored squares are controlled injection / drop points]))
})
