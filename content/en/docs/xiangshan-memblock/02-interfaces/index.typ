#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "en", route: "docs/xiangshan-memblock/02-interfaces/", title: "ooo_to_mem and mem_to_ooo")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/02-interfaces/")

= The Main Boundary to the Backend: `ooo_to_mem` and `mem_to_ooo`

#series-navbar("en", nav)

#doc-toc("en")

Once the high-level map is in place, the next useful boundary is the pair of interfaces between MemBlock and the backend. They tell you what the rest of the core expects MemBlock to accept, and what kinds of results or feedback MemBlock is responsible for returning.

== What enters through `ooo_to_mem`

The issue side is already split by memory role rather than hidden behind one generic request stream:

- `issueLda` for load-address side work
- `issueSta` for store-address side work
- `issueStd` for store-data side work
- vector issue streams such as `issueVldu`
- control inputs such as `csrCtrl`, `sfence`, and redirect-related signals

That split is important because it mirrors the internal structure. MemBlock is not re-discovering categories after the fact. The backend is already speaking to it in differentiated memory lanes.

== What comes back through `mem_to_ooo`

The return side is broader than plain writeback:

- load, store, and vector writeback results
- IQ feedback paths
- wakeup signals
- load cancel information
- memory-violation and replay-related feedback
- LSQ status and rollback-related control information

This is why I like reading the boundary before the implementation loops. It immediately shows that MemBlock is both a data path and a control-feedback hub.

== Why this boundary is the right first reading handle

If I start from one internal unit too early, I lose the system picture. The boundary fixes that. It answers:

- which classes of micro-ops exist before they even enter MemBlock
- which control events must fan out across many submodules
- which outputs are architecturally visible to the rest of the backend

In practice, it also helps me name the code correctly. A path carrying writeback is different from a path carrying replay or violation information, even if both are ultimately "feedback."

== Review questions I would keep nearby

At this boundary, I would keep asking:

- Does each issued lane have a clear owner and return path?
- Are cancellation, wakeup, and feedback tied to the same logical instruction class?
- Can a redirect or violation arrive while another shared lane is borrowing resources?
- When multiple rollback candidates exist, where is the single point that decides which one wins?

Those questions make later internal wiring easier to judge, because I already know what contracts the backend believes it has with MemBlock.

#series-navbar("en", nav)
