#import "../../index.typ": (
  definition, doc-toc, example, series-context, series-navbar, template, tip,
  tufted, warning,
)
#import "../series.typ": arch-paper-reading-series
#show: template.with(
  locale: "zh",
  route: "docs/arch-paper-reading/02-feedback-directed-prefetching/",
  title: "Feedback Directed Prefetching",
)

#let series = arch-paper-reading-series
#let nav = series-context(
  series,
  "docs/arch-paper-reading/02-feedback-directed-prefetching/",
)
#let paper = "/assets/papers/arch-paper-reading/feedback-directed-prefetching.pdf"

= Feedback Directed Prefetching

#series-navbar("zh", nav)

#doc-toc("zh")

原论文：#link(paper)[Feedback Directed Prefetching: Improving the Performance and Bandwidth-Efficiency of Hardware Prefetchers (PDF)]

传统的硬件预取器常被看成一个地址预测问题：如果程序正在访问 `A, A+1, A+2`，那就提前把 `A+3, A+4` 拿回来。预取是基于历史行为的 speculative memory request，因此带来性能收益的同时，也会引入两个副作用：

首先它会占用带宽。prefetch 会额外发 memory request；如果这些 request 太多，或者距离和粒度过大，就会增加 DRAM bank conflict、DRAM row/page conflict、memory bus contention 和 queueing delay。更直接的问题是 demand request 可能被挤慢。

第二点, 它会造成 cache pollution. prefetch 把数据带进 cache 以后，不一定真的会被用到。如果这些 prefetched blocks 挤掉了原本后面还会用到的 demand-fetched blocks，就会造成 cache pollution。更糟的是，cache pollution 不是孤立问题。被挤掉的数据将来又会 miss，新的 miss 又可能再触发更多 prefetch，于是形成一个正反馈：无用 prefetch 增加 miss，miss 又触发更多 prefetch。

这两个副作用会导致 prefetcher 在性能和带宽消耗上都可能变得不稳定。

作者观察到 prefetcher 没有一个固定 aggressiveness 能对所有程序都最好。作者把一个 stream-based prefetcher 的 aggressiveness 从 No prefetching、Very Conservative、Middle-of-the-Road 到 Very Aggressive 一路调上去，然后看 17 个 memory-intensive SPEC2000 benchmark 的表现。结果是：对很多 benchmark，aggressive prefetching 性能明显上升；但对 ammp、applu 这类 benchmark，aggressive prefetching 反而严重拖后腿。

`FDP` 这篇 paper 的位置就在这里。它没有重新设计地址预测器，而是拿一个 stream prefetcher 当被控对象。这类 prefetcher 的基本单位是一个访问流；FDP 在外面加一层反馈控制，分别观察方向是否可靠、数据是否回来太晚、是否污染 cache，再动态调 `distance`、`degree` 和预取 line 的插入位置。

== stream prefetcher

论文里用的底层预取器是 stream prefetcher。这类 prefetcher 的基本单位是一个访问流。它会给每条访问流分配一个 tracking entry，然后这个 entry 大致经历四种状态：
1. Invalid: 还没跟踪任何流。
2. Allocated: 某次 demand L2 miss 让 prefetcher 觉得这里可能开始了一条 stream。
3. Training: 继续观察接下来的 miss，看这是上升地址流还是下降地址流。
4. Monitor and Request: 一旦方向确定，就开始沿这个方向预取。

可以把它理解成一种方向跟踪器：看到连续几个 cache block 沿同一个方向移动，就认为这里存在一个 stream，然后沿着这个方向提前取后面的 block。

比如程序连续访问`100, 101, 102, 103`,预取器就可能判断这是一个向上的 stream，接着预取 `104, 105, ...`。如果访问序列是`200, 199, 198, 197` 那就是向下的 stream。

一个实际的 stream prefetcher 通常不会仅凭一次相邻访问就触发。它会先观察几次，确认方向稳定后再进入跟踪状态。FDP 在识别出稳定 stream 后，对预取的时机、强度与 cache 留存策略做动态调节：
+ 预取距离(prefetch distance): 预取应该提前多远发出去
+ 预取粒度(prefetch degree): 一次触发应该发多少个 block
+ 缓存策略(Insertion Policy):预取回来的 line 应该插在 LRU stack 的什么位置

这三个合起来，就是 paper 里说的 aggressiveness。distance 越大、degree 越大，预取器越激进。激进配置可以隐藏更长延迟，但错误预取的资源代价也会更高。

#tip(title: "demand vs. prefetch")[
  - `demand request` 是程序已经执行到某条 load/store，现在真的需要这个 block。
  - `prefetch request` 是硬件提前发出的 speculative request。猜对了可以隐藏延迟，猜错了不会改变程序语义，但会消耗带宽、MSHR 和 cache 空间。

  所以当 demand 和 prefetch 争资源时，demand 通常更重要。特别是在 non-blocking cache 里，多个 miss 可以同时在路上，MSHR 会记录这些未完成请求。MSHR 不是 non-blocking cache 本身，但它是支撑这种能力的关键账本：哪个 block 正在取、谁在等它、数据回来后要唤醒谁。

  预取请求也会占这些结构。一个过于激进的 prefetcher 不只是多发了几个无用请求，还可能挤占 demand request 前进所需的资源。
]

== 评价指标

很多预取器调参最自然的想法是看准确率：发出去的 prefetch 里，有多少后来真的被 demand 用到了？这个指标当然重要，但它不够。

假设一个预取器 accuracy 很高。如果 demand 来的时候，prefetch 还在 MSHR 里没回来，那这次预取虽然方向对，却没有隐藏住延迟。对程序来说，它还是等了。

另一种情况：accuracy 也不算差，但预取 line 插进 cache 之后，把本来有用的 demand line 挤掉了。后面程序又要用那条被挤掉的 line，于是多了一次 demand miss。这种预取在单条 line 上可能有用，但对整体 cache replacement 行为是负收益。

所以 `FDP` 把预取器的失败拆成三类，而不是混成一个分数：

- `accuracy`：发出去的 prefetch 里，有多少最终真的被 demand request 用到了。$"accuracy" = "useful prefetches" / "total prefetches sent to memory"$
  - prefetch line 填进 L2 时带一个 `pref-bit`。如果后面 demand 命中这条 line，就说明这次 prefetch 被用上了。硬件维护两个计数器：`pref-total` 记录总共发了多少 prefetch，`used-total` 记录其中多少后来被 demand 用到。
- `lateness`：猜对的东西有没有来得足够早, $"lateness" = "late useful prefetches" / "useful prefetches"$
  - 光看 cache line 不够，因为 late 的那一刻，数据可能还没进 cache。paper 的做法是把 `pref-bit` 也放进 L2 MSHR。这样 demand 请求到来时，如果发现自己要的 block 正在某个 prefetch MSHR entry 里等待返回，就把这次记为 late。
- `pollution`：预取是否造成额外 cache miss。
  - 最难精确追踪。理想情况下，硬件要知道“某条 demand line 是不是因为某次 prefetch 插入才被逐出”，这需要很重的因果记录。`FDP` 没这么做，而是用了一个小的 filter 近似记录。某条 demand line 被 prefetch 挤掉时，在 filter 里打一个标记；之后如果 demand miss 又碰到这个标记，就把它当作一次 pollution 事件。这个 filter 会有 aliasing，但控制器需要的是足够稳定的方向信号，而不是精确归因。

这三个信号对应的动作不一样。低 accuracy 通常说明该降低 aggressiveness；高 accuracy 但 late 很高，反而可能说明请求需要更早发出或一次多发几个；pollution 高则说明 cache 插入策略或 aggressiveness 已经带来明显副作用。

#figure(
  image("imgs/fdp-structures.svg"),
  caption: [`FDP` 加的不是一个新地址预测器，而是一套反馈账本：cache line 上的 `pref-bit` 负责记录 useful，MSHR 上的 `pref-bit` 负责记录 late，pollution filter 负责近似追踪被 prefetch 挤掉的 demand line。],
)

== FDP总体结构

FDP = 一个普通 prefetcher + 一个运行时反馈控制器

FDP 在每个采样区间结束时会做三件事：
1. 测量 prefetcher 的当前表现
2. 根据测量结果判断“现在太激进了，还是太保守了”
3. 调两个旋钮：
  - prefetch aggressiveness
  - prefetched block 在 cache 里的插入位置

论文的控制结构可以写成：
```
Prefetcher 运行一段时间
-> 收集反馈
-> 计算三个指标
-> 调 aggressiveness 和 cache insertion
-> 下一段时间继续运行
-> 再收集反馈 ...
```

这是一个闭环控制系统。

=== 采样窗按 eviction 切，而不是按指令数切

`FDP` 不是每个周期都调档。它按 interval 收集一段时间内的 useful、late、pollution 事件，然后在 interval 结束时统一更新策略。

这个 interval 的边界不是指令数，而是 `eviction-count`。当 L2 里发生的 eviction 数超过阈值 `Tinterval`，这一轮采样窗结束。实验里 `Tinterval` 取 `8192`。

这个选择和控制目标有关，因为 `FDP` 调的是 cache 和带宽压力。两个程序片段可能都执行了一百万条指令，但一个几乎不碰内存，另一个频繁替换 L2。按指令数切，前者会给控制器一堆低信息量样本；按 eviction 切，至少能保证每轮更新都看到了足够多的 cache 行为。

`8192` 这个量级也不是随便来的。它大约接近实验配置里半个 L2 的 cache block 数。太短的话，统计噪声太大；太长的话，程序 phase 都变了，控制器还抱着旧结论不放。这个阈值是在“样本够多”和“反应别太慢”之间取一个工程平衡。

=== 调档前先做平滑

interval 结束后，`FDP` 不会直接拿本轮统计量生硬决策。它会把本轮结果和历史结果做一次平滑，大致是：

```
new_metric = old_metric / 2 + interval_metric / 2
```

这一步看起来普通，但很重要。预取器控制最怕抖：这一轮晚了一点就猛加，下一轮污染高一点又猛降，最后系统自己制造噪声。平滑的作用就是让控制器记得一点历史，不被一个短窗口里的偶然事件牵着走。

平滑之后，控制器把 `accuracy` 分成高、中、低，把 `lateness` 分成 late / not-late，把 `pollution` 分成 polluting / not-polluting。组合起来就是 12 种情况。paper 用一张控制表决定下一步调不调 aggressiveness。

控制表背后的判断可以概括为：
- accuracy 低，说明方向本身不可靠，通常降低 aggressiveness
- accuracy 高但 late 高，说明方向对、只是太慢，通常提高 aggressiveness
- pollution 高，说明预取已经造成 replacement side effect，通常要降低 aggressiveness 或调冷插入位置
- 不 late、不 polluting，说明当前档位可以保持

第一条和第二条需要分开看。同样是性能不好，原因可能完全相反：一个是“不该取”，一个是“该取但取晚了”。只看 miss rate 或 accuracy 很容易把这两种情况混掉。

#figure(
  image("imgs/fdp-topology.svg"),
  caption: [`FDP` 的形状更像控制环：底层 stream prefetcher 继续负责发现地址流，cache hierarchy 把 useful、late、polluting 三类事件反馈给 controller，controller 再回头改 distance、degree 和 insertion policy。],
)

== 五个 aggressiveness 档位

paper 最后没有让 `distance` 和 `degree` 任意组合，而是收敛成五个档位：

- 档位 1：`distance = 4`, `degree = 1`
- 档位 2：`distance = 8`, `degree = 1`
- 档位 3：`distance = 16`, `degree = 2`
- 档位 4：`distance = 32`, `degree = 4`
- 档位 5：`distance = 64`, `degree = 4`

这几个档位体现了一个简单事实：越想提前隐藏长延迟，就越要把请求发得更早，有时还要一次多发几个。但 degree 也不能无上限增加，因为每多发一个 block，都可能占 MSHR、占带宽、占 cache 空间。

比如当前在档位 3，`distance = 16, degree = 2`。一轮统计下来发现 accuracy 很高、late 也很高、pollution 不明显，那它很可能应该往档位 4 走。因为方向没错，问题只是回来太晚。

反过来，如果 accuracy 低，还伴随明显 pollution，那就不是“再早一点”能解决的事。预取器方向不可靠，而且已经影响 cache replacement，这时应该降档。

== 插入位置也要调

`FDP` 另一个重要点是，它没有只调发请求的 aggressiveness。它还调 prefetched line 插入 cache 的位置。

普通 demand line 刚被程序访问过，放在比较热的位置很自然。但 prefetch line 只是预测出来的未来需求。它可能很快会被用到，也可能完全没用。如果一进 cache 就给它 `MRU` 待遇，等于让 speculative data 和 demand data 使用同一套最高生存优先级，这很容易造成 pollution。

所以 paper 用 pollution 程度调插入位置：

- pollution 低时，prefetch line 插到 `MID`
- pollution 中等时，插到更靠近 LRU 的位置，比如 `LRU-4`
- pollution 高时，直接插到 `LRU`

`MID` 可以理解成 LRU stack 的中间位置。它比 `MRU` 保守，但又不会像 `LRU` 那样一插进去就马上被赶走。这个策略背后的判断很实际：预取数据可以进 cache，但默认不该和刚被 demand 用过的数据拥有同样的生存优先级。

#figure(
  image("imgs/fdp-update-flow.svg"),
  caption: [`FDP` 的更新节奏是 interval-driven：窗口内累积 useful / late / pollution，`eviction-count` 触发收窗，随后平滑指标、查控制表、更新 aggressiveness，并按 pollution 调整预取 line 的插入位置。],
)

== 贡献：把预取控制拆成三个反馈信号

`FDP` 最后报告了性能提升和带宽效率提升，但更重要的是它把硬件预取器从单纯的地址预测器，扩展成一个带反馈的控制系统。

它的核心思想接近控制论。传统 aggressive prefetcher 如果遇到适合预取的程序，会明显减少 miss penalty；但如果程序不适合，它可能因为带宽竞争和 cache pollution 让性能变差。作者指出，prefetcher 可能形成正反馈：pollution 导致 demand miss，demand miss 又触发更多 prefetch，进一步加剧污染和带宽竞争。FDP 加的就是 negative feedback，也就是给已有 prefetcher 增加一个自适应控制层。

一个强 prefetcher 不只是会带来 hit，也会带来资源压力。它可能取晚，可能取错，也可能造成 cache pollution。这三种失败模式最后都可能表现为性能不好，但修法不一样。

`FDP` 的贡献就是把它们分开测、分开调：

- direction problem 看 accuracy
- timing problem 看 lateness
- cache side effect 看 pollution

这也是为什么它比“按准确率调强度”更稳。准确率只能告诉你方向对不对，不能告诉你来不来得及，也不能告诉你有没有造成 cache side effect。预取控制必须同时看这三件事。

#series-navbar("zh", nav)
