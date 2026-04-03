#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": linux-bringup-series
#show: template.with(locale: "en", route: "docs/linux-bringup/01-quick-start/", title: "RISC-V Privilege Levels and Boot Context")

#let series = linux-bringup-series
#let nav = series-context(series, "docs/linux-bringup/01-quick-start/")

= RISC-V Privilege Levels and Boot Context

#series-navbar("en", nav)

#tufted.margin-note[
  Further reading \
  #link("https://riscv.github.io/riscv-isa-manual/snapshot/privileged")[Privileged Architecture Manual]
]

Linux bring-up made the privileged architecture feel much less abstract to me. Once the target is a real kernel image instead of a tiny test program, the questions stop being "can the core run instructions?" and become "which privilege mode owns what, who handles traps, and who is responsible for the next handoff?"

== Machine, Supervisor, and User

The privileged specification defines a software stack with distinct privilege levels:

- `M-mode` is the highest privilege level and the only mandatory one for a RISC-V hardware platform.
- `S-mode` is where a supervisor-level OS such as Linux expects to execute.
- `U-mode` is where ordinary applications live once the kernel has set up the environment around them.

That split matters because Linux is not supposed to begin life in a vacuum. Something below it has to establish the environment, delegate the right control, and hand over execution in a predictable way.

== Why CSRs and traps appear immediately

Once boot becomes the topic, control and status registers stop feeling like background material:

- status registers tell you what privilege state the hart is in
- trap-related CSRs tell you where exceptions and interrupts will land
- address-translation state such as `satp` affects when virtual-memory assumptions begin to matter
- delegation controls decide which layer is allowed to see which trap first

Even when I am not reading every CSR in detail, I still need the overall picture: if a trap goes to the wrong place or the next privilege transition is wrong, Linux bring-up can fail long before the kernel gets far enough to print anything useful.

== Boot context is more than "can it execute code"

The first practical questions I now care about are things like:

- Which mode does the hart start in?
- Who sets up the next privilege transition?
- Who passes the device tree and boot arguments?
- Which layer is expected to provide the SBI calls Linux will rely on?
- Where should I expect the first visible sign of life if the path is correct?

These are all "boot context" questions rather than "instruction set" questions, but they sit directly on top of the privileged architecture model.

== What I take away from this chapter

- The privilege split is not just specification vocabulary; it defines the contracts between firmware, kernel, and user software.
- Traps and CSRs matter early because they determine whether control reaches the expected layer at all.
- Before touching Linux-specific details, I need a clear picture of the privilege and handoff story.

#series-navbar("en", nav)
