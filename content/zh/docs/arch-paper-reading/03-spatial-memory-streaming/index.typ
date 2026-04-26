#import "../../index.typ": (
  definition, doc-toc, example, series-context, series-navbar, template, tip,
  tufted, warning,
)
#import "../series.typ": arch-paper-reading-series
#show: template.with(
  locale: "zh",
  route: "docs/arch-paper-reading/03-spatial-memory-streaming/",
  title: "Spatial Memory Streaming",
)

#let series = arch-paper-reading-series
#let nav = series-context(
  series,
  "docs/arch-paper-reading/03-spatial-memory-streaming/",
)
#let paper = "/assets/papers/arch-paper-reading/spatial-memory-streaming.pdf"

= Spatial Memory Streaming

#series-navbar("zh", nav)

#doc-toc("zh")

原论文：#link(paper)[Spatial Memory Streaming (PDF)]

这篇 paper 的切入点很明确：很多 commercial workload 的 miss 不是简单的 next-line，也不是干净的 stride。程序每次进到某段代码，可能会在一个较大的地址区域里访问一组 block；这些 block 不连续，访问顺序也未必稳定，但“这一组 block 会一起出现”这件事本身是稳定的。

`Spatial Memory Streaming` 把这个现象叫做 region-level spatial correlation。它不直接预测“下一个地址”，而是预测“这一轮 region 里会访问哪些 block”。预测结果是一张 bitmask，硬件再把 bitmask 展开成一串 prefetch 请求。

#tip(title: "这篇 paper 的主线")[
  `SMS` 的关键不是把 prefetch 做得更激进，而是把预测对象换了：从单个地址换成一个 region 内的访问形状。
]

== 问题背景：stride 看不出来的相关性

先把两个词分开看。

`spatial locality` 通常指访问了某个 block 之后，附近 block 也更可能被访问。例如 `B0, B1, B2, B3`。这种模式很适合 next-line、stream 或 stride prefetcher。

`spatial correlation` 更宽一点。它不要求 block 连续，也不要求相邻访问之间有固定步长。只要同一个 region 内某些 block 经常在同一种代码上下文下一起出现，它们之间就有可利用的 correlation。

#example(title: "不是 stride，但仍然可预测")[
  在一个 region 里，程序经常访问 `B0, B3, B9, B12`。如果看地址序列，`+3, +6, +3` 不像一个稳定 stride；但如果看一轮 region 最后点亮了哪些 block，它就是一张相当稳定的 bitmask。
]

这就是 SMS 和普通 stream prefetcher 的分界。stream prefetcher 试图从地址序列里推出下一项；SMS 则先换一个观察窗口，把地址序列压成 region 内的集合。

== 核心抽象：region generation 和 pattern

SMS 不是一看到访问就马上训练长期历史。它先定义一轮 `spatial region generation`，再把这一轮内访问过的 block 汇总成 pattern。

#definition(title: "SMS 的基本对象")[
  - `spatial region`: 固定大小的连续地址区间，论文推荐配置里是 `2KB`。
  - `trigger access`: 一轮 region generation 的第一次访问。
  - `spatial region generation`: 从 trigger access 开始，到这一轮里任意已访问 block 被 eviction 或 invalidation 为止。
  - `spatial pattern`: generation 内访问过的 block offset 组成的 bit vector。
]

这个定义看起来比“访问了什么就记什么”麻烦，但它解决的是训练样本边界问题。窗口太短，完整 pattern 会被切碎；窗口太长，不相关的几轮访问会被揉在一起。eviction / invalidation 是一个比较自然的结束点：只要这些 block 还能共同驻留，这轮 generation 就还活着；一旦其中某个成员被换走，这轮“共同出现”的窗口就该结算了。

=== 一个 2KB region 的例子

假设 region 大小是 `2KB`，cache block 是 `64B`，那一个 region 里有 `32` 个 block。某次访问先碰到这个 region 的第 `4` 个 block，它就是 trigger。后续在同一轮 generation 中，程序又访问了第 `7`、`12`、`13` 个 block。

这一轮最后写出的训练样本不是完整地址序列，而是：
- trigger `PC`
- trigger offset = `4`
- pattern bits = `4, 7, 12, 13`

注意这里真正稳定的是“这条代码从 region 内 offset `4` 开始时，常常会点亮这几个位置”。至于这次 region base 是 `R`，下次是不是换成另一个对象地址，反而不是最重要的。

== 训练结构：AGT 怎样收集干净样本

`AGT` 是 `Active Generation Table`，负责跟踪还活着的 generation。它没有一上来就给每个 generation 分配完整 bit vector，而是拆成 `filter table` 和 `accumulation table` 两级。

#figure(
  image("imgs/sms-structures.svg"),
  caption: [`AGT` 的设计可以按“先过滤，再累积”来看：`filter entry` 只记录 region 身份和 trigger 信息；只有当这一轮访问到第二个不同 block 时，entry 才升级到 `accumulation table` 并开始维护 pattern bits。],
)

=== filter table：先判断是不是单点访问

一轮 generation 第一次出现时，系统只知道三件事：
- 这是哪个 region
- 是哪条静态指令触发的
- trigger 在 region 内是什么 offset

这时候还不能说它有 spatial pattern。很多 generation 可能只访问 trigger 一个 block 就结束了。如果这类访问也分配完整 bit vector，硬件状态会被大量没有训练价值的单点访问占掉。

所以 filter entry 只保存身份信息。如果直到 generation 结束都没有第二个不同 block，它就直接丢弃，不写入长期历史。

=== accumulation table：第二个不同 block 之后才认真记录

当同一轮 generation 出现第二个不同 block，SMS 才把它看成值得记录的 pattern 候选。entry 会从 filter table 转到 accumulation table，后续每访问一个新的 block offset，就把对应 bit 置 1。

这一步是 SMS 很重要的噪声控制：它不是把所有访问都写进历史，而是等一轮 generation 表现出“多个 block 成组出现”之后，才开始付出 bitmask 的成本。

#warning(title: "AGT 的容量取舍")[
  filter table 太小，会过早丢掉刚开始的 generation；accumulation table 太小，会让已经长出 pattern 的 generation 被提前挤掉。论文推荐的 `32-entry filter + 64-entry accumulation` 不是为了堆很大的表，而是为了让多数 generation 能活到自然结束。
]

=== 训练结束：成熟 pattern 写入 PHT

训练流程可以按 generation 生命周期走：

1. 某个 region 第一次被访问，形成 trigger。
2. `AGT` 未命中，于是在 filter table 分配 entry。
3. entry 记录 region tag、trigger `PC`、trigger offset。
4. 如果这一轮直到结束都没有第二个不同 block，entry 被丢弃。
5. 如果来了第二个不同 block，entry 升级到 accumulation table。
6. 后续访问同一 generation 内的 block 时，对应 pattern bit 被置 1。
7. 当这一轮里任意已访问 block 被 eviction / invalidation，generation 结束。
8. 如果 entry 已经在 accumulation table，就把最终 pattern 用 `PC + offset` 作为 key 写入 `PHT`。

#figure(
  image("imgs/sms-update-flow.svg"),
  caption: [`SMS` 的更新流要和 generation 生命周期一起读：先用 `filter` 排除短命单点访问，跨过“第二个不同 block”门槛后进入 `accumulation`，最后只有成熟 pattern 才提交到 `PHT`。],
)

== 预测结构：PHT 如何回放 pattern

训练结束后，成熟 pattern 会进入 `PHT`，也就是 `Pattern History Table`。未来再遇到类似 trigger 时，SMS 从 PHT 取出历史 bitmask，再用当前 region base 把它展开成具体地址。

=== 为什么 PHT 用 PC + offset

`PHT` 的 key 不是完整地址，而是：
- trigger access 的静态 `PC`
- trigger 在 region 内的 offset

这一步是 SMS 能预测新 region 的关键。很多 commercial workload 一直在处理不同对象、记录、节点。绝对地址经常变化，但访问它们的代码路径和对象内部布局比较稳定。如果用完整地址做 key，很多地址可能只出现一次；如果用 `PC + offset`，同一段代码处理新对象时仍然可以复用以前学到的 pattern。

#tip(title: "为什么 SMS 能碰 cold miss")[
  `PHT` 复用的是代码上下文里的 region 形状，不是旧地址本身。只要同一段代码在新 region 上重复类似 pattern，SMS 就有机会在第一次访问这个 region 时预取后面的 block。
]

=== prediction register 把 bitmask 变成请求

PHT 命中后输出的是一张 bitmask，不是一条地址。硬件还需要把它变成一串实际 prefetch。`prediction register` 通常保存两样东西：
- 当前 region base
- 还没发完的 pattern bits

然后它扫描 bitmask，把每个置位 bit 展开成：

```text
region_base + block_offset * block_size
```

每发出一个 prefetch，对应 bit 就可以清掉。所有 bit 清空，这轮预测才结束。

#figure(
  image("imgs/sms-topology.svg"),
  caption: [`SMS` 的主路径可以分成训练和回放两半：`AGT` 在 live generation 里长出 pattern，`PHT` 保存成熟 pattern；未来 trigger 再出现时，`prediction register` 把 `region base + bitmask` 展开成一串实际 prefetch。],
)

=== 一次预测怎么走

未来某次访问又触发一个 generation 时：

1. 根据访问地址算出 region base 和 trigger offset。
2. 用 `PC + offset` 查 `PHT`。
3. 如果没有命中，这轮先正常执行，同时 AGT 会开始训练。
4. 如果命中，取出历史 pattern bitmask。
5. 把 `region base + pattern bits` 写入 prediction register。
6. prediction register 扫描 bitmask，逐个发出 prefetch。
7. 已经在 cache 里的 block、资源暂时发不出去的 block，可以跳过或延后。

#example(title: "同一张 pattern，换一个 region base 回放")[
  训练时学到的 pattern 是 `{4, 7, 12, 13}`。下次 trigger 命中 `PHT`，但新的 region base 变成 `R'`。prediction register 发出的不是旧地址，而是 `R' + 4 * 64B`、`R' + 7 * 64B`、`R' + 12 * 64B`、`R' + 13 * 64B`。
]

== 设计取舍：为什么这样才有用

SMS 的结构看起来绕，是因为它同时在处理三件事：训练样本不能太脏，历史 key 要能跨地址复用，预取请求不能粗暴地把整个 region 都搬回来。

=== 为什么不是大 cache line

如果 region 里常有一组 block 一起出现，一个直接的想法是把 cache line 做大，或者用 sectored cache。paper 的判断是：这不等价。

SMS 要的是更大的访问模式表达，而不是更大的数据搬运粒度。大 cache line 会把 region 里没用的 block 也带回来，带宽浪费、false sharing、cache pollution 都会变严重。sectored cache 能缓解一部分带宽问题，但它仍然把训练窗口绑在 cache 组织上，容易把 interleaved generation 切碎。

AGT 的意义正在这里：cache 仍然以 `64B` block 为基本单位搬数据，SMS 只在旁边观察哪些 block 经常在同一轮 generation 里一起出现。

=== 参数背后的取舍

论文推荐配置里比较重要的参数是：
- `2KB` spatial region
- `32-entry filter table`
- `64-entry accumulation table`
- `16K-entry, 16-way PHT`

region 太小，稀疏 correlation 会被切碎；region 太大，bit vector 变长，PHT/AGT 成本上升，pattern 也更容易混入无关 block。`2KB` 表达的是一个折中：很多有价值的 spatial correlation 明显大于 cache line，但还没大到需要无限扩大 region。

AGT 太小会让 live generation 被提前替换，最后写入 PHT 的 pattern 不是完整形状，而是容量截断后的残片。PHT 太小则会丢掉长期 pattern，尤其是多个代码路径、多个 trigger offset 都在竞争历史项时。

=== 边界和失败模式

SMS 的实验重点不是证明“多发 prefetch 总会更快”，而是证明 commercial workload 里确实存在 region-level spatial correlation：它比 next-line/stride 更复杂，但又足够稳定，可以用硬件历史表学出来。

它适合的场景大概有几个特征：
- 同一段代码会反复处理结构相似的数据对象。
- 访问在一个 region 内比较稀疏，直接放大 cache line 会浪费。
- region pattern 相对稳定，`PC + offset` 能成为有效 key。
- 系统还有足够 prefetch 带宽和 MSHR 去消化 bitmask 展开的请求。

#warning(title: "SMS 的失败模式")[
  如果同一个 `PC + offset` 在不同上下文下对应完全不同的 pattern，`PHT` 会学到混杂 bitmask；如果 generation 交错太多、AGT 容量不够，pattern 会在训练时被截断；如果预测出来的 block 很多但很少真正使用，收益会被带宽和 cache pollution 吃掉。
]

所以 SMS 的价值不是“更激进”，而是换了一个更合适的预测单位。它用 region generation 收集训练样本，用 `PC + offset` 做跨地址复用，再用 bitmask 表达稀疏 block 集合。只要程序里真的存在这种稳定的 region 形状，它就能预测传统 stride/next-line 很难预测的 miss。

#series-navbar("zh", nav)
