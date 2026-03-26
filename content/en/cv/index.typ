#import "../index.typ": template, tufted
#show: template.with(locale: "en", route: "cv/", title: "CV")

= 0x1B05

#tufted.margin-note[
  M.S. student in Electronic Information \
  ShanghaiTech University \
  One Student One Chip group
]

I am a graduate student in Electronic Information at ShanghaiTech University and a member of the One Student One Chip group. My current background is stronger in CPU and digital systems fundamentals than in mature performance-analysis work, and this page is meant to give a compact view of the direction I am actively growing into.

== Profile

- Graduate student in Electronic Information at ShanghaiTech University.
- Member of the One Student One Chip group.
- Completed the B-track of the One Student One Chip training.
- Interested in turning architecture fundamentals into stronger systems and performance-analysis habits.

== Current Work

Recently I have been spending time on system bring-up and simulation-oriented learning rather than claiming polished performance expertise too early.

- I am trying to boot Linux on both `NEMU` and `NPC`.
- In this context, `NEMU` is the educational full-system emulator used throughout the YSYX training workflow.
- `NPC` is my own `RISC-V64` core project, which makes the hardware and software boundary much more concrete during bring-up and debugging.
- I am also learning `gem5` and trying to turn simulator use into a more repeatable way of studying workload behavior and microarchitectural questions.

== Background and Training

- My current base is still primarily in CPU and digital systems fundamentals, including introductory understanding of pipelines, caches, and branch prediction.
- One Student One Chip B-track gave me a practical starting point for core, toolchain, and system-level work.
- I have used `gem5` before, but I am still building a stable workflow for analysis rather than treating it as a fully mature skill.
- This summer I will intern at XiangShan, which I expect to be an important step in making my architecture work more concrete.

== Technical Interests

- CPU and microarchitectural performance analysis
- workload characterization and measurement
- AI chip performance analysis
- AI systems performance optimization

== Direction

- Near term, I want to become more systematic about Linux bring-up, simulation, debugging, and performance-oriented reasoning around CPU-like systems.
- Over a longer horizon, I want to move from traditional CPU performance questions toward AI workloads and accelerator performance.
- After graduation, I would prefer to work in Shanghai or Suzhou.
