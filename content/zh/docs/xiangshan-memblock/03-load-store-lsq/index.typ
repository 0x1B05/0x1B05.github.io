#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/03-load-store-lsq/", title: "Load、Store、Std 与 LSQ")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/03-load-store-lsq/")

= Load、Store、Std 和 LSQ：一条访存指令是怎么被拆开的

#series-navbar("zh", nav)

MemBlock 里最清楚的结构之一，就是“访存指令”不会被当成一个整体黑盒来处理。load、store address 和 store data 很早就被拆成不同职责，然后再通过 LSQ 和外围控制结构重新协调起来。

== 那个 `loadUnits(i)` 循环非常值得反复看

给每个 `loadUnits(i)` 接线的那段循环，几乎把访存子系统最关键的依赖都摆在了一处：

- 后端 issue 和 feedback
- DCache 访问
- LSQ 的 forward 与 replay
- uncache 和 MSHR 相关 forward
- DTLB 与 PMP
- misaligned load buffer
- 写回侧的延迟错误信息

这会让你很快意识到：load unit 并不是一个单独执行器，而是很多共享服务的消费者，也是很多控制结果的生产者。

== 为什么 store address 和 store data 要分开

乱序核里，store 的地址准备好和数据准备好，本来就不保证在同一时刻发生。所以香山把 store 路分成两条：

- `StoreUnit` 负责 store-address 这一侧，例如地址相关工作和进入 SQ 前的准备
- store-data 执行单元负责真正要写出的数据一侧

这也是为什么后端接口要分别提供 `issueSta` 和 `issueStd`。这不是编码风格问题，而是微架构里本来就存在的拆分。

== LSQ 不是“只是一个队列”

LSQ 在这里更像顺序和协调中心：

- load 会向它查询 forward
- store 地址和数据都会汇入它
- replay 从它回给 load side
- rollback / nuke 会通过它参与协调
- uncache 请求也从这片区域发起

所以 LSQ 不能只被理解为“memory ops 排队的地方”。它实际承担的是顺序、依赖、replay 与可见性协调。

#tufted.margin-note[
  #image("imgs/LSQ.svg")
  香山设计文档里的 LSQ 框图比较适合当成侧边参考图，因为队列、replay 结构和 committed-store buffering 还能保持在同一张图里看清。
]

== 这一层我会重点 review 什么

到这章开始，我会真的把一些问题记成检查项：

- 各条 load lane 的角色在特殊路径借用后还保持一致吗？
- store-address 和 store-data 两半在 LSQ 里能保证按预期重新汇合吗？
- 多个 replay 或 rollback 原因同时出现时，会不会选错真正应该生效的那个？
- 那些看起来对称的路径，实际上有没有隐藏的 lane-specific 例外？

MemBlock 越往下读，我越不愿意默认“这几路应该是对称的”。这个警惕就是从这里开始建立的。

#series-navbar("zh", nav)
