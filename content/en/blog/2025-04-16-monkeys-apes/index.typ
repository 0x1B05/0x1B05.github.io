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

Checkpoint tooling interests me less as a standalone feature and more as a piece of stack infrastructure. Once a project starts talking about restoration, payload linkage, and direct boot in the same place, it is implicitly teaching me how the boot flow is packaged and re-entered.

== Why LibCheckpointAlpha caught my attention

The `LibCheckpointAlpha` README is unusually direct. It describes the repository as a transitional version of `LibCheckpoint`, and says it currently offers two uses:

- restore checkpoint state
- link the next-level bootloader such as `riscv-pk` or `OpenSBI`

That dual role is the part I find most interesting. It says this is not just a restore utility hidden at the edge of a workflow. It sits at a place where restart, boot packaging, and execution flow all meet.

== The XiangShan workload guide makes the role concrete

The XiangShan guide for building a Linux kernel with OpenSBI turns that README into a practical workflow. After building OpenSBI with a payload, the guide explicitly asks the user to clone `LibCheckpointAlpha`, set `GCPT_HOME`, and run `make GCPT_PAYLOAD_PATH=...` to produce `gcpt.bin`, which can then be used for direct boot or as a workload for SimPoint profiling and checkpoint-related flows.

That is enough to change how I read the repository. It is part of the glue between a built payload and a reusable boot artifact, not just a debugging afterthought.

#figure(
  image("imgs/checkpoint-handoff.svg"),
  caption: [How I now picture checkpoint tooling sitting between payload build output, reusable boot artifacts, and later bring-up reuse],
)

== What changed in the newer LibCheckpoint repo

The newer `LibCheckpoint` repository narrows the headline around restoration more explicitly: it presents itself as a restorer for `rvgcpt` checkpoints, focused on recovering in-memory architectural state into registers. But the README still keeps "linking to the next-level bootloader" in its usage section.

So the newer repo feels less like a conceptual change than a cleaner specialization. The infrastructure role is still there; it is just described with a more explicit restoration focus.

== Why I care about this kind of project

Projects like this change how I think about the stack. They make it obvious that bring-up is not only about the CPU core and not only about the Linux image. The artifacts in the middle matter too: how state is packaged, how payloads are linked, and how execution is resumed or redirected.

That is exactly the sort of "boring but decisive" infrastructure I want to understand better.
