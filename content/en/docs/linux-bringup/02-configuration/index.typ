#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": linux-bringup-series
#show: template.with(locale: "en", route: "docs/linux-bringup/02-configuration/", title: "What OpenSBI Does in the Boot Chain")

#let series = linux-bringup-series
#let nav = series-context(series, "docs/linux-bringup/02-configuration/")

= What OpenSBI Does in the Boot Chain

#series-navbar("en", nav)

#tufted.margin-note[
  Sources \
  #link("https://github.com/riscv-software-src/opensbi")[OpenSBI README] \
  #link("https://docs.xiangshan.cc/zh-cn/latest/workloads/opensbi-kernel-for-xs/")[XiangShan OpenSBI kernel guide]
]

OpenSBI is the layer that made the boot story feel much less hand-wavy to me. Once I stopped treating Linux as "the first interesting thing" and started asking who is supposed to hand control to it, the machine-mode firmware layer stopped being optional background reading.

#tufted.margin-note[
  #image("imgs/sbi-boundary.svg")
  The SBI boundary is the handoff surface where machine-mode control turns into services the payload can rely on.
]

#figure(
  image("imgs/boot-chain.svg"),
  caption: [One practical view of the boot chain from platform reset to user software],
)

== Where it sits

According to the OpenSBI project, the RISC-V Supervisor Binary Interface is the recommended interface between platform-specific firmware in `M-mode` and software executing in `S-mode` or `HS-mode`. OpenSBI positions itself as the open-source reference implementation of that interface for machine-mode firmware.

In other words, OpenSBI is not "the kernel" and it is not "just another application." It is the layer that stands between machine-mode control and the supervisor-level software that expects SBI services.

#figure(
  image("imgs/opensbi-handoff-checks.svg"),
  caption: [Three checks I now keep together: payload placement, device-tree handoff, and the SBI-facing service boundary],
)

== What this layer usually owns

The OpenSBI README is useful because it makes the role concrete. The reusable `libsbi.a` layer is meant to provide the SBI interface while still allowing platform-specific code to plug in the hardware-dependent pieces. That is where responsibilities such as console access hooks, inter-processor interrupt control, or timer-related platform operations become relevant.

That is exactly the sort of boundary I need to care about during bring-up: not every failure is "the kernel failed." Sometimes the missing piece is lower, at the firmware handoff or SBI-service layer.

== Why Linux bring-up runs into it quickly

The XiangShan documentation makes this practical very quickly: when building a Linux workload around OpenSBI, the OpenSBI firmware is built with the kernel image as payload and a device tree passed alongside it. That makes the handoff chain visible in build commands, image layout, and address assumptions instead of leaving it as a purely conceptual layer.

For me, that changes how I read bring-up problems. If Linux does not move forward, one of the questions becomes: was the firmware built the way the payload expects, and was the handoff performed in the way the software stack assumes?

== What I am trying to remember

- OpenSBI is the visible handoff layer between machine-mode firmware and supervisor-level software.
- It matters not because it is large, but because it defines the contract Linux expects below it.
- The moment Linux becomes the payload, firmware build parameters, payload location, and device-tree handling stop being secondary details.

#series-navbar("en", nav)
