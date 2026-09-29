#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/22-emerging-memory/",
  title: "Memory Robustness, Flash, and Emerging Memory",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/22-emerging-memory/")

= Memory Robustness, Flash, and Emerging Memory

#series-navbar("en", nav)

#doc-toc("en")


This chapter supplements the preceding memory hierarchy and cache material. It
focuses on the device and controller effects that are
usually hidden by the abstract memory interface: retention variation,
read-disturbance attacks, flash translation and garbage collection, and the
architectural choices needed by nonvolatile and persistent memories.

The same cross-layer method is useful throughout. First identify the physical
state that is changing, then identify the abstraction that hides that change,
and finally ask which controller, software policy, or error-correction code can
restore correctness without destroying performance, energy efficiency, or
security.

== DRAM Reliability Beyond the Idealized Cell

The basic DRAM organization and the `ACTIVATE`--`READ/WRITE`--`PRECHARGE`
sequence are described in the memory-organization chapter. Real chips add two important
failure dimensions:

- *Retention loss*: a capacitor leaks charge while a row is not accessed. The
  controller must refresh every row before its stored value becomes
  undecodable.
- *Read disturbance*: activating a row changes the electrical environment of
  nearby rows. Repeated or unusually long activation can move a victim cell
  across its sensing threshold even though software never writes that cell.

These mechanisms are related but not interchangeable. A cell that is weak under
retention is not necessarily weak under RowHammer, and a defense tuned for one
mechanism can leave the other exposed.

=== Retention Is Heterogeneous

Retention time is not one fixed property of a DRAM chip. It depends on the row
and cell location, the stored data pattern, temperature, process variation, and
the time since the last refresh. A retention profile therefore contains a
distribution of safe refresh intervals rather than one useful value for every
row.

Temperature accelerates leakage. A controller that uses the worst-case interval
for all rows is correct but spends refresh bandwidth on rows that could safely
wait longer. Conversely, assuming a typical interval can silently corrupt weak
rows. Profiling must also account for variable-retention-time behavior and the
fact that the data pattern in neighboring cells changes the measured margin.

=== RAIDR: Heterogeneous Refresh

RAIDR (Retention-Aware Intelligent DRAM Refresh) exploits the retention-time
distribution instead of treating every row identically. A short profiling phase
classifies rows into a small number of retention bins. The refresh controller
then refreshes each bin at the shortest interval that is safe for that class.

The implementation is intentionally metadata-light: a row needs only a compact
bin identifier, while a small set of counters or queues tracks when each class
is due. A weak row still receives the conservative refresh rate; strong rows
are refreshed less often. The resulting bandwidth and energy savings come from
removing unnecessary refreshes, not from weakening the correctness guarantee.

#figure(
  block(
    width: 100%,
    inset: 8pt,
    radius: 2pt,
    stroke: 0.5pt + rgb("#9AA4B2"),
    fill: rgb("#F6F8FB"),
  )[
    `profile rows -> classify retention bins -> schedule per-bin refresh -> preserve data`
    #v(4pt)
    `weak rows: short interval     typical rows: medium interval     strong rows: long interval`
  ],
  caption: [RAIDR replaces one worst-case refresh interval with a small set of safe, row-class-specific intervals.],
)

RAIDR illustrates a general design rule: profiling can be useful only when the
property being profiled is stable enough, the metadata is cheaper than the
saved work, and the controller has a safe fallback when the device ages or the
environment changes.

== RowHammer: Mechanism, Characterization, and Attack Surface

=== From Activation to a Bit Flip

In a DRAM subarray, a wordline controls many access transistors and adjacent
wordlines are not perfectly electrically isolated. The simplified attack chain
is:

#figure(
  block(
    width: 100%,
    inset: 8pt,
    radius: 2pt,
    stroke: 0.5pt + rgb("#9AA4B2"),
    fill: rgb("#F6F8FB"),
  )[
    aggressor `ACT/PRE` -> coupling on adjacent wordlines ->
    victim charge loss -> threshold crossing / bit flip
    #v(5pt)
    The victim row is not addressed by the program that triggers the disturbance.
  ],
  caption: [RowHammer is a circuit-level coupling effect that becomes a system-level integrity and security failure.],
)

The classic double-sided pattern alternates accesses to rows on both sides of a
victim. Each access must reach DRAM rather than hit in a cache, so an attacker
can use cache-line flush instructions, eviction sets, or uncached mappings. A
barrier or equivalent ordering instruction keeps the access sequence from being
reordered by the processor. In pseudocode:

`repeat: read X; read Y; flush X; flush Y; fence`

where `X` and `Y` map to two aggressor rows in the same bank and the victim
lies between them. The exact physical mapping is normally hidden, so practical
attacks first locate suitable rows through timing or memory-allocation
side channels.

=== What Experiments Show

The first large-scale characterization tested 129 modules manufactured from
2008--2014. In the three vendor groups, 86% (37/43), 83% (45/54), and 88%
(28/32) of modules were vulnerable. The most affected modules exhibited up to
about $1.0 times 10^7$, $2.7 times 10^6$, and $3.3 times 10^5$ errors in the
tested region.

Important observations are more useful than any one threshold:

- Victims are usually adjacent to the aggressor; non-adjacent flips are rare
  in the original characterization.
- Increasing the time between aggressor accesses reduces errors, while
  increasing the refresh interval increases them.
- The data pattern in aggressor and victim rows changes the error rate because
  the coupling depends on the stored charge and neighboring cell state.
- Victim cells and retention-weak cells have almost no overlap in the original
  experiments. Retention profiling is therefore not a substitute for
  disturbance testing.
- Errors are repeatable: more than 70% of victim cells that flipped did so in
  every one of ten repeated tests.
- Up to four errors can occur in one cache line. A single-error-correct,
  double-error-detect (SECDED) code cannot guarantee correction of such a line.

Later measurements show technology scaling pressure. Across 1580 DDR3, DDR4,
and LPDDR4 chips, newer nodes generally exhibit more flips, more vulnerable
rows, and flips farther from the aggressor. Reported first-flip thresholds have
fallen from roughly 139K hammers in older DDR3 to about 24K in newer DDR3, 10K
in newer DDR4, and 4.8K in LPDDR4. These numbers vary substantially by vendor,
die, row, data pattern, and test conditions; they are not a universal safety
threshold.

=== Why This Is a Security Vulnerability

The bit flip is caused below the ISA, but it can corrupt any data that happens
to occupy the victim row. Demonstrated consequences include:

- modifying page-table entries to obtain write access to physical memory;
- escaping virtual-machine or process isolation;
- corrupting cryptographic keys, model parameters, or control metadata;
- remotely inducing flips through JavaScript, WebGL, RDMA, or a peripheral that
  can generate high-rate memory traffic.

The attack is therefore not limited to a malicious kernel module. A user-level
program can turn a reliability defect into a privilege-escalation or denial of
service primitive. Mitigations must cover both direct CPU accesses and traffic
generated by GPUs, DMA engines, and network interfaces.

=== Defense Taxonomy

#three-line-table(
  columns: (1.45fr, 2.25fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *Family* | *Mechanism* | *Main cost or gap* |
  | :------- | :--------- | :---------------- |
  | Stronger cells / ECC | Increase physical margin or correct more errors | Area, energy, and multi-bit errors can exceed the code capability |
  | More frequent refresh | Shorten the time in which many activations can accumulate | Refresh bandwidth and power grow with density |
  | Physical isolation | Place sensitive rows farther from aggressors or add guard rows | Wastes capacity and does not cover unknown adjacency |
  | Reactive refresh | Detect a hot aggressor and refresh its neighbors | Requires accurate, scalable tracking and may be attacked |
  | Proactive throttling | Limit activation rate from an aggressive requester | Reduces performance and can be a denial-of-service vector |
  | Probabilistic refresh | Refresh neighbors after a close with a small probability | Requires a trustworthy random source and a probabilistic guarantee |
]

No one family dominates for all thresholds. A high threshold makes exact
tracking affordable; a low threshold makes false positives and metadata traffic
the dominant cost. A robust design also specifies what happens on counter
overflow, row remapping, rank power-down, refresh overlap, and a change in the
physical row mapping.

=== PARA: A Stateless Probabilistic Baseline

PARA (Probabilistic Adjacent Row Activation) refreshes the neighbors of a row
when that row is closed, with probability $p$. With $p = 0.005$, the original
analysis estimated a one-year error probability of approximately
$9.4 times 10^(-14)$. Across 29 benchmarks, the average slowdown was 0.20%
and the maximum slowdown was 0.75%.

PARA needs no per-row activation table: each close event consumes one random
decision and, on a hit, a preventive refresh. Raising $p$ strengthens the
probability bound at the cost of more refreshes. The guarantee assumes that the
random decisions are independent enough, the adjacent-row relation is known,
and the timing slack allows a neighbor refresh. A controller implementation
must know physical adjacency; a chip implementation can use its internal row
decoder directly.

=== Tracking-Based Designs

Tracking-based schemes compare an activation count with a preventive threshold.
They differ mainly in how much state they keep and where it lives:

- exact per-row counters are accurate but scale with the number of rows and
  banks;
- shared counters reduce area but overestimate some rows, causing extra
  refreshes or throttling;
- hybrid schemes keep cheap approximate state for most rows and exact state for
  currently hot rows.

The threshold must be below the smallest vulnerable activation count, not the
average count. Otherwise a safe-looking average can leave a single weak victim
unprotected. Counters also need a reset or decay policy aligned with the DRAM
refresh window; resetting too early loses security, while never resetting
causes permanent throttling.

=== New Attack Patterns and Defensive Lessons

The attack surface has continued to evolve as vendors added on-die Target Row
Refresh (TRR)-like mechanisms. *TRRespass* searches for many-sided access
patterns that distribute activations across several aggressors. A detector that
only remembers the hottest row can therefore miss the aggregate pressure on a
victim. The study found vulnerable DDR4 modules and mobile devices despite the
presence of advertised TRR; the exact vulnerable set depends on the module and
the tested pattern.

*U-TRR* is a methodology for reverse-engineering and stress-testing these
undocumented defenses. Across 45 tested modules, every module admitted a
pattern that could induce disturbance under some configuration, and one
configuration produced up to seven flips in an 8-byte word. The result is a
warning about treating a black-box mitigation as a proof: an attacker can
search the hidden state machine's threshold, refresh timing, and replacement
policy.

*Half-Double* reaches a victim through an intermediate row. A strong aggressor
`A` can amplify a weaker disturbance in neighboring row `B`, which then affects
row `C`; thus the victim need not be directly adjacent to the row the program
activates most often. Physical isolation and a two-neighbor assumption are not
enough when coupling extends across more than one wordline.

*BlockHammer* takes a software-compatible approach: approximate activation
counts with Bloom-filter-like structures and throttle or blacklist a source
before it reaches the vulnerable threshold. It avoids per-row state in DRAM,
but false positives reduce throughput and an adversary can try to fill the
filter. The general invariant is the same as for CoMeT and ABACuS: an
approximation may overprotect, but it must never undercount an active aggressor.

Characterization also has to vary the physical and temporal conditions. Lower
wordline voltage increases disturbance susceptibility in real chips, while
temperature, retention age, data pattern, and device aging shift the first-flip
threshold. *Variable Read Disturbance* measurements show that a row's threshold
can change over time even with the same nominal command stream. A one-time
profile should therefore be treated as a conservative lower bound and
revalidated across voltage, temperature, and lifetime, not as a permanent
constant.

== RowPress and Combined Read Disturbance

=== RowPress Is Not Just Faster RowHammer

RowPress keeps an aggressor row open for a long time instead of repeatedly
closing and reopening it. The extended `tAggON` exposes adjacent victims to a
different electrical stress. A proof-of-concept program reads many cache blocks
within the same aggressor row before flushing them, so one `ACTIVATE` can keep
the row open while the controller services many column accesses.

Experiments on 164 DDR4 chips from all three major manufacturers found:

- the minimum activation count (`ACmin`) fell by one to two orders of
  magnitude as `tAggON` increased;
- increasing `tAggON` from 36 ns to 7.8 us reduced `ACmin` by 21x on average;
- at extreme open times (for example 30 ms), one activation was enough on some
  rows;
- at 80 C and `tAggON = 7.8 us`, about 50% fewer activations were needed than
  at 50 C;
- only about 0.013% of RowPress-vulnerable cells overlapped RowHammer-vulnerable
  cells when `tAggON >= 7.8 us`;
- RowHammer flips were predominantly 0-to-1, whereas RowPress flips were
  predominantly 1-to-0;
- at sufficiently long open times, single-sided RowPress can be more effective
  than double-sided RowPress, unlike the usual RowHammer pattern.

These differences imply a separate mechanism and a separate test space. A
defense that only counts `ACTIVATE` commands can miss a long-open row.

=== Mitigating RowPress

A practical adaptation has two parts:

1. bound the maximum row-open time (`tmro`) so a row cannot remain active
   indefinitely; and
2. configure the RowHammer mitigation threshold using the lower `ACmin` caused
   by the permitted open time.

The bound trades row-buffer locality for security. In the RowPress study,
Graphene-based mitigation added roughly 0.63% average and 6.4% maximum
overhead across tested `tmro` values, while PARA-based adaptation added about
4.5% average and 13.1% maximum overhead in the reported configuration. The
exact values depend on workload and threshold, but the lesson is general:
security must be evaluated against both activation count and residence time.

=== Combining RowHammer and RowPress

The combined pattern hammers one aggressor at the minimum row-open time and
presses the other aggressor for a long time. On 84 DDR4 chips, the combined
pattern induced the first flip up to 46.1% faster than the state-of-the-art
RowPress pattern and required 40.5--48.0% fewer activations in the reported
configurations. The first bits to flip differed among RowHammer, RowPress, and
the combined pattern, supporting the hypothesis that the two aggressors do not
contribute symmetrically.

== Spatially Aware and Scalable DRAM Defenses

=== Svard: Learn the Real Vulnerability Map

A tempting shortcut is to predict a row's RowHammer vulnerability from its
bank, subarray, row address, or distance from the row buffer. Measurements on
144 DDR4 chips from SK Hynix, Micron, and Samsung show that these spatial
features are weak and manufacturer-dependent predictors: vulnerability varies
irregularly across rows, and only a few feature combinations reach useful
classification quality for one manufacturer. A defense should therefore
measure the chip rather than assume that physical proximity implies identical
behavior.

Svard (the name is written in ASCII here) profiles a chip and assigns each row
to a small vulnerability class. A compact per-row value, for example four bits,
records the class. The memory controller or DRAM can then use the class to
choose a threshold for an existing mitigation such as PARA, BlockHammer,
Hydra, AQUA, or RRS. A robust row receives fewer preventive actions; a weak row
gets a lower threshold. The profiling result is a policy hint, not a license
to disable protection: aging, temperature, and voltage can move a row to a
different class, so the profile needs a refresh or conservative margin.

The metadata is small relative to the array. The reported design stores about
4 bits per 8 KiB row, roughly 0.006% of DRAM-array capacity. A controller-side
implementation was estimated at about 0.027% of processor-die area per bank,
with no added request latency on the normal path. In the evaluated settings,
the preventive-action overhead fell by about 2.4x for BlockHammer, 2.7% for
Hydra, 1.6x for PARA, and 3.0x for RRS; the exact reduction depends on the
baseline threshold and workload. The important design rule is to use a
measured lower bound for each class, not the average vulnerability.

=== CoMeT: Approximate the Cold Rows, Track the Hot Rows

Exact per-row activation counters scale poorly with the number of banks and
rows. CoMeT combines two structures:

- A Count-Min Sketch hashes every row into several small counter arrays. An
  activation increments one counter in each hash row. The estimated count is
  the minimum of the hashed counters, so collisions overestimate a row but
  cannot make a hot row look colder.
- A Recent Aggressor Table (RAT) stores exact row tags and counters for the
  small set of currently hot aggressors. Saturating counters stop growing once
  the preventive threshold is reached, which bounds update energy and avoids
  wraparound.

One evaluated configuration used four hash functions with 512 counters each
and a 128-entry RAT. When a sketch estimate or RAT counter approaches the
threshold, the controller refreshes the victim neighbors, throttles the
aggressor, or migrates to the selected mitigation policy. A replacement in the
RAT must preserve the security invariant: evicting an entry cannot erase an
unexpired count unless its information is conservatively retained in the
sketch.

Compared with a fully exact Graphene-style table, CoMeT reported up to 74.2x
less tracking area and up to 39.1% better performance than Hydra in the tested
range. Its area/performance point was within about 1.75% of Graphene's
overhead, and one reported single-core configuration added roughly 4.01%
performance and 2.07% energy overhead relative to an unprotected baseline.
These numbers are workload- and threshold-specific; the general advantage is
that sketch collisions cause extra protection, whereas undercounting is
forbidden.

=== ABACuS: Exploit Sibling Rows Across Banks

Rows at the same row ID in different banks are often called *siblings*.
A hammering program can distribute activations among these siblings so that a
per-bank counter misses the aggregate pressure on the shared victim region.
ABACuS tracks the maximum activation count among a sibling group with a
Sibling Activation Vector (SAV). Frequent-item/spillover structures keep the
few groups that are currently close to the threshold while representing the
rest compactly.

For $B$ banks, one group-level count can replace approximately $B$ separate
counters when the security policy only needs the maximum sibling pressure. A
16-bank example therefore reduces the counter count by about 16x. The design
also avoids the counter-storage doubling that a naive per-bank scheme would
incur when moving to 32-bank DDR5. A reported counter update takes about
1.2 ns; at low thresholds ABACuS outperformed Hydra, REGA, and PARA in the
evaluated workloads, while remaining close to Graphene's protection. Area was
about 20.3x smaller than Graphene at a 1K threshold and 22.7x smaller at a
125 threshold.

The common invariant for CoMeT and ABACuS is monotonicity: approximation may
overestimate activity and trigger an unnecessary refresh, but it must not
underestimate activity during the active refresh window. The state must also
be reset or aged only at a point where all possible victim effects have been
covered.

=== DDR5 RFM: Ask the Device to Help

DDR5 adds a Refresh Management (RFM) interface. The memory controller issues an
RFM command and the DRAM uses the granted time to perform preventive work,
including neighbor refreshes. This shifts part of the mitigation state and
timing contract into the DRAM device.

Two policies from the slides illustrate the design space:

- *PRFM* (periodic RFM) keeps aggregate or low-accuracy bank counters in the
  controller and requests RFM at a fixed schedule. It is simple but can waste
  RFMs when traffic is benign, and a low threshold makes the request rate
  grow rapidly.
- *PRAC* (per-row activation counting) keeps per-row activation state in the
  DRAM and sends a back-off signal when a row approaches the threshold. The
  controller then supplies RFM time. PRAC can provide a mathematical bound
  near a threshold of about 20 in the reported analysis, but its counter and
  signaling work are not fully parallel with ordinary activation traffic.

A DDR5-3200AN timing comparison in JESD79-5C (April 2024) illustrates why RFM
is not free:

#three-line-table(
  columns: (1.35fr, 1.05fr, 1.35fr),
  inset: 5pt,
  align: left,
)[
  | *Timing* | *Change* | *System consequence* |
  | :------- | :------ | :------------------ |
  | $t_"RP"$ | +21 ns (+140%) | More time to close/precharge before another row |
  | $t_"RAS"$ | -16 ns (-50%) | Shorter minimum row-active interval |
  | $t_"RTP"$ | -2.5 ns (-33%) | Earlier read-to-precharge boundary |
  | $t_"WR"$ | -20 ns (-66%) | Earlier write recovery boundary |
  | $t_"RC"$ | +5 ns (+10%) | Lower maximum row-cycle rate |
]

A wave/feinting attack sends decoy-row activations that keep the bank busy while
hiding the real aggressor pattern. In the reported model, safe PRFM operation
at a low threshold could require approximately one RFM every eight
activations. PRAC reduced this exposure, but one configuration still cost
about 10% performance and 19% energy. As the RowHammer threshold was lowered,
PRFM's overhead grew roughly 25x in performance and 5x in energy; an adversarial
pattern could consume up to 79% of DRAM throughput and degrade performance by
up to 98% (94% average in that experiment).

Useful variants include PRAC-N, which changes the timing contract, a hybrid
PRAC+PRFM policy, and an optimistic PRAC variant that avoids timing changes but
relies on a less conservative response. The choice is a security/performance
contract between the controller and the DRAM, not merely a counter
implementation.

*Chronus* evaluates these industry mechanisms as complete timing/state
contracts and addresses shortcomings in emerging PRAC-style defenses. Its
lesson is that an on-die counter is not sufficient by itself: the back-off
signal, controller response latency, number and scope of RFM operations,
counter reset, and adversarial traffic during the response window must jointly
bound the maximum activations. A secure DDR5 evaluation should therefore model
the published timing changes and search adversarial command sequences, rather
than assuming that the presence of PRAC eliminates RowHammer.

=== HBM: High Bandwidth Does Not Remove Disturbance

High Bandwidth Memory exposes many channels and banks through a 3D-stacked
interface, but each bank still contains vulnerable DRAM cells. Tests covered
six HBM2 chips; each chip has eight channels, two pseudo-channels per channel,
16 banks per pseudo-channel, and 16,384 rows per bank, with 1 KiB (8 Kbit) in
each row. Vulnerability varied by channel, bank, row, and data pattern; one
chip exhibited as many as 247 flips in a single 8-Kbit row, and the first-flip
activation count was as low as 14,531 (about 1.3 ms at the tested rate). Fewer
than twice that count was enough to obtain ten flips on some rows.

HBM devices also contain undocumented or lightly documented on-die mitigation.
One observed policy refreshed both adjacent rows after roughly 17 periodic
refresh events. It identified an aggressor after a row had been refreshed by
the mitigation and after its activation count exceeded about half the
threshold. Dummy aggressors can keep this detector busy and hide a real
aggressor, so tests must include interleaved decoy traffic. Retention-induced
flips and aging change the measured threshold over time; in one analysis about
0.109% of apparent flips were removed after filtering retention failures.

The practical lesson is to treat HBM as a distinct target. A DDR4 threshold,
bank mapping, or assumed TRR behavior cannot simply be copied to HBM without
characterization.

== Simulation and Testing Infrastructure

=== SoftMC and Experimental Methodology

*SoftMC* is an earlier open-source FPGA infrastructure for issuing flexible,
low-level DRAM command sequences through a C++ API. It makes experiments such
as retention profiling, RowHammer, timing reduction, and row-buffer studies
repeatable without proprietary controller firmware. DRAM Bender extends the
same idea with a more extensible RISC-like command engine and broader device
support.

An experiment should separate four concerns: generate a controlled command
trace, map logical rows to physical banks/subarrays, observe data errors and
timing, and record environmental state. Repeating a pattern at several
temperatures and voltages, filtering retention failures, and reporting both
the first-flip threshold and the complete error distribution avoids confusing
a device's ordinary retention weakness with read disturbance.

=== Ramulator2

Ramulator2 models a memory system as hierarchical state machines for channel,
rank, bank-group, and bank. Each command is dispatched through a lambda that
checks timing and state, then updates the affected nodes and energy counters.
Address mapping, scheduling, refresh, row policy, and mitigation are modular
components, so a new defense can be compared without rewriting the DRAM model.

The evaluated framework release includes DDR3, DDR4, DDR5, LPDDR4/5,
HBM1/2/3, and GDDR6 models. A useful evaluation should report the address mapping,
row policy, refresh policy, timing configuration, traffic source, and
mitigation threshold; otherwise a result cannot be reproduced or fairly
compared.

=== DRAM Bender

DRAM Bender is an FPGA-based, RISC-like experimental platform for issuing
low-level DRAM commands. Its fixed-latency pipelined core supports integer
operations, loops, and explicit command sequences; C++ and Python APIs make
test generation practical. The platform was demonstrated with DDR4 DIMMs and
SODIMMs and with HBM2 boards, with optional temperature and voltage control.
The reported fine-grained timing control is platform-specific: about
$plus.minus 1.5$ ns for DDR4 on XCU200 and $plus.minus 1.67$ ns for HBM2 on
XCU50.

This access is important for effects that simulators may omit: RowPress,
HBM's internal mitigation, processing-in-memory experiments, in-DRAM logic,
and true-random-number generators. A sound experiment separates retention
failures from disturbance failures, controls temperature and voltage, repeats
patterns across rows and chips, and records the first-flip count as well as
the total number of flips.

== NAND Flash and SSDs

=== Cell Physics and State Encoding

A NAND flash cell is a transistor whose threshold voltage $V_"TH"$ is
programmed by moving charge onto a floating gate (in planar NAND) or a charge
trap (in 3D NAND). During a read, a reference voltage $V_"REF"$ determines
whether the cell conducts. A single-level cell stores one bit; an $m$-bit
multi-level cell (MLC/TLC/QLC for $m=2/3/4$) stores one of $2^m$ threshold
voltage states.

More states increase density but narrow the voltage margin. Program and
retention noise can move a cell across a neighboring state, so the controller
uses multiple read references and strong ECC. The programmed state generally
has a higher threshold voltage; erase removes charge and lowers it. NAND
therefore cannot freely change a programmed 0 back to 1 (or vice versa,
depending on the convention) in place: an erase-before-write operation is
needed for a whole block.

=== String, Page, Block, Plane

Cells in a NAND string are connected in series, typically around 128 cells in
a recent 3D stack. A wordline selects one page of the string; unselected
wordlines receive a pass voltage $V_"PASS"$ so that the selected cell controls
the string current. The useful hierarchy is:

#three-line-table(
  columns: (1.15fr, 1.45fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Level* | *Contains* | *Parallelism / operation* |
  | :------ | :-------- | :----------------------- |
  | Cell | One threshold-voltage state | Read by sensing string current |
  | Page | Cells on one wordline, often 16 KiB or more | Read and program unit |
  | Block | Pages sharing wordlines, often hundreds of pages | Erase unit; cannot erase one page |
  | Plane | More than 1,000 blocks with shared peripheral logic | Same-offset operations can run in parallel |
  | Die | Usually two or four planes | Independent internal operation |
  | Package / channel | Multiple dies behind one interface | Controller schedules requests and hides busy time |
]

A page read applies $V_"READ"$ to the selected wordline and $V_"PASS"$ to the
others, senses the bitlines, and runs on-die or controller ECC. MLC and TLC
reads may require several sensing steps; the chosen state encoding changes the
number of steps and latency. A page program uses incremental step-pulse
programming (ISPP): apply a small voltage pulse, verify, then increase the
pulse until all target cells reach their state. Non-target cells are biased with
$V_"PASS"$ to suppress disturb.

A plane operation can issue the same command to blocks at the same page offset
in multiple planes. A controller groups such blocks into a *superblock* so
that multi-plane reads, programs, and erases approach linear throughput. The
constraint is strict: command type, page offset, and timing must agree across
the participating planes.

#figure(
  block(
    width: 100%,
    inset: 9pt,
    radius: 2pt,
    stroke: 0.5pt + rgb("#9AA4B2"),
    fill: rgb("#F8FAFC"),
  )[
    *Host LBA* -> *HIL queues* -> *FTL LPA -> PPA* -> *NAND channel / die / plane*

    read or write; priority and buffering; mapping + GC + wear; page read/program, block erase
    #v(7pt)
    A write is translated, placed out of place, and later reclaimed by block-level erase.
  ],
  caption: [Simplified SSD request path. The host sees logical block addresses; the FTL and flash controller expose physical parallelism and reliability mechanisms.],
)

=== Program, Read, and Erase Granularity

A page can be programmed only once or a small number of times before its block
is erased. Updates are consequently *out of place*: the controller writes a new
physical page, marks the old page invalid, and changes the logical-to-physical
mapping. A block erase resets all pages and takes milliseconds, much longer than
a page read or program.

Typical order-of-magnitude timings are:

#three-line-table(
  columns: (1.35fr, 1.1fr, 1.7fr),
  inset: 5pt,
  align: left,
)[
  | *Operation* | *Typical time* | *Main source* |
  | :---------- | :------------- | :------------ |
  | Page read ($t_R$) | 50--100 us | Sense selected cell plus transfer |
  | Page program ($t_"PROG"$) | 700--1000 us | ISPP pulses and verify |
  | Block erase ($t_"BERS"$) | 3--5 ms | Remove charge from all wordlines |
]

An SSD request adds command setup, DMA, ECC decode, queueing, and channel
contention. A useful first-order read estimate is

$ t_"read" approx t_"CMD" + t_R + t_"DMA" + t_"ECCDEC" + t_"RND" $

and a corresponding program estimate is

$ t_"program" approx t_"CMD" + t_"DMA" + t_"ECCENC" + t_"RND" + t_"PROG" . $

The actual host-visible latency can be lower than either serialized estimate
when independent dies and planes overlap their internal operations.

=== Why SSDs Need a Controller

A contemporary SSD controller contains a host interface layer (HIL), request
queues, a flash translation layer (FTL), DRAM or SRAM for mapping and data
buffers, ECC/LDPC engines, and several flash channels. Each channel connects
packages, dies, and planes. A write buffer absorbs bursts; mapping metadata and
validity information are persisted so a power failure does not expose stale
physical pages.

SATA SSDs preserve a disk-like command path and usually deliver thousands of
IOPS. NVMe removes much of the legacy serialization and exposes many submission
and completion queues, allowing millions of IOPS when the flash and controller
have enough parallelism. The interface alone does not guarantee low latency:
GC, ECC retries, channel conflicts, and a full write buffer can dominate.

The physical capacity exceeds the advertised logical capacity through
*over-provisioning*. Spare blocks provide room for out-of-place updates,
garbage collection, bad-block replacement, and wear leveling. More spare space
usually improves steady-state write latency and endurance at the cost of
usable capacity.

=== Mapping Granularity and Power Loss

The FTL maps a logical page address (LPA) to a physical page address (PPA).
Page-level mapping gives flexible placement but consumes DRAM. For a 2 TB
SSD with 4 KiB logical pages, a four-byte mapping entry alone is about 2 GB;
hybrid or log-block mappings reduce DRAM use but add lookup and merge work.

The NAND page size grew from a few hundred bytes to 16 KiB or more while file
systems still issue 512-byte sectors or 4 KiB blocks. A page buffer or write
cache accumulates small writes until a full page can be programmed. The
controller must retain the mapping and dirty data across a crash, so SSDs
commonly include power-loss protection capacitors and a recovery journal. A
`TRIM`/deallocate hint lets the FTL mark pages invalid without copying them
during GC.

== Garbage Collection, Wear, and Parallelism

=== Garbage Collection

GC reclaims a block whose pages are mostly invalid. It:

1. selects a victim block using invalid-page fraction, age, wear, and urgency;
2. reads each still-valid page and writes it to a new physical location;
3. updates the LPA-to-PPA map and page metadata; and
4. erases the old block, returning it to the free pool.

A greedy policy chooses the block with the most invalid pages, but a pure
greedy policy can starve old blocks and create wear imbalance. Lazy erase
defers the expensive erase until a free block is actually needed. Background
GC uses idle bandwidth; foreground GC is unavoidable when the free pool is
low and causes large tail-latency spikes.

Consider a 576-page block with 5% valid pages, $t_R=100$ us,
$t_"PROG"=700$ us, and $t_"BERS"=5$ ms. Copying 28 valid pages already costs
about $28 times (100+700) = 22,400$ us, and the erase adds 5,000 us before
controller overhead. The example shows why copying valid data, rather than the
erase alone, often dominates GC. Progressive GC, write-hotness separation,
over-provisioning, and TRIM reduce this cost.

=== Wear Leveling and Write Amplification

Each program/erase (P/E) cycle damages the tunnel dielectric and widens the
threshold-voltage distribution. *Dynamic wear leveling* places new writes on
the least-worn available blocks; *static wear leveling* occasionally moves
cold data out of an old block so that its wear can catch up. The FTL tracks
per-block erase counts and retires blocks that exceed the endurance limit.

Write amplification is

$ "WA" = ("internal bytes programmed") / ("host bytes written"). $

It includes valid-page copies during GC, metadata and journal writes, parity
updates, and partial-page merges. Small random writes and a nearly full SSD
raise `WA` sharply. Lowering write amplification improves latency, energy, and
lifetime simultaneously, but aggressive hot/cold separation can itself move
data and add writes.

=== Scheduling and Fairness

The controller arbitrates requests at several levels: host queues, channels,
dies, planes, and the internal NAND command queue. Reads are usually latency
critical; program and erase operations are long and can be suspended when a
read arrives. Read/program suspend improves responsiveness but requires
additional buffers and bookkeeping and can reduce sustained write bandwidth.

The FLIN scheduler addresses fairness inside an NVMe SSD. It first inserts
requests with awareness of queue intensity, then performs priority-aware
arbitration, and finally balances wait time when selecting a flash transaction.
The evaluated implementation used less than 0.06% additional DRAM and
improved fairness by about 70% and performance by about 47% over a
Sprinkler-plus-fairness baseline; maximum slowdown fell from more than 500x to
under 80x in the reported workload set.

The Venice design treats a flash channel as a shared network. Channel and
package conflicts can increase average latency by about 57%. Venice reserves
a path with a low-cost scout packet, then uses fully adaptive non-minimal
routing to avoid congested links without changing the flash chips. Reported
performance/cost was about 1.9x/1.5x the best prior SSD designs, with 99.98%
of requests conflict-free and 46% lower energy than the most energy-efficient
prior design. These results depend on the same queue depth and flash geometry;
they illustrate that internal interconnects are part of SSD performance.

=== Controller-Level Optimizations

Read-data optimization (RDO) chooses a subpage or partial sensing operation
when the host needs only part of a large NAND page. It reduces transfer and
ECC work but needs extra page-buffer control. Cache read overlaps the NAND
array's $t_R$ or DMA with the next command; similarly, program/erase suspend
allows a high-priority read to interrupt a long operation. Each optimization
trades silicon buffers, scheduling complexity, and sometimes endurance for
lower average or tail latency.

=== Representative SSD Research Directions

Representative SSD case studies show that the controller, flash media, and
host software form one system. They are complementary rather than alternative
FTLs:

#three-line-table(
  columns: (1.35fr, 2.15fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *Work* | *Main idea* | *System lesson* |
  | :----- | :--------- | :-------------- |
  | MQSim | Detailed multi-queue NVMe SSD simulation | Queueing, flash timing, and host submission policy must be modeled together |
  | Evanesco | Architectural support for efficient data sanitization | Secure erase can be accelerated without treating every page as an ordinary write |
  | Read-retry optimization | Predict an initial reference voltage and search the likely direction first | Avoid repeated full sweeps when retention has shifted the optimum |
  | DeepSketch | ML-based reference search for post-dedup delta compression | Compression metadata and flash traffic trade computation for capacity and bandwidth |
  | Sibyl | Online-RL placement for hybrid storage | Placement should adapt to workload phase, device latency, and endurance |
  | MegIS / GenStore | Filter metagenomic/genomic data inside storage | Early filtering removes host transfers before expensive alignment |
  | CIPHERMATCH | Pack data and perform homomorphic string matching in flash | In-storage computation can reduce encrypted-data movement while preserving a security contract |
]

These names are useful anchors for further reading, but their reported gains
are workload- and device-specific. A fair comparison must hold queue depth,
over-provisioning, flash geometry, ECC, and the host interface constant.

== NAND Error Mechanisms and Reliability

=== Four Error Sources

The controller must distinguish four recurring NAND error mechanisms:

#three-line-table(
  columns: (1.35fr, 2.05fr, 1.7fr),
  inset: 5pt,
  align: left,
)[
  | *Mechanism* | *Physical cause* | *Typical response* |
  | :---------- | :-------------- | :---------------- |
  | Read error | Sensing noise, coupling, or an incorrect reference | Read retry, adaptive $V_"REF"$, ECC |
  | Erase error | Incomplete erase or excessive erase stress | Retry, block retirement, stronger ECC |
  | Program interference | Neighbor wordline programming shifts a victim's threshold | Neighbor-aware reference prediction, extra margin |
  | Retention loss | Stored charge leaks with time, wear, and temperature | Refresh/reprogram, retention-aware read, ECC |
]

The raw bit-error rate (RBER) grows approximately exponentially with P/E cycle
count. Retention errors dominate after long idle periods; one measured MLC
population attributed more than 99% of one-year errors to retention. Cells
programmed with more charge have more room to leak, and the direction of
state transitions is data-pattern dependent (for example, 01-to-10 and
00-to-01 transitions can have different rates). An ECC-corrected read is not a
failure-free read: the controller should track correction count and its trend
before an uncorrectable error occurs.

=== Threshold-Voltage Distributions

Each programmed state is a distribution of threshold voltages rather than a
single value. P/E cycling broadens and shifts the distributions; retention
moves them further, and read/program interference adds state- and
neighbor-dependent distortion. A Gaussian distribution plus additive white
noise is a useful first model (about 95% prediction accuracy in one study),
but modern 3D NAND exhibits non-Gaussian tails and layer-specific behavior.

The optimum reference is the set of decision voltages that minimizes overlap
between adjacent states. A fixed reference therefore becomes stale as a block
ages or its data rests. Read-retry hardware can sweep candidate references,
but each extra sense operation adds latency and energy.

=== Retention Refresh (FCR)

Flash Correct-and-Refresh (FCR) periodically reads a block before its ECC
margin is exhausted. It corrects the data, writes a refreshed copy to a new
page (or reprograms in place when the device permits it), updates the mapping,
and retires the old copy. Refresh frequency can be adapted to wear, temperature,
and measured ECC slack: a cold, lightly worn block needs less work than a
hot, heavily worn block.

The reported FCR study improved lifetime by up to 46x over no refresh. An
adaptive policy consumed less than about 1.8% extra energy at a daily refresh
cadence in the measured range. In-place refresh avoids an erase but can add
program errors and consumes the remaining program budget, so the controller
must choose between relocation and reprogramming.

=== Program Interference and NAC

Programming one wordline changes the electric field seen by neighboring
wordlines. The immediately above neighbor is usually the strongest source,
the diagonal neighbor is second, and farther neighbors still contribute.
The victim's current state and the neighbors' target states determine both the
direction and magnitude of the threshold shift.

Neighbor-assisted correction (NAC) reads a neighbor page when ECC cannot
decode the victim, chooses a conditional reference voltage based on that
neighbor's state, and reruns sensing and ECC. In an example with a
40-bit-per-1 KiB ECC budget, NAC improved lifetime by about 33% without a
measurable performance loss. The principle is to spend extra sensing only on
the rare hard pages rather than widening every page's margin.

=== Read Disturbance

Every read applies $V_"PASS"$ to unselected wordlines. Repeated pass-voltage
stress can slowly program an unselected cell, especially in a block that is
read many times. The controller can lower $V_"PASS"$ while keeping enough
margin for the current ECC budget. A daily tuning procedure estimates ECC
slack for a block, lowers $V_"PASS"$ until the error budget is nearly crossed,
then raises it by a small safety margin. A reported 512 GB implementation
needed about 128 KiB of metadata and 24.34 s of tuning per day, and extended
lifetime by about 21%.

Read-Disturb Recovery (RDR) handles a block after an uncorrectable read. It
backs up valid data, deliberately applies a controlled disturb sequence (up to
100K reads in the experiment), measures each cell's threshold shift, and
classifies cells or blocks as disturbance-prone or resistant. The controller
then remaps or uses a lower pass voltage for the prone population. The
reported classification reduced RBER by up to 36% at one million disturb
cycles.

=== Retention-Aware Reading

Retention-optimized reading (ROR) learns a block's predicted optimum reference
$V_"pred"$ from its age, P/E count, and temperature. The first read uses that
reference; a read-retry sweep is reserved for pages whose ECC still fails.
Across the evaluated workloads, ROR reduced total read latency by about 29%
and cut read-retry invocations by about 30% relative to a fixed-reference
policy.

Retention failure recovery (RFR) targets very old data. Cells near the
decision boundary are separated into fast- and slow-leaking populations. Their
leakage direction provides a clue about the original state, so the controller
can infer a likely state before invoking ECC. The reported method removed
roughly 50% of raw retention errors before ECC, reducing retry work without
changing the stored data format.

=== 3D NAND Layer and Temperature Variation

Vertical stacking introduces process variation between layers. Measured RBER
can differ by as much as 21x across layers, and early retention loss can be
around 10x larger after only three hours for an unfavorable layer. Storage
temperature accelerates leakage; high program temperature increases variation,
while a dwell at a benign temperature can produce partial self-recovery.

Layer-aware techniques exploit this structure:

#three-line-table(
  columns: (1.3fr, 2.45fr, 1.55fr),
  inset: 5pt,
  align: left,
)[
  | *Technique* | *Idea* | *Reported result* |
  | :--------- | :---- | :--------------- |
  | LaVAR | Store a layer-specific optimum reference, with about two bytes per layer of metadata | Average RBER reduced about 43% |
  | LI-RAID | Interleave reliable/unreliable layers and MSB/LSB pages so parity covers the weak population | Less than 0.8% storage overhead |
  | ReMAR | Keep a compact retention model and per-block age/timestamp metadata | RBER reduced about 51.9% |
  | HeatWatch | Predict retention from wear, self-recovery, and temperature history; use layer-aware refresh | Prediction error about 4.9%; lifetime up to 3.85x |
  | WARM | Partition write-hot and write-cold data, refreshing only the hot population as needed | Up to 12.9x lifetime with adaptive refresh |
]

Combining layer-aware references, interleaving, and retention models improved
lifetime by about 1.85x in one configuration or reduced ECC overhead by about
78.9%. The values are not universal device specifications; they show why a
single chip-wide reference and refresh interval leaves substantial reliability
on the table.

A short self-recovery dwell can also help. In the measured device, increasing
the dwell from one minute to about 2.3 hours slowed retention degradation by
roughly 40%. A controller can exploit this during idle or thermal-throttling
periods, but it must account for the capacity and latency cost of delaying
writes.

=== Field Reliability and Endurance Policy

Field data is highly skewed: a small fraction of SSDs can account for most
uncorrectable errors. The controller should therefore expose health counters
such as corrected-bit count, read-retry count, P/E count, temperature history,
bad-block count, and spare-block level. Predictive retirement is safer than
waiting for an ECC failure.

A useful lifecycle policy has three regimes. Early life is dominated by
process and layer variation, useful life by retention/read-disturb and normal
wear, and wearout by rapidly rising RBER and shrinking ECC margin. Thermal
throttling or shutdown can be necessary at the last regime. Page caching,
small-write merging, GC policy, and write amplification all feed back into
this reliability trajectory.

== Emerging Nonvolatile Memories

=== From Charge Storage to Resistive State

DRAM and flash store charge and infer a bit from a voltage. Resistive memories
instead write a device resistance and read a current. The common abstraction is
still a row/line address and a sensed value, but the write pulse, endurance
limit, and failure model are different.

#three-line-table(
  columns: (1.35fr, 1.45fr, 2.0fr),
  inset: 5pt,
  align: left,
)[
  | *Technology* | *Physical state* | *Architectural implication* |
  | :---------- | :-------------- | :------------------------ |
  | PCM | Amorphous (high resistance) or crystalline (low resistance) phase | Writes are asymmetric and energy-intensive; resistance drifts |
  | STT-MRAM | Parallel or anti-parallel magnetic tunnel junction | No refresh and fast reads; writes need high current |
  | ReRAM / memristor | Conductive filament or analog conductance | Dense crossbars can perform in-array multiply-accumulate |
  | Persistent DRAM-like NVM | Nonvolatile bit state behind a load/store interface | Stores data across power loss, so ordering and recovery become architectural |
]

=== Phase-Change Memory (PCM)

PCM uses a chalcogenide material. A sustained SET current heats a cell above its
crystallization temperature, producing a low-resistance state; a short, hotter
RESET pulse melts and rapidly quenches the material into a high-resistance
amorphous state. Multi-level PCM uses intermediate resistance levels, but
narrower margins make sensing and drift management harder.

Representative values from the lecture are:

#three-line-table(
  columns: (1.45fr, 1.2fr, 1.9fr),
  inset: 5pt,
  align: left,
)[
  | *Property* | *PCM* | *DRAM reference* |
  | :-------- | :--- | :-------------- |
  | Read latency | about 50 ns | about 12 ns |
  | Write latency | about 150 ns | about 12 ns |
  | Write bandwidth | about 5--10 MB/s in the reported device | Much higher |
  | Read / write current | roughly 40 / 150 uA | Lower write asymmetry |
  | Write endurance | about $10^8$ writes per cell | Refresh-limited, not P/E-limited |
  | Retention | more than 10 years at 85 C in the reported device | Volatile |
]

PCM needs no refresh and has no erase-before-write block operation, but writes
are slower and substantially more energy-intensive (roughly 2--43x DRAM energy
in the measured range). Resistance drift gradually moves a programmed level,
especially for intermediate states, so reads need age-aware references and ECC.
For multi-level PCM, closer resistance states require more precise sensing and
programming; a representative design incurs roughly 2x read and 4x
write latency/energy versus single-level operation. Bit values are asymmetric:
one high-order bit may be inferred before the full multi-level read finishes,
which permits value-aware early completion instead of always waiting for the
slowest state.

A naive DRAM replacement can be about 1.6x slower and 2.2x more energy hungry,
while repeated writes can exhaust a cell in about 500 hours for a hot workload.
A PCM-aware organization narrows row buffers, writes only dirty cache blocks,
and uses a DRAM cache for hot data. One reported design reduced the average
delay to about 1.2x and energy to about 1.0x DRAM, with an average lifetime of
roughly 5.6 years. The result depends on workload temperature and write
distribution; wear leveling remains necessary.

=== STT-MRAM

An STT-MRAM bit is a magnetic tunnel junction with a reference layer and a
free layer. Parallel magnetization gives a low-resistance state and
anti-parallel magnetization gives a high-resistance state. A read senses the
resistance; a write sends a spin-polarized current that flips the free layer.

STT-MRAM is nonvolatile, so it needs no refresh and retains data through a power
failure. It offers high density and fast reads, but write latency and energy
are high, the write current stresses the access transistor, and process
variation makes the switching threshold difficult to guarantee. Differential
read margins, write-verify, ECC, and wear leveling are still useful.

A system study that placed optimized STT-MRAM arrays in a DRAM-like hierarchy
reported about 6% performance loss and about 60% energy savings relative to a
DRAM baseline. The architectural point is more robust than the exact number:
eliminating refresh energy can outweigh slower writes when the workload is
read-heavy or has enough locality.

=== Hybrid DRAM and NVM

DRAM is small, fast, and volatile; NVM is larger and persistent but has
different read/write costs and endurance. A hybrid controller can use:

- a DRAM cache for hot or write-intensive lines;
- lazy writeback and partial dirty-line writes to reduce NVM programming;
- page bypass for streaming data that will not be reused; and
- wear-aware placement and migration.

Row-buffer locality is a useful signal. Random, low-locality hot data benefits
from DRAM because it would repeatedly pay NVM activation and write costs;
streaming data can bypass DRAM to preserve cache capacity. Placement can also
consider memory-level parallelism (MLP): a request on a lightly loaded bank
may tolerate more latency than one on a serialized critical path.

One formulation uses a utility score

$ "Utility"_i = Delta "StallTime"_i times "Sensitivity"_i $

for candidate page or line $i$. The first term estimates how much moving $i$
changes system stall time; the second captures how sensitive the workload is
to that change. UH-MEM uses this kind of MLP-aware utility to place pages
rather than ranking them only by access count.

UH-MEM periodically estimates each page's stall-time benefit and migration
cost, then promotes only pages with positive system utility. Across the
evaluated memory-intensity groups, its gain over the best prior hybrid manager grows from
roughly 3% to 5%, 9%, and 14% as the workload becomes more memory intensive;
the precise value changes with the slow-memory latency. This is why access
frequency alone is insufficient: an often-read page whose misses overlap may
be less valuable than a less frequent page on the critical path.

Large DRAM caches create a tag-storage problem. TIMBER stores cache tags in
memory and keeps a small SRAM directory, while adapting the cache granularity
to reduce tag traffic. Banshee uses TLB and page-table metadata, lazily
coheres translations, and chooses replacements with bandwidth as well as
locality in mind. These schemes illustrate that a hybrid cache needs metadata,
migration bandwidth, and crash policy in addition to a replacement algorithm.
In the reported comparison, TIMBER's tags-in-memory organization remained
about 6% slower than an ideal SRAM-tag design but improved performance per watt
by about 18%; dynamic region granularity recovers spatial locality without
paying one SRAM tag for every fine-grained line.

=== NVM Crossbars and In-Memory Compute

Memristor, ReRAM, and PCM devices can be arranged as a crossbar. Applying input
voltages to rows and measuring column currents computes an analog
vector-matrix product by Ohm's and Kirchhoff's laws:

$ I_i = sum_j G_(i,j) V_j . $

A practical tile contains DACs or pulse encoders on the input side,
sample-and-hold circuits, ADCs on the output side, and digital accumulation and
calibration logic. The array performs the multiply-accumulate where the data
resides, reducing movement for neural-network or linear-algebra kernels.

Crossbars are not ideal arithmetic units. Device conductance variation,
write noise, drift, limited ADC precision, sneak paths, and limited endurance
require calibration, redundancy, quantization-aware training, or periodic
refresh. Mapping and tiling also determine whether peripheral ADC energy
dominates the array energy. The broad PIM programming model and workload
examples are covered in the architecture notes; here the key memory-system
contract is that an analog read can be a computation and therefore consumes
the same sensing and endurance budget as a data read.

Representative systems map this primitive to different domains. *ISAAC* and
*PRIME* execute neural-network matrix operations in ReRAM crossbars;
*GenPIP* tightly integrates genome basecalling and read mapping in memory; and
*Swordfish* evaluates neural basecalling when memristor conductance is
non-ideal. Their common architectural problem is not the dot product itself,
but quantization, ADC/DAC cost, endurance, calibration, tiling, and the data
movement between analog arrays and digital control.

== Persistent Memory and Crash Consistency

=== A Load/Store Persistent Address Space

Conventional systems place volatile DRAM above a file system and a block
storage device below it. A store must pass through a buffer cache, file-system
metadata, and an I/O stack before it is durable. Persistent memory (PMem)
places nonvolatile media on the memory bus and exposes a byte-addressable
load/store region. Loads and stores are fast, but the processor, caches, memory
controller, and PMem can complete at different times.

A Persistent Memory Manager (PMM) allocates, locates, migrates, and protects
objects in this region. Applications can provide hints about locality,
persistence, sharing, and security. A single-level store uses persistent
addresses for both active and dormant data, avoiding repeated serialization and
deserialization. Reported examples showed about 24x performance and 16x
energy improvement over a disk-like path, and about 5x performance/energy
improvement over a DRAM-plus-SSD design; these are workload-specific
comparisons, not device guarantees.

=== Why Ordinary Stores Are Not Enough

Suppose a linked list inserts node `N` between `A` and `B`:

1. persist `N.next = B`;
2. persist `A.next = N`.

If a crash occurs after step 1, recovery still follows `A.next = B` and loses
`N`; if `A.next` becomes durable first, recovery can follow a pointer to an
uninitialized node. A correct update needs an ordering and an atomicity
boundary. Cache eviction order is not a persistence order.

The design spectrum has two endpoints:

- programmer-transparent hardware checkpoints hide ordering but need logs,
  metadata, and recovery bandwidth;
- programmer-managed persistence exposes flush, fence, transaction, or
  failure-atomic APIs but requires data-structure rewrites and careful use.

NV-Heaps, BPFS, and Mnemosyne represent explicit interfaces in this spectrum.
They differ in allocation, logging, and atomic-update granularity, but all make
the durability boundary visible to software. A practical protocol usually
combines cache-line writeback, a persistence fence, and a redo/undo record or
copy-on-write pointer swap.

*Loose-Ordering Consistency* relaxes persistence order between independent
updates while preserving programmer-declared dependencies and commit points;
it seeks more overlap without exposing an unrecoverable state. *NVMove* helps
port block/file-oriented software to byte-addressable persistence by making
allocation, update, and durability operations explicit in a library. These
interfaces reduce accidental ordering assumptions, but software still has to
state which writes form one failure-atomic update.

Persistence also competes for a shared memory controller. *FIRM* separates or
prioritizes traffic so that long NVM writes and persistence barriers cannot
indefinitely delay ordinary DRAM reads, while still providing fair progress.
Thus crash consistency and scheduling interact: a fence that is logically
correct can have unbounded latency if the controller provides no service
guarantee.

=== Hardware Checkpoints and Recovery

ThyNVM takes a more hardware-centric approach. It periodically checkpoints
dirty data at multiple granularities while execution continues, then restores
a consistent checkpoint after power loss. Checkpoint scheduling overlaps useful
execution and avoids flushing every cache line synchronously. The reported
implementation stayed within about 4.9% of an ideal-DRAM execution time in its
target workloads.

Checkpoint granularity is a tradeoff. A line-level checkpoint minimizes lost
work but costs metadata and write traffic; a page- or region-level checkpoint
amortizes metadata but writes more data after a failure. The controller must
also order data and metadata, preserve ECC/parity consistency, and bound the
recovery scan.

=== Security and Lifetime

Persistence changes the threat model:

- *Wearout attacks* issue writes to a small set of addresses and consume NVM
  endurance; quotas, wear leveling, and write-rate monitoring are needed.
- *Performance attacks* force migration between DRAM and NVM or exhaust the
  persistence log, increasing latency for other tenants.
- *Data remanence* leaves secrets after a process exits; secure erase,
  encryption, and key destruction are required because power cycling does not
  clear the cells.
- *Crash attacks* interrupt execution at carefully chosen points to expose
  partially ordered updates; recovery must validate checksums, epochs, and
  pointer metadata before publishing an object.

The cross-layer lesson is that nonvolatility removes refresh, not
responsibility. Placement, endurance, ECC, ordering, and access control must
all be part of the memory-system design.

#series-navbar("en", nav)
