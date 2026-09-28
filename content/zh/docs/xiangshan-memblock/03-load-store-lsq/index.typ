#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/03-load-store-lsq/", title: "Load、Store、Std 与 LSQ")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/03-load-store-lsq/")

= Load、Store、Std 和 LSQ：一条访存指令是怎么被拆开的

#series-navbar("zh", nav)

#doc-toc("zh")

MemBlock 里有一条结构很清晰：访存指令不会被当成一个整体来处理。load、store address 和 store data 很早就拆成三条职责不同的路径，再由 LSQ 和外围控制结构重新协调起来。

== `loadUnits(i)` 接线循环是重点

给每个 `loadUnits(i)` 接线的那段循环，把访存子系统的大部分关键依赖都摆在了一处：

- 后端 issue 和 feedback
- DCache 访问
- LSQ 的 forward 与 replay
- uncache 和 MSHR 相关 forward
- DTLB 与 PMP
- misaligned load buffer
- 写回侧的延迟错误信息

看完这个循环就清楚了：load unit 不是独立执行器，它消费一堆共享服务，也生产一堆控制结果。

== 为什么 store address 和 store data 要分开

乱序核里，store 的地址和数据不保证同时准备好。所以香山把 store 拆成两条路：

- `StoreUnit` 负责 store-address 这一侧，例如地址相关工作和进入 SQ 前的准备
- store-data 执行单元负责真正要写出的数据一侧

后端接口分开提供 `issueSta` 和 `issueStd`，对应的就是这个拆分，和代码风格无关。

== LSQ 管的不只是排队

LSQ 在这里更像顺序和协调中心：

- load 会向它查询 forward
- store 地址和数据都会汇入它
- replay 从它回给 load side
- rollback / nuke 会通过它参与协调
- uncache 请求也从这片区域发起

所以别把 LSQ 只当成 memory ops 排队的地方，它承担的是顺序、依赖、replay 和可见性协调。

#tufted.margin-note[
  #image("imgs/LSQ.svg")
  香山设计文档里的 LSQ 框图。队列、replay 结构和 committed-store buffering 在同一张图里，适合当侧边参考。
]

== 这一层要记下的检查项

- 各条 load lane 的角色在特殊路径借用后还保持一致吗？
- store-address 和 store-data 两半在 LSQ 里能保证按预期重新汇合吗？
- 多个 replay 或 rollback 原因同时出现时，会不会选错真正应该生效的那个？
- 那些看起来对称的路径，实际上有没有隐藏的 lane-specific 例外？

MemBlock 越往下读，越不能默认“这几路应该是对称的”。这个警惕就是从 LSQ 这一层开始有的。

#series-navbar("zh", nav)
