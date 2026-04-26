#import "../index.typ": template, tufted
#show: template.with(locale: "en", route: "cv/", title: "CV")

= 0x1B05

#tufted.margin-note[
  M.S. student in Electronic Engineering \
  ShanghaiTech University \
  One Student One Chip group
]

I am an M.S. student in Electronic Engineering at ShanghaiTech University and a member of the One Student One Chip group. My background is mostly in CPUs and digital systems. These days I spend most of my time on Linux bring-up, simulators, and review or validation work around XiangShan Kunminghu `v2`.

== Profile

- M.S. student in Electronic Engineering at ShanghaiTech University.
- Member of the One Student One Chip group.
- Completed the B-track of the One Student One Chip training.
- Working on the link between architecture, system software, and performance analysis.

== Current Work

Recently I have been spending more time reviewing and validating XiangShan Kunminghu `v2`, while still working through bring-up and simulator problems.

- I have recently been reviewing and validating XiangShan Kunminghu `v2`.
- I am also still working on booting Linux on both `NEMU` and `NPC`.
- In this context, `NEMU` is the educational full-system emulator used throughout the YSYX training workflow.
- `NPC` is my own `RISC-V64` core project, so bring-up and debugging land directly on the hardware/software boundary.
- I continue to learn `gem5` so workload observation and microarchitectural analysis become less ad hoc.

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

== Next

- Near term: more Linux bring-up, simulation, debugging, and review work around CPU-like systems.
- Longer term: more work on AI workloads and accelerator performance.
