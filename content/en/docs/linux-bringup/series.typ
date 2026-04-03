#let linux-bringup-series = (
  id: "linux-bringup",
  title: "From RISC-V Privilege Levels to Linux Bring-up",
  summary: "A practical path through privilege levels, OpenSBI, simulator roles, and the checkpoints I currently use while trying to boot Linux.",
  route: "docs/linux-bringup/",
  thumbnail: "starter-series.svg",
  begin-route: "docs/linux-bringup/01-quick-start/",
  chapters: (
    (
      id: "quick-start",
      title: "RISC-V Privilege Levels and Boot Context",
      summary: "Start from the M/S/U split, traps, and CSRs, then connect them to the first real questions that appear during bring-up.",
      route: "docs/linux-bringup/01-quick-start/",
      order: 1,
    ),
    (
      id: "configuration",
      title: "What OpenSBI Does in the Boot Chain",
      summary: "Place OpenSBI between machine-mode firmware and supervisor-mode software, then trace why that layer matters when Linux is the payload.",
      route: "docs/linux-bringup/02-configuration/",
      order: 2,
    ),
    (
      id: "styling",
      title: "How I Use NEMU, NPC, and gem5 Differently",
      summary: "Separate baseline emulation, direct core bring-up, and simulation-driven observation instead of treating the tools as substitutes.",
      route: "docs/linux-bringup/03-styling/",
      order: 3,
    ),
    (
      id: "deploy",
      title: "A Working Checklist for Linux Bring-up",
      summary: "Use a compact set of checks for firmware handoff, device tree sanity, console visibility, and early boot progress.",
      route: "docs/linux-bringup/04-deploy/",
      order: 4,
    ),
  ),
)
