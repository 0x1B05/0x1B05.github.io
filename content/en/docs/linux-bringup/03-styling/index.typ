#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": linux-bringup-series
#show: template.with(locale: "en", route: "docs/linux-bringup/03-styling/", title: "How I Use NEMU, NPC, and gem5 Differently")

#let series = linux-bringup-series
#let nav = series-context(series, "docs/linux-bringup/03-styling/")

= How I Use NEMU, NPC, and gem5 Differently

#series-navbar("en", nav)

#doc-toc("en")

#tufted.margin-note[
  Sources \
  #link("https://www.gem5.org/about/")[What gem5 is] \
  #link("https://www.gem5.org/documentation/learning_gem5/introduction")[Learning gem5]
]

When I first grouped these tools together, I implicitly treated them as alternative ways to do the same thing. That model is too vague to be useful. The more practical distinction is that each one helps me answer a different kind of question.

#figure(
  image("imgs/tool-roles.svg"),
  caption: [How I currently separate baseline emulation, direct core bring-up, and simulation-oriented observation],
)

== NEMU as the baseline I can reason against

In my current workflow, `NEMU` is the educational full-system emulator that gives me a relatively stable reference point. It is not "simple" in the sense of being trivial, but it is simple in the sense that it helps me ask, "what should a working full-system path roughly look like?"

That makes it useful as a baseline for software stack expectations before I start debugging my own hardware implementation.

== NPC as the place where the assumptions hit my own core

`NPC` is different because it is my own `RISC-V64` core project. That means the interesting failures are no longer only about "does the software stack expect X?" but also about "did my own implementation actually provide X?" The same bring-up question becomes more concrete because the hardware boundary is mine.

That is why I treat NPC as the direct target for bring-up work rather than as just another simulator binary.

#figure(
  image("imgs/tool-questions.svg"),
  caption: [The different question I usually bring to each tool before I start debugging],
)

== gem5 as the simulator I am learning for a different purpose

The gem5 documentation describes gem5 as a modular computer-system simulation platform, and the Learning gem5 material makes it clear that using it well requires understanding how the simulator works rather than just copying commands. That is a useful warning for me, because my interest in gem5 is less about immediate bring-up and more about eventually building a better workflow for workload and microarchitectural observation.

So for now I treat gem5 as part of my learning path, not as a mature workflow I already own.

== Why I do not treat them as substitutes

The current split that makes sense to me is:

- use `NEMU` as a baseline for full-system behavior
- use `NPC` when I need to confront whether my own core and handoff path behave correctly
- use `gem5` when the question becomes more about simulator-supported observation, workload study, or microarchitectural experimentation

That separation is still evolving, but it is already much more useful than treating all three as generic "ways to run RISC-V code."

#series-navbar("en", nav)
