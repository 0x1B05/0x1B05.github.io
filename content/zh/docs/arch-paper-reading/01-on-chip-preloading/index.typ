#import "../../index.typ": series-context, series-navbar, template, tufted, doc-toc
#import "../series.typ": arch-paper-reading-series
#show: template.with(
  locale: "zh",
  route: "docs/arch-paper-reading/01-on-chip-preloading/",
  title: "On-Chip Preloading",
)

#let series = arch-paper-reading-series
#let nav = series-context(
  series,
  "docs/arch-paper-reading/01-on-chip-preloading/",
)
#let paper = "/assets/papers/arch-paper-reading/on-chip-preloading.pdf"

= On-Chip Preloading

#series-navbar("zh", nav)

#doc-toc("zh")

原论文：#link(paper)[An Effective On-Chip Preloading Scheme to Reduce Data Access Penalty (PDF)]

这篇 paper 有点老了，主要关心的问题是 L1 data cache 带来的 CPI 代价。

片上 cache 很小，而且大概率是 direct-mapped。单纯的 demand fetching 处理不了 compulsory miss，也很难把数据及时准备好。所以这篇paper要解决的问题是：*能不能在真正的 load 指令执行前，就把它很快会用到的数据块提前装到 data cache 里，从而减少 data access penalty？*

== Data Cache Preloading

=== Motivation

作者把支持的data reference 分成几类：
- scalar: 简单变量访问
- zero stride: 在某个 loop level 上，访问的是同一个位置
- constant stride: 每次按固定步长推进，步长不一定小

对以上规则的 load/store 地址模式做 aggressive preloading, 而对于irregular的访问, 比如链表、间接寻址、不可预测下标这类访问尽量避免预取.

作者这里还特意强调了大stride, 普通 cache 和常见 prefetch 对小 stride 还行，但对大 stride 帮助十分有限。比如 block 很小，stride 却是 400B，这时候访问了一个块，下一次真正用的是很远的另一个块，传统相邻块 prefetch 根本抓不到。这篇paper希望不管 stride 大小如何，只要模式稳定，就能提前preload。

==== 矩阵乘法

矩阵乘法内层循环一下把几种 pattern 都展示出来了。例如类似：
- `B[i,k]`: 可能是 constant stride
- `C[k,j]`: 也可能是 constant stride，但 stride 比较大
- `A[i,j]`: 可能是 zero stride，因为在某个 loop level 里不断复用同一个位置

=== 硬件结构

这篇论文的硬件结构其实就四个关键词：
- BPT(Branch Prediction Table): 因为 look-ahead PC 要沿着未来控制流跑，所以必须依赖分支预测。
- LA-PC(Look-Ahead Program Counter): 这是一个跑在真实 PC 前面的辅助 PC，用来提前看到未来会执行哪些 load/store。
- RPT(Reference Prediction Table): 记录每条 load/store 指令以前访问过的地址、stride 和状态，用来预测这条指令下一次会访问哪里。
- ORL(Outstanding Request List): 记录已经发出去但还没回来的 preload 请求，防止重复发同一个块。

所以整个系统像这样工作：真实 `PC` 负责真的执行程序。`LA-PC` 在前面“试跑”。一旦 `LA-PC` 遇到 load/store，就查 RPT 看这条指令下次大概率访问哪个地址。如果对应块不在 cache，且没在 ORL 里，就发一个 preload 请求。

==== decoupled architecture

作者自己也说，这个设计和 decoupled architecture 有点像，因为本质上都是：“把数据访问的准备动作放到真正计算之前。”但它比 decoupled architecture 简单很多，因为：
+ 不需要完整拆成两条执行流
+ 不需要编译器特别配合
+ 也不需要解码整个预测出来的未来指令流

这是他们强调“硬件支持简单、成本更低”的地方。

=== RPT

`RPT` 是 `Reference Prediction Table`。它按“哪条 load/store 指令”建表。RPT 的每个 entry 都对应一条 load/store 指令, 每个 RPT entry 里有 4 个字段：
- `PC tag`: 对应这条 `load/store` 指令本身的地址
- `prev-addr`: 上一次这条指令真正访问到的操作数地址
- `stride`: 最近学到的步长
- `state`: 一个 4 状态的小状态机，决定现在该不该继续 preload：
  - `initial`：刚建立 entry，或者刚从稳定状态掉下来。现在还没有足够把握。
  - `transient`：系统刚刚观察到一个可能的 stride，但还不完全相信。
  - `steady`：模式稳定，可以放心继续预测。
  - `no prediction`：这条指令目前看起来不规则，先别 preload 了。

==== `RPT` 怎么学地址模式

*只有真实程序执行到那条 load/store，并且真正算出了有效地址，`RPT` 才更新。*

1. 第一次看到某条 load/store：
  - 分配表项
  - 记下 `prev-addr = addr`
  - `stride = 0`
  - 状态进 `initial`
2. 第二次看到同一条指令：
  - 新的 `stride = addr - old_prev_addr`
  - `prev-addr = addr`
  - 状态转到 `transient`
3. 如果下一次地址正好等于 `prev-addr + stride`：
  - 说明 stride 连续成立
  - 状态进入或保持 `steady`
4. 如果在 `steady` 状态下失配：
  - 说明原来的稳定模式崩了
  - 更新 `prev-addr`
  - 先退回 `initial`
5. 如果在 `transient` 状态下又失配：
  - 说明上次看到的 stride 很可能只是偶然
  - 用新的地址差重写 `stride`
  - 进入 `no prediction`

LA-PC 只消费RPT, 遇到 load 时，这里分成两种情况。
1. LA-PC 遇到某条 load 指令，但 RPT 里没有 entry，或者 entry 在 no prediction那就什么也不做。
2. LA-PC 遇到的 load 在 RPT 里有 entry，而且当前允许预测, 那就生成预测地址：`predicted address = prev-addr + stride`

然后检查：
- 这个 block 是不是已经在 cache 里
- 这个请求是不是已经在 ORL 里挂着了
如果都不是，就发起一次 preload，并把这个请求地址登记进 ORL。

==== 用一条规则 load 走一遍会更清楚

假设同一条 load 的实际地址依次是：
- `1000`
- `1064`
- `1128`
- `1192`

那 `RPT` 大致会这样变化：
1. 第一次看到 `1000`
  - `prev-addr = 1000`
  - `state = initial`
2. 第二次看到 `1064`
  - 学到 `stride = 64`
  - `prev-addr = 1064`
  - `state = transient`
3. 第三次看到 `1128`
  - 正好满足 `1064 + 64`
  - `prev-addr = 1128`
  - `state = steady`
4. 第四次看到 `1192`
  - 继续满足 `1128 + 64`
  - `steady` 维持

到这一步以后，`LA-PC` 才会比较放心地在未来提前用这条 load 做 preload。

如果后来突然来了一个 `1400`：
- 这就说明原来的规则断了
- 这条 load 会从 `steady` 退回去

所以 `steady` 不是一个“学会了就永远不掉”的状态，而是随时会因为真实执行流打脸而撤销。

#figure(
  image("imgs/preloading-structures.svg"),
  caption: [`RPT` 这一套如果只记结构名很容易空掉。图里把 `PC tag / prev-addr / stride / state` 单独展开后，能直接看出：真正决定是否允许 `LA-PC` 动作的，不是有没有 stride，而是这个 stride 有没有稳定到进入 `steady`。],
)

=== LA-PC

传统硬件 prefetch，特别是 one-block-lookahead，访问了 `block i`，就会猜下一个可能访问 `block i+1`。这适合 instruction stream 或者 stride 很小、很规整的数据流。但对 data cache，尤其 scientific code 里 stride 可能很大，或者不同 load 指令各自有自己的访问规律时，这种思路就不够了。

这篇paper提出不从当前数据块往后猜，而是从未来即将执行的 load/store 指令往前看。所以这篇论文不是 “address-stream-centered”，而是更接近 “instruction-stream-centered” 的预取设计。

真实 `PC` 还在执行程序的同时, 用 `LA-PC` 沿着预测的控制流往前跑；当 `LA-PC` 碰到某条 load/store 指令时，查RPT，预测这条指令这次会访问哪个地址；如果这个块还不在 cache，就提前把它装进来。

==== LA-PC 怎么动

LA-PC 和真实 PC 一样，也是按预测的指令流前进：
1. 平常按顺序加一，像普通 PC 一样往后走
2. 如果碰到 branch，就查 BPT，预测分支走向
3. 按预测结果跳到目标 basic block
4. 继续往前走

如果 LA-PC 走到一条未来会执行的 load/store 指令，比如某个 `lw`，它会去查 `RPT`：
- 这条指令以前访问过哪些地址？
- 有没有稳定 stride？
- 现在是不是处于允许预测的状态？

如果 RPT 说：“这条指令下一次大概率会访问 `prev_addr + stride`”, 那系统就会看看这个块：
- 在不在 cache
- 在不在 ORL 里已经请求过
如果都没有，就发一个 preload 请求。

==== LA-PC 走到未来指令时，是不是在真的“取指 + 解码”？

`LA-PC` 并非把未来指令都执行一遍，仅仅是在未来控制流上做*轻量探路*。它只需要：
1. 知道当前“未来指令地址”是多少
2. 用这个地址去查：
  - `BPT`：这里是不是一条分支
    - 命中, 说明这里曾经是一条 branch，而且有预测信息
    - 没命中, 就按顺序加一继续走
  - `RPT`：这里是不是一条曾经执行过的 `load/store`
    - 命中，这个地址对应的是一条 load/store，而且以前见过它的地址模式。
    - 没命中，就当它不是一个可预测的 load/store，不做 preload。

这里隐含了一个重要前提：*固定长度指令*
这篇论文的目标机器是典型 RISC-like 结构，例子里也是固定 4-byte instruction。所以 LA-PC 平时可以很自然地：`LA-PC = LA-PC + 4` 继续往下走。如果是变长 ISA，事情会复杂很多，因为不解码就未必知道下一条指令边界。

此外这套机制天然*依赖历史已见过的代码行为*。如果一段代码是第一次执行，真实 `PC` 还没训练过 `RPT`/`BPT`，那 `LA-PC` 就没法从表里知道：
- 这里是不是 branch
- 这里是不是可预测的 load/store

==== 例子

```
  500: lw r4, 0(r2)
```

第一次程序真正执行到 `500` 时，真实 PC 会取指, 解码, 算出地址, 然后把 “指令地址 500 是一条 `load/store`，它最近访问了什么地址” 记进 `RPT`

以后 LA-PC 如果跑到地址 `500`，它根本不需要再把那条 `lw` 解码一遍。它只需要查 `RPT[500]`:
- 如果查到了，就说明 500 这个地址是条 memory instruction, 而且它有历史模式可用, 于是就可以基于该 entry 的 `prev-addr + stride` 生成 preload 地址。

#figure(
  image("imgs/preloading-topology.svg"),
  caption: [`On-Chip Preloading` 的主路径其实非常明确：分支预测先把 `LA-PC` 往前推，只有当它撞到一条已经训练过的访存 `PC`，才会去查 `RPT` 生成候选地址，再经过 `ORL / cache` 过滤后决定要不要发 preload。],
)

==== Look-Ahead Distance：LA-PC 到底应该领先多远

理想情况当然是：`LA-PC` 领先 `PC` 的距离，刚好等于下一层 memory hierarchy 的访问延迟 `b`, 这样 preload 发出去后，正好赶在真实 load 需要前把数据送到 cache。

但现实里这个距离不可能永远精确控制，因为分支预测会错, memory latency 会波动, miss 会聚集, PC 和 LA-PC 可能跨很多 basic block...

所以论文定义了一个参数 `LA-limit = d`, 它表示 `LA-PC` 最多允许领先 `PC` 多远。如果领先距离达到 `d`，或者 `ORL` 已经满了，`LA-PC` 就必须停住。

如果 `d` 太小，preload 发得太晚。于是当真实 PC 执行到那条 load 时，数据虽然已经在路上，但还没到 cache，程序还是要等。论文把这种等待叫 `hit-wait cycles`。
如果 d 太大，LA-PC 可能跨过太多控制流边界。这样会带来几个问题：
+ 分支预测更容易错
+ preload 可能发到错误路径上
+ 数据可能来得太早，把当前还有用的块挤掉
+ 在带宽紧张时，还可能占住资源，拖慢真正的 demand miss

所以 `d` 的设置在这里也是一个非常典型的 architecture tradeoff：
- 小 d：预测保守，但可能来不及
- 大 d：预测激进，但错误代价更高

论文实验里看到，对于较受限的 memory model，`d` 设在一个中等区间通常比较好，大致像 $6 <= d <= 26$ 这样的范围会比较合理。如果内存系统已经很流水、很宽松，就没那么需要把 `d` 拉得很大。

=== miss时怎么处理

==== 读miss

如果真实 PC 发生 read miss，cache controller 会先查 ORL。
- 如果这个块已经被某次 preload 请求过了, 那就等待这个已经在路上的块到达。这个等待比完整 miss 短，论文叫它 hit-wait
- 如果 ORL 里没有, 那就发一个正常 demand load，而且它优先级高于那些排队中的 preload(buffered preload requests)

一个典型的仲裁策略：

```
  if (有 demand miss 待发送)
      先发 demand miss
  else if (有 preload 待发送)
      发 preload
```

可以想象 cache/memory 控制器前面有两个来源 Demand queue && Preload queue, 仲裁器每一拍或者每次通道空闲时，先看 Demand queue。通道可用时:
1. 如果 Demand queue 非空，选 demand
2. 否则，如果 Preoad queue 非空，选 preload

==== 写miss

论文采用的是 *write-allocate, copy-back*。也就是说，写 miss 时先把 block 取回来，再更新目标字。如果 block size 大于一个字，还可以像读 miss 一样触发后续 preload 逻辑。

同时还要考虑和 write buffer 的一致性问题：preload 和真正 miss 都要检查 write buffer，避免读到过期值或和未写回的数据打架。

==== 错误分支预测

如果 LA-PC 是因为错误分支走到某条路径上，发出去的 preload 请求可能就都没意义。所以论文说，若因为 branch prediction 错误需要重置 LA-PC，还在本地缓冲中的 preload 请求会被 flush。

一个 preload 请求可能处在三种不同阶段：
+ 阶段 A：刚被产生，还在本地 buffer / queue 里排队
  - 对应的 ORL 项也应该一起删掉或标 invalid
+ 阶段 B：已经发出，在下一级 cache / bus / memory system 里飞行
  - 更合理的是保留 ORL 项，直到请求返回
+ 阶段 C：数据已经回到本地

如果已经发出的 preload 以后回来了，怎么处理?

但从体系结构上有几种自然做法：
+ 让它正常填入 cache
  - 简单, 但可能造成 cache pollution, 这也是 branch misprediction 的代价之一
+ 给这类请求打“discard / ignore”标记
  - 数据回来时不装入 cache，直接丢掉, 论文在别的场景里其实已经用了类似想法：例如 write miss 与 preload 冲突时，会给 ORL 项加 discard status，表示回来后忽略, 所以同样的机制理论上也可以用于 branch flush 后的无效 preload

==== 异常

如果 preload 触发了异常，比如 page fault，选择直接忽略。为了一个 speculative preload 去认真处理 page fault，代价太高，不值得。

#figure(
  image("imgs/preloading-update-flow.svg"),
  caption: [`On-Chip Preloading` 的训练流和发射流是分开的。上面那条是真实执行流退休后更新 `RPT`，下面那条才是 `LA-PC` 读取稳定历史、尝试发出 speculative preload。理解这张图时一定要把“训练”和“消费”分开。],
)

== 实验

作者用的是 trace-driven simulation。程序跑在一台 DECStation 5000 (R3000 MIPS) 上，采集 data references 和 reference 间隔，再做模拟。

作者这里实验比较了三种架构：
1. Pure Data Cache: 就是*纯 cache*，没有预装机制。这是 baseline。
2. add-cost: 原来大小为 N KB 的 data cache 保留不变，另外再加上 256-entry RPT + 256-entry BPT。这代表*愿意多花芯片面积*的设计。
3. no-cost: 把 N KB cache 砍成 N/2 KB，然后把省出来的面积拿来放 RPT/BPT。这代表*总面积不变*的设计。

还设计了三种memory model
1. non-overlapped: 最保守的模型。一次 miss 基本会把后续推进卡死，等这次访存回来再说。这样的系统里，即使你会预取，能发挥的空间也有限。
  ```
  A: [issue][----latency----][transfer]
  B:                                   [issue][----latency----][transfer]
  ```
2. overlapped: 有一定重叠能力。一次 miss 期间，处理器还能做别的独立工作，所以 preload 如果能把数据提早放进 cache，就有机会把真正会卡住的那部分时间压短。
  ```
  A: [issue][----latency----][transfer]
  B:        [issue][----latency----][transfer]
  ```
3. pipelined: 更进一步，多个内存请求可以形成流水，系统能同时容纳更多在途请求。这个模型下 preload 的潜力最大，但同时 wrong-path 或过度 preload 的副作用也会更明显。
  ```
  A: [issue][----latency----][transfer]
  B:        [issue][----latency----][transfer]
  C:               [issue][----latency----][transfer]
  D:                      [issue][----latency----][transfer]
  ```

作者用的核心指标是 `CPI_data_access`，也就是 data access penalty 对 CPI 的贡献。它报告的主要是 *preloading 把原本 data cache miss 带来的 penalty 降掉了多少。*

=== `lockup-free cache` 和 `decoupled architecture`

`lockup-free cache` 更常见的现代叫法是 `non-blocking cache`。cache 遇到一次 miss，不会把整个 cache 都锁死, 后续命中仍然能继续服务, 甚至后续新的 miss 也可能继续进入系统，只要有足够的 miss tracking 结构

`decoupled architecture` 在这里可以理解成访存和执行不必死绑在同一步里。处理器前端、执行、访存之间有一定解耦，允许某些请求先飞出去，后面的计算继续推进。

它的基本思想是access/execute decoupling。
- Access 侧负责：算地址, 提前发 load/store, 把数据放进队列
- Execute 侧负责：从队列里取已经准备好的操作数, 做 ALU / FP 运算

=== 这三种 model 和 paper 结果的关系

如果再说白一点：

- `non-overlapped` 下，处理器自己没什么隐藏延迟的能力，所以 preload 的收益容易被系统级阻塞吃掉
- `overlapped` 下，处理器已经能在 miss 期间做一些别的事，preload 开始真正有“把关键 miss 变短”的空间
- `pipelined` 下，多个内存请求能更充分并行，preload 的 timeliness 价值最大，但乱发 preload 的坏处也会更明显

所以这些 model 其实是在帮作者回答一个更本质的问题：

#strong[“如果系统本来就几乎不能重叠延迟，那提前看到未来 load 有多大意义？”]

答案是：系统越允许重叠，这种 look-ahead 式预取越有价值。

#series-navbar("zh", nav)
