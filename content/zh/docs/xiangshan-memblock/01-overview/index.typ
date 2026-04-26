#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/01-overview/", title: "MemBlock 到底是什么")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/01-overview/")

= MemBlock 到底是什么：先建立访存总图

#series-navbar("zh", nav)

#doc-toc("zh")

第一次读 MemBlock 时，最容易犯的错误是把它想成一个特别大的 LSU 顶层文件。文件确实很大，但更有用的心智模型是：它是核内访存子系统的协调器。后端 issue 进来的访存 uop、load/store 执行单元、地址翻译、权限检查、DCache、uncache 路径、向量访存和 rollback 决策，都在这里相遇。

== 不要先扎进连线墙，先看参数块

`HasMemBlockParameters` 比实现主体更适合作为入口，因为它先告诉你 MemBlock 自己认为什么是“它管理的单元”：

- 三个标量 `LoadUnit`
- 两个 `StoreUnit`，负责 store-address 这一侧
- 两个 store-data 执行单元
- 向量 load / store 相关单元
- `AtomicWBPort`、`MisalignWBPort`、`UncacheWBPort` 这些明确命名的特殊写回口

最后这一点特别重要。代码其实已经先告诉你：三条 load pipeline 不是三份完全对称的复制品。

== 三条 load lane 是带角色分工的

尽早建立这个结论很有价值：

- `loadUnits(0)` 是 atomics 和 vector segment 会借用的特殊 lane
- `loadUnits(1)` 会参与 misaligned load 的写回处理
- `loadUnits(2)` 负责标量 uncache 返回路径

所以你后面读到写回覆盖、DTLB 复用、DCache 抢占时，不应该把它们看成偶发特例。它们是在这个角色分工上继续展开的结果。

== 为什么它更像“协调器”

MemBlock 会让人觉得中心化，是因为它本来就很中心化。它站在这些结构之间：

- 后端 issue 侧
- DCache、uncache 和更低层 memory 侧
- DTLB、PTW、PMP 这类翻译与权限侧
- LSQ、forward、replay、rollback 这一类顺序与控制侧
- 会继续借用标量资源的向量访存侧

这也是为什么这个文件读起来不像一条流水线，更像一个带有很多交通规则的交换枢纽。很多难查的问题不是某个单元“内部算错了”，而是多个单元在共享资源和控制信号时互相踩到了。

#figure(
  image("imgs/memblock.svg"),
  caption: [香山设计文档里的 MemBlock 总体框图很适合先拿来建立子系统地图，再去追每条 lane 的具体连线],
)

== 如果重新开始读，我会怎么进

如果让我从零重新读一遍，我会按这个顺序：

- 先看参数计数和特殊写回口常量
- 再看它和后端之间的边界接口
- 然后完整跟一条 load lane、一条 store-address lane 和一条 store-data lane
- 最后再扩展到 DTLB/PTW/PMP、DCache、uncache 和向量访存

第一次阅读的目标不是全懂，而是先把地图立住。后面的细节必须有地方可挂，读码才不会一直散掉。

#series-navbar("zh", nav)
