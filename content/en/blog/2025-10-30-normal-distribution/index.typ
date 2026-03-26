#import "../index.typ": template, tufted
#show: template.with(
  locale: "en",
  route: "blog/2025-10-30-normal-distribution/",
  title: "Why OpenSBI Became Hard to Ignore",
)

= Why OpenSBI Became Hard to Ignore

#tufted.margin-note[
  Source links \
  #link("https://github.com/riscv-software-src/opensbi")[OpenSBI README] \
  #link("https://riscv.github.io/riscv-isa-manual/snapshot/privileged")[Privileged Architecture Manual] \
  #link("https://docs.xiangshan.cc/zh-cn/latest/workloads/opensbi-kernel-for-xs/")[XiangShan OpenSBI workload guide]
]

The moment I started treating Linux bring-up as a concrete task rather than a distant milestone, OpenSBI stopped feeling optional. Before that, it was easy to read the privilege architecture and think mostly in terms of modes and specifications. Once the target became an actual boot flow, the firmware layer between machine mode and supervisor-mode software became much harder to ignore.

== The SBI boundary is a real contract

The OpenSBI README states the point cleanly: the RISC-V SBI is the recommended interface between platform-specific firmware in `M-mode` and software executing in `S-mode` or `HS-mode`, and OpenSBI is the open-source reference implementation of that interface for machine-mode firmware.

That phrasing matters because it turns an abstract boundary into a concrete contract. Once Linux is the thing I want to boot, I cannot just say "the kernel starts somehow." I have to ask which layer owns the transition and which services Linux expects below it.

== The build flow makes the firmware visible

The XiangShan guide for an OpenSBI-based Linux workload makes this boundary operational. It asks the user to build OpenSBI with `FW_PAYLOAD_PATH` pointing at the Linux kernel image, `FW_FDT_PATH` pointing at the device tree, and a chosen `FW_PAYLOAD_OFFSET`. That immediately changes the shape of the problem.

Now the firmware is not a background library. It is visibly part of the boot artifact, the image layout, and the assumptions about where the payload and device tree will be placed.

== Why that changed my reading path

The privileged architecture manual still matters, but now I read it differently. I am less interested in memorizing every detail in isolation and more interested in tracing a specific chain:

- which privilege level owns the current execution stage
- which layer is responsible for the next handoff
- what Linux expects from the SBI side of that boundary
- what kind of failure might really belong to firmware rather than to the kernel proper

That shift is why OpenSBI became hard to ignore. It is the point where the boot chain stops being an abstract stack diagram and starts becoming a concrete part of the problem.

== What I take away

- OpenSBI is not just "one more repository" in a build flow; it is the visible implementation of the SBI boundary.
- Once Linux is the payload, firmware build choices become part of bring-up reasoning.
- Reading the privileged spec becomes more useful when it is tied to an actual handoff chain instead of left as isolated background theory.
