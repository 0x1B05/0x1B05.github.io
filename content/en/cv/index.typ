#import "../index.typ": template, tufted
#show: template.with(locale: "en", route: "cv/", title: "CV")

= 0x1B05

#tufted.margin-note[
  M.S. student in Electronic Engineering \
  ShanghaiTech University \
  One Student One Chip group
]

I am an M.S. student in Electronic Engineering at ShanghaiTech University and a member of the One Student One Chip group. My background is still anchored in CPU and digital-systems fundamentals, and this page is a short summary of what I am doing now and where I want to go next.

== Profile

- M.S. student in Electronic Engineering at ShanghaiTech University.
- Member of the One Student One Chip group.
- Completed the B-track of the One Student One Chip training.
- Trying to turn architecture fundamentals into more solid systems and performance work.

== Current Work

Recently I have been spending more time reviewing and validating XiangShan Kunminghu `v2`, while still using bring-up and simulators as part of my learning path.

- I have recently been reviewing and validating XiangShan Kunminghu `v2`.
- I am also still working on booting Linux on both `NEMU` and `NPC`.
- In this context, `NEMU` is the educational full-system emulator used throughout the YSYX training workflow.
- `NPC` is my own `RISC-V64` core project, so bring-up and debugging land directly on the hardware/software boundary.
- I continue to learn `gem5` as a way to look at workloads and microarchitectural behavior more systematically.

== Background and Training

- My current base is still mostly CPU and digital-systems fundamentals, including introductory understanding of pipelines, caches, and branch prediction.
- One Student One Chip B-track gave me a practical starting point for core, toolchain, and system-level work.
- I have used `gem5` before, but I am still building a stable workflow for analysis rather than treating it as a mature skill.
- Recent work around XiangShan Kunminghu `v2` is also giving me a clearer sense of how architecture reading, code review, and validation fit together.

== Technical Interests

- CPU and microarchitectural performance analysis
- workload characterization and measurement
- AI chip performance analysis
- AI systems performance optimization

== Direction

- Near term, I want to become more systematic about Linux bring-up, simulation, debugging, and review work around CPU-like systems.
- Over a longer horizon, I want to move from traditional CPU performance questions toward AI workloads and accelerator performance.
