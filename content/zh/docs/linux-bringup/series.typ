#let linux-bringup-series = (
  id: "linux-bringup",
  title: "从 RISC-V 特权级到 Linux Bring-up",
  summary: "按特权级、OpenSBI、模拟器分工到 bring-up 检查点这条线，把目前在做的事串成一条路径。",
  route: "docs/linux-bringup/",
  thumbnail: "starter-series.svg",
  begin-route: "docs/linux-bringup/01-quick-start/",
  chapters: (
    (
      id: "quick-start",
      title: "RISC-V 特权级与启动上下文",
      summary: "把 M/S/U 模式、trap 和 CSR 放进启动语境，说清 bring-up 为什么要先管它们。",
      route: "docs/linux-bringup/01-quick-start/",
      order: 1,
    ),
    (
      id: "configuration",
      title: "OpenSBI 在启动链路里做什么",
      summary: "OpenSBI 夹在 machine-mode firmware 和 supervisor 软件之间，做的是哪一段交接。",
      route: "docs/linux-bringup/02-configuration/",
      order: 2,
    ),
    (
      id: "styling",
      title: "我如何区分使用 NEMU、NPC 和 gem5",
      summary: "教学基线、自己的核、观察型模拟器分工不同，不能混着用。",
      route: "docs/linux-bringup/03-styling/",
      order: 3,
    ),
    (
      id: "deploy",
      title: "一份正在使用的 Linux Bring-up 检查框架",
      summary: "firmware handoff、设备树、console 和 early boot 的检查清单，卡住时照着查。",
      route: "docs/linux-bringup/04-deploy/",
      order: 4,
    ),
  ),
)
