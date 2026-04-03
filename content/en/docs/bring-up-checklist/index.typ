#import "../index.typ": template, tufted
#show: template.with(locale: "en", route: "docs/bring-up-checklist/", title: "Bring-up Checklist Reference")

= Bring-up Checklist Reference

#tufted.margin-note[
  Reusable prompts \
  for when the boot flow \
  stops before the story \
  is clear
]

This page is the flatter companion to the series chapter. I want it to behave like a page I can skim while debugging rather than a narrative explanation.

== Privilege assumptions

- Which privilege mode owns the current stage?
- Which layer is supposed to receive the next trap or exception?
- If control returns, which `xRET` path is the current code assuming?

== Firmware handoff

- Was the firmware built for the payload and device tree I am actually using?
- Do payload placement and offset assumptions still match the current image layout?
- Is there one clear handoff point I can instrument or confirm?

== Memory map and device tree

- Which address ranges are reserved by firmware, checkpoint tooling, or initramfs packaging?
- Does the device tree describe the same platform configuration I am actually booting?
- If memory is shared across multiple layers, who assumes ownership first?

== First visible signals

- earliest console output
- earliest reliable trap location
- first point where NEMU and NPC behavior diverge
- first stage where logs become silent

== Cheap debugging prompts

- What can I verify without rebuilding everything?
- Which layer can I compare against a known-good baseline?
- Am I missing a signal, or missing the transition itself?
