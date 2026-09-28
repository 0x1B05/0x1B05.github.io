#import "../../index.typ": (
  definition, doc-toc, example, series-context, series-navbar, template, tip,
  tufted, warning,
)
#import "../series.typ": arch-paper-reading-series
#show: template.with(
  locale: "zh",
  route: "docs/arch-paper-reading/05-store-sets/",
  title: "Store Sets",
)

#let series = arch-paper-reading-series
#let nav = series-context(series, "docs/arch-paper-reading/05-store-sets/")
#let paper = "https://doi.org/10.1109/ISCA.1998.694770"

= Memory Dependence Prediction Using Store Sets

#series-navbar("zh", nav)

#doc-toc("zh")

原论文：#link(paper)[Memory Dependence Prediction Using Store Sets (DOI)]

这篇是 memory dependence prediction 的经典论文，核心问题一句话：*load 要尽量早发，但不能越过真正相关的 store。* OoO 处理器里，寄存器依赖在 decode 时就能看出来，memory dependence 不行——load 和前面的 store 冲不冲突，要等两边地址都算出来才知道。于是 scheduler 两头为难：全等，制造大量 false dependencies；全放，load 越过 store 跑出 memory-order violation，然后 squash、refetch、重执行，代价很大。store sets 想在中间找平衡：少 violation，也少无谓等待。

== 问题背景：load 到底该不该等

论文用三条 baseline 把设计空间切开：
+ No speculation: load 必须等所有更老的 store 先 issue 完。没有 violation，但 false dependencies 一堆。
+ Naive speculation: 寄存器依赖 ready 就让 load 先跑，不管前面的 store。反过来，violation 一堆。
+ Perfect memory dependence predictor: 既不制造 false dependencies，也没有 violations。现实中做不到，但它标出了中间的改进空间有多大。

#tip(title: "预测目标")[
  `Store Sets` 不做完美的 memory dependence oracle，而是用很小的硬件状态记录历史上发生过 violation 的 load/store 关系。
]

== Store Set 抽象

一个 load 的 store set，就是它历史上曾经依赖过的所有 store 的集合。这些 load/store 按静态 `PC` 归成同一组。

注意 `store set` 只是个逻辑概念，硬件里并没有一个真的存 `[PC_A, PC_B, PC_C]` 成员列表的容器。实现上只是给相关指令分配同一个 `SSID`，以后看到这些 `PC`，就知道它们属于同一个 dependence cluster。

这个集合抽象可以覆盖几类关系：
+ 多个 load 依赖同一个 store: 一个值先被某 store 写入，然后后面多个 reader load 都读它
+ 一个 load 依赖多个 store 的问题
  - 不同控制路径上，最终同一个 load 可能读到不同 store 写过的位置
  - 结构体不同字段被分别写，但一个 load 把整个字一起读出
  - 同一地址被多次 store 覆盖，load 可能依赖其中若干动态实例

=== 理想模型：Infinite Store Sets

作者先看一个理想模型：store set 可以无限大，一个 store 可以出现在任意多个 load 的 store set 里。然后把每个动态 load 分成 4 类：
- Not Predicted: 这个 load 的 store set 还是空的，没学到东西
- Correct Predictions: 预测对了，安全执行，也没无谓等待
- False Dependencies: 不该等却等了
- Memory Order Violations: 冲错了

结果：大多数 benchmark 的 violation 基本消掉了，有些还剩一点 false dependencies，整体已经很接近 perfect predictor。说明 store set 这个抽象本身立得住。

理想模型里剩下的 False Dependencies 从哪来？store set 记的是“这条 load 曾经依赖过这些 store PC”，一旦某个 store PC 进了集合，之后所有同 PC 的动态实例都会让 load 去等——哪怕这次其实不用等。

论文还试过用 two-bit counters 区分 working store set，即最近用到的关系比长期历史更重要。在理想 infinite predictor 上，这个反馈能减掉一部分 false dependencies。

== 硬件结构：SSIT + LFST

#definition(title: "SSIT 与 LFST")[
  - *SSIT(Store Set ID Table)*: 用 load/store 的 PC 去索引, 查出这条指令*属于哪个 Store Set ID* (SSID)
  - *LFST(Last Fetched Store Table)*: 用 SSID 去索引, 记录这个 store set 里*最近一个被 fetched 但还没执行完的 store*
]

#figure(
  image("imgs/store-sets-structures.svg"),
  caption: [`Store Sets` 的硬件状态主要集中在两张表：`SSIT` 把静态 `PC` 映射到 `SSID`，`LFST` 给每个 `SSID` 记录当前最新的 in-flight store。],
)

预测流程是：
1. 一个 load 被 fetch
2. 通过 `PC` 查 `SSIT` 得到它的 `SSID`
3. 再查 `LFST[SSID]`
4. 如果这里记录了一个尚未完成的老 store，就让这个 load 依赖它
5. 否则 load 可以自由执行

=== SSIT: 长期的 PC -> SSID 映射

SSIT 是 violation 驱动、逐步训练出来的长期结构。一开始，所有 load/store 的 SSIT 项基本都无效。当处理器运行时发生了某次 memory-order violation，它才学到：“这条 load 和那条 store 应该属于同一个 store set。”于是它更新 SSIT，把这两个 PC 映射到同一个 SSID。

SSIT 按 load/store 的静态 `PC` 索引，返回一个 `SSID`。SSIT 不可或缺的表项有：
- `valid bit`: 这一项现在有没有有效 store-set 信息
- `SSID`: Store Set ID，也就是“这条指令属于哪个集合”

论文有些变体还加 `2-bit counter` 做反馈，但属于可选件。

举例来说，一条 load 查出来 `SSIT[PC=100] = valid, SSID=7`，一条 store 查出来 `SSIT[PC=100] = valid, SSID=7`。这条 load 和这条 store 就被认为属于同一个依赖集合（dependence cluster）。

按完整 `PC` 寻址开销太大，实际做法是取 `PC` 的一部分 bit（或哈希后的 bit）去 index 一张普通数组表，direct-mapped，没有 tag。

代价是会有 alias：不同的 load/store PC 可能撞到同一个表项。某条本来不需要 store set 的 load 用到别人的 SSID，平白无故背上一个 false dependence。不过 store set 本来就不要求精确到每条动态实例，用小硬件代价覆盖大多数有用关系就够了。

当然表越小 alias 越频繁。论文后面 sizing 的结果是：SSIT 4K entry 已经很好，1K 还能接受，再往下 aliasing 就明显恶化。

=== cyclic clearing：让旧关系退出

论文在实现部分又回到一个工程问题：SSIT 没有 tag，会 alias；而且某个阶段学到的 dependence 关系，到后面的程序阶段可能已经不重要了。永远不清的话，表会越来越脏。候选方案有两个：2-bit counter 和 cyclic clearing。

2-bit counter 自己也放在会 alias 的 SSIT 旁边。某条需要 dependence 的 load/store 对和另一条完全无关的 load/store 可能共用同一个 SSIT entry，于是后者可能错误地把前者的 counter 往下减。这样应该保留的 dependence 关系反而被过早忘掉，然后 violation 又回来了。

作者的判断：2-bit counter 在个别 benchmark 上有改善，但整体不稳，还加复杂度，不如 cyclic clearing 简单可靠。

所以最后用的是 cyclic clearing：定期把 SSIT 的 valid bit 清掉，让表重新训练。代价是清理后有一小段重新训练期，论文的结论是这个代价值。

另外，cyclic clearing 不需要瞬间把整张表清零。论文给了一个很简单的实现，用两个计数器：
- 一个计“多久该开始清”
- 一个在 SSIT 里扫表，把 entry 一项一项置 invalid

周期触发，然后用硬件 sweep 把 valid bits 逐步清掉。这样就不需要一个超宽扇出信号把 4K 个 entry 同时清零。

=== LFST: 当前 in-flight store frontier

LFST 是随着当前 in-flight store 动态变化的短期结构。只要有 store 被 fetch 进来，它就可能更新 LFST。store 发完、离开关键路径后，LFST 相应项又会被清掉或改写。`LFST` 按 `SSID` 索引。LFST 不可或缺的表项有：
- `valid bit`
- `inum`: 当前 in-flight 指令的一个硬件编号 / 指针, 例如可以是`store pointer / issue queue tag / ROB index` 指向这个 store set 中“最近一个被 fetch 且尚未完成”的 store

举例来说, `LFST[SSID=7] = valid, points_to = store S42`. 表项里记录的是：这个 store set 里，最近一个被 fetched 但还没执行完成的 store。这里的含义即 7 号 store set 里，当前最新那个会挡住后续 load 的 store，是 `S42`。

LFST 比 SSIT 小很多。SSIT 需要比较大，因为它覆盖的是很多 load/store PC。但 LFST 不用那么大，因为同时活跃的 store set 数量远小于潜在的指令 PC 数量。论文结果是 LFST 只要 128 entries 就基本够了.

论文最后推荐的配置是 4K-entry SSIT, 128-entry LFST.

== 运行时流程：预测和训练

运行时可以分成两条路径：正常 fetch 时用 `SSIT + LFST` 给 load/store 加依赖；发生 memory-order violation 时，再用 offending load/store 去更新 `SSIT`。

=== fetch 到一条 store

#figure(
  image("imgs/store-sets-store-flow.svg"),
  caption: [`fetch` 到一条 `store` 时，`Store Sets` 先查 `SSIT`；若已有 `SSID`，就读取该组当前 frontier，并把这条 `store` 作为新的 `LFST` frontier 发布出去。若还没有 `SSID`，这一拍不会更新 `LFST`，后续要等真实 `violation` 来学习。],
)

fetch 到一条 store，用 `PC(S1)` 查 `SSIT`：
- 没命中或无效：这条 store 目前不属于任何已知 store set，这次不参与组内管理
- 命中，得到 `SSID = k`：这条 store 属于第 k 组。再看 `LFST[k]`，如果里面已经有一个更老的 store `S_old`，scheduler 就让 `S1` 依赖 `S_old`，同一 store set 内的 store 就这样按顺序串起来。然后更新 `LFST[k] = S1`——第 k 组最新的 in-flight store 现在是 `S1`，之后的 load 只要等它就够。最新的 store issue 之后会去访问 LFST，如果 LFST 还指向它自己，就把该项清掉。

=== fetch 到一条 load

#figure(
  image("imgs/store-sets-load-flow.svg"),
  caption: [`fetch` 到一条 `load` 时，`Store Sets` 先查 `SSIT`；如果没有 `SSID`，或者对应 `LFST` 里没有有效 frontier，`load` 就直接走。只有同时命中 `SSID + LFST frontier`，它才会等待。],
)

fetch 到一条 load，用 `PC(L1)` 查 `SSIT`：
- 没命中或无效：没有已知 memory dependence 要预测，按正常 OoO 规则尽快执行
- 命中，得到 `SSID = k`：这条 load 属于第 k 组，再看 `LFST[k]`
  - `LFST[k]` 是空的：按正常 OoO 规则尽快执行
  - `LFST[k]` 指向某个 store `S_last`：scheduler 给 `L1` 建一个依赖，让 `L1` 等 `S_last`

=== violation 触发后的更新流程

`Store Sets` 是在 memory-order violation 里学出来的。处理器从每次 violation 里拿到 `load PC` 和 offending `store PC`，然后决定是新建、传播、保留还是 merge 一个 `SSID`。

#figure(
  image("imgs/store-sets-update-flow.svg"),
  caption: [一次真实 `violation` 会把 `Store Sets` 推进训练路径。它先看冲突 `load/store` 两边在 `SSIT` 中是否已有 `SSID`，再在 `allocate / propagate / keep / merge` 四种情况里选一条，最后把 offending `store` 发布成该组新的 `LFST frontier`，并对错误越过的年轻 `load` 做 recovery。],
)

==== 举例：一次 violation 后 SSIT 怎么变

假设程序刚开始跑，SSIT 还是空的，很多 load 会像 naive speculation 那样先跑。然后出现一次 violation：某条 load `L` 和某条更老的 store `S` 访问了同一内存位置，但 `L` 先执行了。这时就要把 `L` 和 `S` 的 PC 关联到同一个 `SSID`，具体分四种情况：

#example(title: "violation 后的四种更新情况")[
  + `L` 和 `S` 之前都没有 SSIT 项, 那就新分配一个 `SSID`，比如 `SSID=7`： `SSIT[PC(L)] = 7`, `SSIT[PC(S)] = 7`
  + `L` 已经有 `SSID=7`，`S` 还没有, 那就把 `S` 也放进 7：`SSIT[PC(S)] = 7`
  + S 已经有一个集合，L 没有, 那就把 L 放进去。
  + L 和 S 各自已经在不同集合里, 这时就要做 merge
]

这四种更新结束后，程序下一次再跑到类似代码时，就会走前面的 fetch 路径，用学到的 `SSID` 来建立依赖。

=== 动态合并 store sets

如果两条 load 最终都依赖同一个 store，而一开始被分到了不同 store set，中间就会来回摆动（oscillate）：
- load1 冲突，store 被放进 set1
- load2 之后又和同一个 store 冲突，store 被放进 set2
- load1 再次执行时又冲突
- ...

所以作者加了 store set merging 规则：violation 暴露出两个集合共享依赖关系时，就动态把两个 store set 合并。

== 局限：applu 里的上下文变化

applu 是这篇论文里的典型失败案例。它有个三重循环，同一条静态 load 有时依赖某些 store、有时不依赖，依赖模式还随循环展开方式和动态实例位置变化。按 PC 粒度建 store set，就会把不同 iteration 的关系折进同一个预测项。

#warning(title: "失败模式")[
  `Store Sets` 按静态 `PC` 学依赖。如果同一条 load 在不同 iteration 里的真实依赖关系变化很大，它会把这些上下文折到同一个 store set 里，最后表现成过多 false dependence。
]

Store set 只记“这条 load PC 跟这条 store PC 有关系”，记不住第几次迭代的 load 该等第几次迭代的 store。一旦某个 load/store PC 对冲突过，这个 load 以后经常都会去等“最近的那个该 store PC 实例”，哪怕大多数时候根本不用等。结果就是大量 loop parallelism 被错误串行化。

*循环展开*有时能改善。不同动态位置被拆成不同静态 `PC` 之后，原来“同一个 PC 在不同 iteration 里的不同关系”就变成了“不同 PC 之间更稳定的关系”，预测器能学到的粒度更细。

#series-navbar("zh", nav)
