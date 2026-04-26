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

When I first read the RISC-V privileged architecture, I mostly filed away terms like `M-mode`, `S-mode`, traps, and delegation. Once I started trying to make Linux boot, OpenSBI stopped feeling like background material. Before the kernel runs, something has to own the platform, prepare the handoff, and provide the services Linux expects below it.

== The SBI boundary is a real contract

The OpenSBI README states the point cleanly: the RISC-V SBI is the recommended interface between platform-specific firmware in `M-mode` and software executing in `S-mode` or `HS-mode`, and OpenSBI is the open-source reference implementation of that interface for machine-mode firmware.

That phrasing is useful during bring-up because it fixes the boundary. Linux does not just start out of nowhere. The firmware below it owns part of the platform contract, and if that contract is wrong, the failure may not belong to the kernel at all.

== The build flow makes the firmware visible

The XiangShan guide for an OpenSBI-based Linux workload makes this boundary operational. It asks the user to build OpenSBI with `FW_PAYLOAD_PATH` pointing at the Linux kernel image, `FW_FDT_PATH` pointing at the device tree, and a chosen `FW_PAYLOAD_OFFSET`. That immediately changes the shape of the problem.

At that point the firmware is no longer just another dependency in the source tree. It affects the boot artifact, the image layout, and the assumptions about where the payload and device tree live.

== Why that changed my reading path

The privileged architecture manual still matters, but now I read it with the boot chain in mind:

- which privilege level owns the current execution stage
- which layer is responsible for the next handoff
- what Linux expects from the SBI side of that boundary
- what kind of failure might really belong to firmware rather than to the kernel proper

That is why OpenSBI became hard to ignore. It sits right between the privilege model in the spec and the actual Linux boot path.

== Notes to keep

- OpenSBI is not just "one more repository" in a build flow; it is the visible implementation of the SBI boundary.
- Once Linux is the payload, firmware build choices become part of bring-up reasoning.
- Reading the privileged spec becomes more useful when it is tied to an actual handoff chain instead of left as isolated background theory.
