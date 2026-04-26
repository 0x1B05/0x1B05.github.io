#import "../../config.typ": template, tufted, content-card as shared-content-card, profile-image, locale-url
#show: template.with(locale: "en", route: "")

#let content-card = shared-content-card

#let home-link(href, title, description) = html.a(href: href, class: "home-link")[
  #html.span(class: "home-link__title")[#title]
  #html.span(class: "home-link__description")[#description]
]

#html.div(class: "home-hero")[
  #html.div(class: "home-hero__copy")[

    This is 0x1B05's personal site. It mostly collects the projects I am working on, architecture notes, and a growing set of tutorials and reading logs. Right now the content is centered on `RISC-V`, Linux bring-up, simulators and debugging tools, and reading through XiangShan and the infrastructure around it. If you want a quick way in, start with #link(locale-url("en", route: "docs/"))[`Docs`] and #link(locale-url("en", route: "blog/"))[`Blog`].

    == About Me

    I am an M.S. student in Electronic Engineering at ShanghaiTech University and a member of the One Student One Chip group. After finishing the B-track training, I have kept working through the line between CPUs, digital systems, architecture, and system software. This site is where I put the things I am reading, building, and debugging along the way.

    Recently I have been spending more time reviewing and validating XiangShan Kunminghu `v2`. In parallel, I am still working on Linux bring-up on both `NEMU` and `NPC`. Here `NEMU` is the teaching-oriented full-system emulator used in the YSYX workflow, while `NPC` is my own `RISC-V64` core project. I also keep learning `gem5` so I can look at workloads and microarchitectural behavior more systematically.
  ]
  #html.div(class: "home-hero__profile")[
    #profile-image()
  ]
]

== Current Direction

My near-term work is centered on a few connected goals:

- keep building from CPU and digital-systems fundamentals toward microarchitectural performance analysis
- use Linux bring-up, debugging, and simulator work as one connected workflow instead of separate exercises
- keep learning through review and validation work on XiangShan Kunminghu `v2`
- gradually move from CPU performance questions toward AI workloads and accelerators

#html.div(class: "home-links")[
  #home-link(
    locale-url("en", route: "docs/"),
    "Study notes and references",
    "Architecture notes, Linux bring-up records, paper-reading series, and reference pages I expect to revisit.",
  )
  #home-link(
    locale-url("en", route: "blog/"),
    "Experiment logs and writing",
    "Shorter notes on tools, concrete bring-up problems, and reading logs around OpenSBI, checkpointing, and debugging workflows.",
  )
  #home-link(
    locale-url("en", route: "cv/"),
    "Profile and recent work",
    "A short summary of my background, recent work, and technical interests.",
  )
]

== This Site

This is not meant to read like a polished publication archive. It is closer to a notebook I can revisit: boot-flow notes, tool docs, code-reading paths, and the occasional piece that needs to be rewritten once I understand the topic better.
