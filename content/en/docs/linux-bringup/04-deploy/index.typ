#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": linux-bringup-series
#show: template.with(locale: "en", route: "docs/linux-bringup/04-deploy/", title: "A Working Checklist for Linux Bring-up")

#let series = linux-bringup-series
#let nav = series-context(series, "docs/linux-bringup/04-deploy/")

= A Working Checklist for Linux Bring-up

#series-navbar("en", nav)

This chapter is deliberately written as a working checklist instead of a success report. I am still using it to organize my own bring-up thinking, so the goal is not to present a solved story. The goal is to keep the first-response checks short, visible, and easy to revisit.

== Before kernel entry

The first questions I want answered are about assumptions, not heroics:

- Which privilege mode am I in when control reaches the current stage?
- Is there a clear firmware-to-payload handoff path?
- Do the entry address, payload offset, and expected load addresses agree with each other?
- Is the device tree the one this payload actually expects?

If I cannot answer those cleanly, looking at later symptoms is often wasted effort.

== Firmware handoff

When OpenSBI is part of the flow, I want to check:

- how the payload was linked
- whether the device tree path and payload path match the current build
- whether the expected handoff convention is the one the firmware image was built for
- whether the firmware stage can expose enough information to tell me that control really moved forward

At this stage, a wrong handoff can look very similar to a dead kernel, so I try not to collapse them into the same diagnosis too early.

== Device tree and memory map sanity

I also want a compact memory-map sanity check:

- Is the payload placed where the current firmware build assumes?
- Is any reserved region overlapping the area I expect Linux or my current boot payload to use?
- Does the device tree describe the platform in a way that matches the actual run target?
- If there is a checkpoint, initramfs, or payload wrapper involved, which address ranges did it implicitly claim?

These questions are tedious, but they are exactly the sort of mismatch that can make bring-up fail in ways that look mysterious.

== First signals of life

The first useful observations are usually small:

- a visible console message
- a known transition point reached in logs
- a trap that lands where I expect
- a watchdog or timeout that at least tells me where the path stopped

I would rather collect one trustworthy sign of progress than immediately guess at a deeper root cause without evidence.

== When the boot flow stalls

When nothing obvious appears, the next questions I ask myself are:

- Did control stop before the kernel, inside firmware, or after an early kernel transition?
- Am I missing the signal because logging is absent, or because the transition never happened?
- Which assumption can I verify cheaply before changing more code?
- If I compare against a NEMU-based baseline, which part of the path diverges first?

The checklist is intentionally boring. That is the point. I want a repeatable path to follow before I let frustration turn the whole problem into guesswork.

#series-navbar("en", nav)
