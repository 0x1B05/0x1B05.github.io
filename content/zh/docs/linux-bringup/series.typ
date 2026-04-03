#let linux-bringup-series = (
  id: "linux-bringup",
  title: "从 RISC-V 特权级到 Linux Bring-up",
  summary: "一条面向当前阶段的实践路径，把特权级、OpenSBI、模拟器分工和 Linux bring-up 检查点串在一起。",
  route: "docs/linux-bringup/",
  thumbnail: "starter-series.svg",
  begin-route: "docs/linux-bringup/01-quick-start/",
  chapters: (
    (
      id: "quick-start",
      title: "RISC-V 特权级与启动上下文",
      summary: "先把 M/S/U 模式、trap 和 CSR 放进启动语境里，再理解为什么 bring-up 不是“能跑指令”这么简单。",
      route: "docs/linux-bringup/01-quick-start/",
      order: 1,
    ),
    (
      id: "configuration",
      title: "OpenSBI 在启动链路里做什么",
      summary: "把 OpenSBI 放回 machine-mode firmware 和 supervisor-mode 软件之间，理解它为什么会在 Linux bring-up 中变得具体起来。",
      route: "docs/linux-bringup/02-configuration/",
      order: 2,
    ),
    (
      id: "styling",
      title: "我如何区分使用 NEMU、NPC 和 gem5",
      summary: "把教学型基线、直接 bring-up 目标和面向观察的模拟器分开，而不是把它们当成可互换工具。",
      route: "docs/linux-bringup/03-styling/",
      order: 3,
    ),
    (
      id: "deploy",
      title: "一份正在使用的 Linux Bring-up 检查框架",
      summary: "把 firmware handoff、设备树、console 和 early boot 这些关键检查点整理成可反复使用的框架。",
      route: "docs/linux-bringup/04-deploy/",
      order: 4,
    ),
  ),
)
