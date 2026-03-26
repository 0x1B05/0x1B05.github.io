#import "../../config.typ": template, tufted, content-card as shared-content-card, profile-image, locale-url
#show: template.with(locale: "en", route: "")

#let content-card = shared-content-card

#let home-link(href, title, description) = html.a(href: href, class: "home-link")[
  #html.span(class: "home-link__title")[#title]
  #html.span(class: "home-link__description")[#description]
]

= 0x1B05

#html.div(class: "home-hero")[
  #html.div(class: "home-hero__copy")[
    #html.span(class: "home-kicker")[Architecture notes and work in progress]

    == From CPU fundamentals to performance-oriented systems work

    I am an M.S. student in Electronic Information at ShanghaiTech University and a member of the One Student One Chip group. After completing the B-track of the training, my current foundation is strongest in CPU and digital systems fundamentals, and I am using this site to document how that base grows into more systematic architecture, systems, and performance work.

    Recently I have been trying to boot Linux on both `NEMU` and `NPC`. In this context, `NEMU` is the educational full-system emulator used in the YSYX workflow, while `NPC` is my own `RISC-V64` core project. In parallel, I am learning `gem5` so I can build a more repeatable way to study microarchitectural behavior and performance questions.
  ]
  #html.div(class: "home-hero__profile")[
    #profile-image()
  ]
]

== Current Direction

My near-term work is centered on a few connected goals:

- strengthen the path from CPU and digital systems fundamentals toward microarchitectural performance analysis
- use Linux bring-up on `NEMU` and `NPC` as a concrete way to connect architecture, debugging, and systems behavior
- prepare for my upcoming summer internship at XiangShan
- grow from CPU-oriented performance questions toward AI workload and accelerator performance over time

#html.div(class: "home-links")[
  #home-link(
    locale-url("en", route: "docs/"),
    "Study notes and references",
    "Keep architecture notes, bring-up records, and practical methodology pages that are easy to revisit when the workflow gets deeper.",
  )
  #home-link(
    locale-url("en", route: "blog/"),
    "Experiment logs and writing",
    "Collect reading notes, short technical essays, and stage-by-stage writeups from ongoing systems and performance work.",
  )
  #home-link(
    locale-url("en", route: "cv/"),
    "Profile and direction",
    "See a compact summary of my background, current work, technical interests, and the directions I want to grow into next.",
  )
]

== What This Site Is For

I want this site to stay small, readable, and useful both as a personal profile and as a technical notebook. The emphasis is less on presenting finished expertise and more on making current work, learning direction, and technical growth visible.
