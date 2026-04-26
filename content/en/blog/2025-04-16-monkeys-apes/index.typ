#import "../index.typ": template, tufted
#show: template.with(
  locale: "en",
  route: "blog/2025-04-16-monkeys-apes/",
  title: "Reading LibCheckpointAlpha as Infrastructure",
)

= Reading LibCheckpointAlpha as Infrastructure

#tufted.margin-note[
  Source links \
  #link("https://github.com/OpenXiangShan/LibCheckpointAlpha")[LibCheckpointAlpha README] \
  #link("https://github.com/OpenXiangShan/LibCheckpoint")[LibCheckpoint README] \
  #link("https://docs.xiangshan.cc/zh-cn/latest/workloads/opensbi-kernel-for-xs/")[XiangShan OpenSBI workload guide]
]

I first looked at checkpoint tooling because I wanted to know how it restored state. With `LibCheckpointAlpha`, the other words in the README quickly became just as important: payload, bootloader, direct boot, SimPoint. If a restore tool talks about all of those, it is doing more than putting state back.

== Why LibCheckpointAlpha caught my attention

The `LibCheckpointAlpha` README is unusually direct. It describes the repository as a transitional version of `LibCheckpoint`, and says it currently offers two uses:

- restore checkpoint state
- link the next-level bootloader such as `riscv-pk` or `OpenSBI`

That dual role is the interesting part. This is not just a restore utility at the edge of a workflow. It sits between resuming execution and packaging the next layer of the boot flow.

== The XiangShan workload guide makes the role concrete

The XiangShan guide for building a Linux kernel with OpenSBI turns that README into a practical workflow. After building OpenSBI with a payload, the guide explicitly asks the user to clone `LibCheckpointAlpha`, set `GCPT_HOME`, and run `make GCPT_PAYLOAD_PATH=...` to produce `gcpt.bin`, which can then be used for direct boot or as a workload for SimPoint profiling and checkpoint-related flows.

That changes how I read the repository. It is part of the middle layer between a built payload and a reusable boot artifact, not just a debugging afterthought.

#figure(
  image("imgs/checkpoint-handoff.svg"),
  caption: [How I now picture checkpoint tooling sitting between payload build output, reusable boot artifacts, and later bring-up reuse],
)

== What changed in the newer LibCheckpoint repo

The newer `LibCheckpoint` repository narrows the headline around restoration more explicitly: it presents itself as a restorer for `rvgcpt` checkpoints, focused on recovering in-memory architectural state into registers. But the README still keeps "linking to the next-level bootloader" in its usage section.

So the newer repo feels less like a conceptual change than a cleaner specialization. Restoration is now the headline, but the bootloader-linking role has not completely disappeared.

== Why I care about this kind of project

Projects like this change where I draw the boundary of bring-up. It is not only the CPU core on one side and the Linux image on the other. The artifacts in the middle also decide how state is packaged, how payloads are linked, and how execution resumes.

Those pieces are easy to overlook, but a reusable boot path depends on them.
