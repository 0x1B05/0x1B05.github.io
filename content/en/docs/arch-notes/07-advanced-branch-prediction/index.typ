#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, tufted, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/07-advanced-branch-prediction/",
  title: "Advanced Branch Prediction",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/07-advanced-branch-prediction/")

= Advanced Branch Prediction

#series-navbar("en", nav)

#doc-toc("en")

== Dynamic Branch Prediction

Dynamic prediction uses history collected at run time.

Advantages:
- Prediction is based on branch execution history.
- It can adapt to dynamic changes in branch behavior.
- Static profiling and the profile-input representativeness problem are not needed.

Disadvantage: additional prediction hardware makes the design more complex.

== Last-Time Predictor

Idea: predict that a branch will take the same direction as its last instance. A single bit per branch, stored in the BTB, records the previous direction.

- A loop with `K` iterations is mispredicted on the first and last iteration, giving accuracy `(K - 2) / K`.
- Large loops are predicted well.
- Short loops with alternating outcomes can be predicted very poorly.

The one-bit branch history table (BHT) entry is updated with the correct outcome after each execution. The BTB stores a tag and target address; the BHT bit selects the target or `PC + instruction size`.

== Two-Bit Counter Prediction

A last-time predictor changes from taken to not-taken, or vice versa, too quickly. Add hysteresis with a two-bit counter: two states predict taken and two states predict not-taken. A strong prediction does not change after one different outcome.

The counter uses saturating arithmetic: it has maximum and minimum values and does not wrap around.

#three-line-table(
  columns: (1.35fr, 1.25fr, 2.3fr),
  inset: 5pt,
  align: left,
)[
  | *Counter state* | *Prediction* | *Update intuition* |
  | :-------------- | :----------- | :---------------- |
  | `11` | strongly taken | move toward `10` on not-taken |
  | `10` | weakly taken | move toward `11`/`01` |
  | `01` | weakly not-taken | move toward `00`/`10` |
  | `00` | strongly not-taken | move toward `01` on taken |
]

For a loop with `K` iterations, the two-bit predictor can achieve `(K - 1) / K` accuracy. Many programs achieve roughly 80--90% accuracy with bimodal prediction.

== The Branch Penalty Still Matters

For `N = 20`, `W = 5`, one branch per five instructions, and 500 instructions:

#three-line-table(
  columns: (1.1fr, 1.7fr, 1.7fr, 1.5fr),
  inset: 5pt,
  align: left,
)[
  | *Accuracy* | *Cycles* | *Extra work* | *IPC* |
  | :--------- | :------- | :----------- | :--- |
  | 100% | 100 | none | 500/100 |
  | 90% | 300 | 200% | 500/300 |
  | 85% | 400 | 300% | 500/400 |
  | 80% | 500 | 400% | 500/500 |
]

== Two-Level Prediction

Last-time and two-bit predictors exploit only last-time predictability. Two further observations motivate two-level predictors:
- A branch outcome can correlate with outcomes of other branches (*global correlation*).
- A branch outcome can correlate with earlier outcomes of the same branch beyond the immediately previous outcome (*local correlation*).

=== Global Branch Correlation

Recently executed branch outcomes in the execution path can predict the next branch. For example, if two earlier branches are both taken, a later branch may be taken; if either is not-taken, the later branch may also be not-taken.

Capture this with a *global history register (GHR)* containing the T/NT history of recent branches and a *pattern history table (PHT)* of two-bit counters indexed by the GHR. This is a two-level global predictor.

First level: an N-bit GHR records the direction of the last N branches. Second level: the PHT records the direction observed the last time each history was seen.

The GHR shifts in the latest outcome after each branch. The Intel Pentium Pro used a two-level global predictor with a four-bit GHR and multiple PHTs selected by low bits of the branch address.

=== Gshare

Gshare hashes the GHR with the branch PC, commonly using XOR, before indexing the counter array.

Advantages:
- More context information is used.
- The two-bit counter array is utilized more effectively.

Disadvantage: the extra hashing can increase access latency.

=== Local Branch Correlation

To predict a loop branch, each local history can identify a different iteration. A *local history predictor* has two levels:
- A set of per-branch history registers, selected using the branch PC.
- A PHT of saturating counters indexed by the local history.

The predictor taxonomy is described by the scope of the branch history register (global, per-set, or per-branch) and the scope of the PHT (global, per-set, or per-branch).

== Hybrid / Tournament Prediction

Branch predictability is heterogeneous:
- Some branches are best predicted with local history.
- Some are best predicted with global history.
- Some need only a two-bit or one-bit predictor.

No single algorithm is best for every branch. A hybrid predictor uses more than one predictor, such as a two-bit counter and a global predictor, and a selector (meta-predictor) chooses which prediction to trust.

Advantages:
- Better accuracy because different predictors are better for different branches.
- Reduced warmup time: the faster-warming predictor can be used while the other predictor is still training.

Disadvantages:
- A meta-predictor or selector is needed.
- Access latency, hardware, and design complexity increase.

The Alpha 21264 tournament predictor had a minimum branch penalty of 7 cycles and a typical penalty of 11 or more cycles. It stored 48K bits of target addresses in the instruction cache, and predictor tables were reset on a context switch.

Many hybrid predictors achieve 90--95% average accuracy, although difficult workloads can still suffer large losses.

=== Branch Filtering

Many branches are heavily biased toward one direction, for example 99% taken. Such branches can pollute prediction tables and global history registers, causing interference that hurts other branches. Detect biased branches and predict them with a simpler mechanism, such as a last-time or static predictor, so that they do not consume entries in the more sophisticated tables.

Even with tournament prediction, difficult workloads can remain far from ideal. In the slide example for `gcc`, the maximum IPC with tournament prediction is 9, while perfect prediction would allow IPC 35.

== Further Predictors

=== Loop Branch Predictor

A loop detector predicts the iteration count and the loop-closing branch. It works well for loops with a small number of iterations and was used in Intel Pentium M.

=== Perceptron Predictor

A perceptron is a simplified biological-neuron model and a binary classifier. It maps an input vector to a prediction:

`output = weight dot history + bias > 0`

In branch prediction, the input vector is the branch history register and the output is the predicted direction. The predictor learns correlations between individual history bits using weights.

Each branch is associated with a perceptron. Express the GHR bits as `1` (taken) and `-1` (not-taken), take the dot product of these bits and the perceptron's weights, add a bias, and predict taken when the output is positive. A positive correlation receives a positive weight; a negative correlation receives a negative weight.

Advantages:
- A more sophisticated learning mechanism can improve accuracy.
- Long branch histories can be supported.

Disadvantages:
- The dot product needs an adder tree and is complex.
- Only linearly separable correlations can be learned; XOR-like correlations cannot.

=== TAGE / Geometric History Length

Different branches need different history lengths. A TAGE predictor uses multiple PHTs indexed with histories of different lengths and allocates entries intelligently.

Advantages:
- Chooses a suitable history length for each branch.
- Enables long histories and high accuracy.

Disadvantages:
- Nontrivial hardware and hash-function design.
- Table sizes and latency must be carefully balanced.

Modern processors can combine a perceptron predictor at one level with TAGE at another level.

== Prediction in the Fetch Path

A direction predictor by itself is not enough to keep fetch moving. In the cycle that fetches a branch, the front end needs enough information to choose the next fetch address immediately:

#three-line-table(
  columns: (1.35fr, 2fr, 2.3fr),
  inset: 5pt,
  align: left,
)[
  | *Question* | *Typical structure* | *Result* |
  | :--------- | :------------------ | :------- |
  | Is this instruction a branch? | BTB tag/type or predecode bits in the I-cache | Distinguish ordinary instructions from control flow |
  | Is a conditional branch taken? | Bimodal, local, global, tournament, or TAGE direction predictor | Select target or fall-through |
  | What is the target? | BTB, return-address stack, or indirect-target predictor | Supply a concrete next PC |
]

The *branch target buffer (BTB)* is a tagged cache indexed by the fetch PC. A hit says that the corresponding instruction was previously observed as a control-flow instruction. Its entry normally contains the branch type and a target; it may also select direction-predictor state. A BTB miss on a previously unseen taken branch creates a fetch bubble until decode or execute computes the target.

A realistic next-PC selection path chooses among several candidates:

- Sequential PC, usually `PC + instruction length`.
- Direct target from the BTB.
- Return target from the return-address stack.
- Target from an indirect-branch predictor.
- A corrected target sent by the backend after resolution.

This path is latency critical. Larger predictors improve accuracy but add table access, hashing, tag checking, and selection delay. Front ends therefore frequently pipeline prediction or use a small, fast first prediction that can be overridden by a slower, more accurate predictor.

=== Speculative History and Predictor Update

The predictor must distinguish *prediction time* from *training time*:

1. At fetch, it reads predictor state, chooses a direction and target, and checkpoints enough history to recover later.
2. Because subsequent predictions depend on recent history, it normally shifts the predicted outcome into the speculative GHR immediately.
3. When the branch resolves, the processor compares predicted and actual direction/target.
4. On a correct prediction, it trains the relevant counters and commits the history state.
5. On a misprediction, it restores the checkpointed history, inserts the actual outcome, redirects fetch, and squashes younger wrong-path instructions.

Updating only at retirement is simple but makes the predictor train late. Updating at execution is faster, but multiple unresolved branches and wrong-path updates require careful recovery. Predictor correctness never affects architectural correctness: a bad prediction changes performance and speculative work, while backend recovery preserves the ISA-visible result.

== Branch Confidence Estimation

A prediction can be accompanied by a confidence estimate: how likely is it to be correct? One simple estimator stores a saturating counter recording whether recent predictions for the same branch were correct. More elaborate estimators use predictor agreement, counter strength, history matches, or a separate table.

Confidence is different from predicted direction. A branch can be predicted taken with low confidence or not-taken with high confidence.

Possible uses include:

- *Pipeline gating*: stop or reduce wrong-path fetch when confidence is low, saving energy at the cost of possible lost performance.
- *Selective multipath execution*: fetch both paths only for low-confidence branches.
- *Resource allocation*: keep low-confidence branches from filling a large speculative window with likely wrong-path work.
- *Hybrid selection*: use confidence to decide whether an expensive predictor or helper mechanism should override a simple predictor.

A confidence estimator must itself be accurate. Overconfidence wastes energy and window capacity on wrong paths; underconfidence sacrifices useful speculation.

== Delayed Branching

Delayed branching changes ISA semantics: the branch takes effect only after a fixed number of following instructions. Instructions in these *delay slots* execute regardless of branch direction. The compiler fills a slot with a useful instruction taken from before the branch, the target path, or the fall-through path; otherwise it inserts a NOP.

Advantages:

- A short pipeline can remain busy without dynamic prediction hardware.
- The compiler makes the control-hazard schedule explicit.

Disadvantages:

- Useful independent instructions may not exist, especially with multiple delay slots.
- Code motion from one branch path can require compensation or squashing semantics.
- The number of slots exposes pipeline depth in the ISA, harming compatibility when implementations change.
- Deeper and wider machines cannot efficiently encode their full branch latency as fixed delay slots.

Delay slots were practical in early RISC pipelines but do not scale well to modern deeply pipelined out-of-order processors.

== Predicated Execution

Predication converts a control dependence into a data dependence. Each instruction carries or consumes a predicate; when the predicate is false, the instruction has no architectural effect. A conditional move is a limited example:

`R1 = condition ? R2 : R1`

Full predication can turn both sides of a short branch into straight-line code. Intel Itanium associated instructions with predicate registers, while earlier ARM ISAs allowed many instructions to carry condition codes.

#three-line-table(
  columns: (1.2fr, 2.35fr, 2.35fr),
  inset: 5pt,
  align: left,
)[
  | *Property* | *Branch prediction* | *Predication* |
  | :--------- | :------------------ | :------------ |
  | Work executed | One predicted path | Operations from both paths may be fetched/executed |
  | Hard branch | Can pay a large flush penalty | Removes the misprediction |
  | Easy branch | Usually very efficient | May perform unnecessary work |
  | Adaptivity | Predictor adapts at runtime | Static if-conversion normally does not |
  | Compiler freedom | Basic blocks remain separated | Larger straight-line region enables scheduling |
]

Predication is attractive when the expected misprediction cost exceeds the cost of executing nullified instructions. It is unattractive for long paths, highly biased easy-to-predict branches, scarce execution bandwidth, or operations that cannot be safely/speculatively performed. A compiler or dynamic mechanism should therefore select branches rather than predicate everything.

== Multipath Execution

Multipath execution follows both successors of a conditional branch and later discards the incorrect path. It completely avoids direction-prediction latency if both target addresses are available, but duplicates fetch, rename, scheduling, register, and execution demand.

Unlike predication, dual-path execution preserves two separate control-flow paths and can stop one as soon as the branch resolves. Unlike ordinary prediction, it guarantees that the correct path is already in flight. The approach is most useful for infrequent, low-confidence branches when spare resources exist; executing both paths after every branch grows work exponentially and is impractical.

== Predicting Calls, Returns, and Indirect Branches

Conditional direction prediction is only one part of control-flow prediction. Other branch types need specialized target mechanisms.

=== Calls and Return-Address Stack

A direct call is always taken and usually has one PC-relative target, so a BTB predicts it easily. A return is harder: the same return instruction can go to every call site that invoked the function.

Calls and returns are normally nested. A *return-address stack (RAS)* exploits this property:

- When a call is fetched, push the address following the call.
- When a return is fetched, pop and predict the saved address.
- Checkpoint or repair the speculative stack across mispredictions and exceptions.

The slides report that an eight-entry RAS can exceed 95% return-prediction accuracy. Mismatches still occur with deep nesting, recursion beyond the stack capacity, nonlocal control transfers, context switches, and code that manipulates return addresses.

=== Indirect Target Prediction

Register-indirect branches are always taken but can have many targets. They implement switch tables, virtual calls, function pointers, and interface dispatch.

Storing only the last target in the BTB is simple but performs poorly when one branch alternates among several targets; the slides cite roughly 50% empirical accuracy. A history-based indirect predictor hashes the indirect-branch PC with global or path history, allowing different contexts to select different target entries.

The tradeoff is capacity: one dynamic indirect branch can occupy many target entries and conflict with direct branches. Tagged target caches, target-set predictors, and separate indirect structures reduce this interference.

== Aliasing and Predictor Interference

Finite predictor tables are shared. Two branches or histories that map to one PHT entry update the same counter. This *aliasing* can be:

- *Positive*: both branches push the entry toward useful predictions.
- *Neutral*: sharing has little effect.
- *Negative*: their preferred outcomes conflict and accuracy falls.

Dedicating a PHT to every branch removes interference but is far too expensive. Practical techniques trade capacity, indexing, and tags against conflict probability.

#three-line-table(
  columns: (1.2fr, 2.45fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Technique* | *Mechanism* | *Main tradeoff* |
  | :---------- | :---------- | :-------------- |
  | Larger PHT | Reduce capacity conflicts | More area, power, and access latency |
  | Branch filtering | Keep highly biased branches in a simple predictor | Requires bias classification |
  | Gshare | XOR PC and GHR before indexing | Better distribution, extra hash delay |
  | Agree predictor | Counter predicts agree/disagree with a per-branch bias bit | Needs a useful bias bit |
  | Gskew | Several differently hashed PHTs vote | Multiple tables and hashes |
  | Bi-mode | Separate mostly-taken and mostly-not-taken tables | Choice structure and duplicated capacity |
  | YAGS | Small tagged exception caches override a base bias | Tags and exception-management complexity |
]

The agree predictor reduces destructive sharing between oppositely biased branches. If branch 1 is 85% taken and branch 2 is 15% taken, a conventional shared direction counter sees opposite outcomes with probability

`0.85 * 0.85 + 0.15 * 0.15 = 0.745`.

With bias bits of taken and not-taken, both usually report *agree*; their agree/disagree outcomes conflict with probability

`0.85 * 0.15 + 0.15 * 0.85 = 0.255`.

Gskew instead indexes several PHTs with different hash functions and uses majority vote. Two branches are unlikely to collide destructively in every table at once, but prediction requires multiple accesses.

== Fast and Wide Fetch

A wide pipeline must deliver several useful instructions every cycle. Branch prediction can be accurate yet still fail to provide peak fetch bandwidth because of prediction latency, alignment, and taken branches inside a fetch block.

=== Line and Way Prediction

Complex next-PC prediction may take multiple cycles. A line-and-way predictor associates each I-cache line with the line and way likely to be fetched next. The Alpha 21264 used this fast mechanism to begin the next cache access, then corrected it using the full branch machinery. A wrong line/way prediction wastes about one cycle rather than the full backend branch penalty.

This illustrates a general front-end principle: use a fast approximate prediction to maintain frequency, then override it before too much work accumulates.

=== Alignment and Fetch Breaks

Two independent effects reduce effective fetch width:

1. *Alignment*: the current PC may be near the end of an I-cache line, leaving fewer than the fetch-width number of sequential instructions.
2. *Fetch break*: a predicted-taken branch inside the packet redirects the remaining slots to a noncontiguous target.

A split-line fetch reads the end of the current line and the beginning of the next line in one cycle, usually by banking the I-cache and adding alignment logic. It solves sequential boundary crossing but not an arbitrary taken target.

Multiple branches in one fetch packet require predicting multiple directions and targets and assembling instructions from multiple basic blocks. This makes wide fetch significantly harder than merely widening decode and execution.

=== Code Layout and Superblocks

Profile-guided basic-block reordering places the likely successor sequentially, converting a frequent taken transfer into fall-through. Besides reducing fetch breaks, a good layout can improve I-cache locality and page behavior. Its benefit depends on whether runtime behavior matches the profile.

A superblock combines a frequently executed trace into a single-entry, multiple-exit region. Tail duplication removes side entrances, enabling code motion and wide fetch across the resulting straight-line region. The costs are larger code, profiling dependence, and recompilation. The VLIW notes discuss superblock formation in more detail.

=== Trace Cache

A *trace* is a dynamic sequence of instructions identified by a starting address and branch outcomes. A trace cache stores instructions from several consecutively executed basic blocks in fetch order, allowing one access to cross taken branches and I-cache line boundaries.

A trace-cache entry typically contains:

- A tag derived from the starting PC and branch history.
- Decoded instructions or micro-operations from the dynamic path.
- The branch outcomes represented in the trace.
- A fall-through or next-trace address.

Advantages:

- Reduces fetch breaks for biased branches.
- Can store decoded operations and save repeated decode work.
- Supplies a wide backend with noncontiguous original instructions.

Disadvantages:

- Duplicates the same instruction in multiple traces and wastes capacity.
- Requires trace construction, fill, and multiple-branch prediction logic.
- Path tags and replacement are more complex than an ordinary I-cache.
- Unbiased control flow fragments traces and lowers hit rate.

Intel Pentium 4 used a 12K-micro-operation trace cache in place of a conventional L1 instruction cache. Modern designs often use micro-op caches, which retain the decode-saving benefit with different path organization.

== Branch-Handling Design Checklist

A complete control-flow design must answer all of the following:

- How are branch presence, type, direction, and target predicted early enough?
- How are direct branches, returns, and indirect targets handled differently?
- Which history is updated speculatively, and how is it recovered?
- When and where are direction counters, targets, and selectors trained?
- How much table aliasing is acceptable for the area and latency budget?
- Can the I-cache and alignment network deliver the predicted path at full width?
- How much wrong-path energy and resource occupancy is tolerable?
- Which hard branches should instead use predication, multipath execution, helper computation, or software layout?

Branch prediction is therefore not a single table. It is a coordinated next-PC subsystem whose accuracy, latency, bandwidth, and recovery behavior jointly determine front-end performance.

#series-navbar("en", nav)
