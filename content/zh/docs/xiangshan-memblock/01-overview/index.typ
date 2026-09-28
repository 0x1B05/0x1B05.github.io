#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/01-overview/", title: "MemBlock 到底是什么")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/01-overview/")

= MemBlock 到底是什么：先建立访存总图

#series-navbar("zh", nav)

#doc-toc("zh")

我第一次读 MemBlock 时，把它当成了一个特别大的 LSU 顶层文件，这个看法没什么用。文件确实大，但它实际是核内访存子系统的协调器：后端 issue 进来的访存 uop、load/store 执行单元、地址翻译、权限检查、DCache、uncache 路径、向量访存和 rollback 决策，都在这里汇合。

== 不要先扎进连线墙，先看参数块

`HasMemBlockParameters` 比实现主体更适合做入口：它先列出 MemBlock 自己管哪些单元：

- 三个标量 `LoadUnit`
- 两个 `StoreUnit`，负责 store-address 这一侧
- 两个 store-data 执行单元
- 向量 load / store 相关单元
- `AtomicWBPort`、`MisalignWBPort`、`UncacheWBPort` 这些明确命名的特殊写回口

注意最后一项。代码已经明说了：三条 load pipeline 不是三份对称的复制品。

== 三条 load lane 是带角色分工的

先把分工记住：

- `loadUnits(0)` 是 atomics 和 vector segment 会借用的特殊 lane
- `loadUnits(1)` 会参与 misaligned load 的写回处理
- `loadUnits(2)` 负责标量 uncache 返回路径

后面读到写回覆盖、DTLB 复用、DCache 抢占时，别把它们当偶发特例——都是这个角色分工的后续展开。

== 为什么它更像“协调器”

MemBlock 本来就是中心化的。它站在这些结构之间：

- 后端 issue 侧
- DCache、uncache 和更低层 memory 侧
- DTLB、PTW、PMP 这类翻译与权限侧
- LSQ、forward、replay、rollback 这一类顺序与控制侧
- 会继续借用标量资源的向量访存侧

所以这个文件读起来不像一条流水线，更像一个有很多交通规则的交换枢纽。难查的问题往往不是某个单元“内部算错了”，而是几个单元在共享资源和控制信号上互相踩到了。

#figure(
  image("imgs/memblock.svg"),
  caption: [香山设计文档里的 MemBlock 总体框图。先拿它建子系统地图，再追每条 lane 的具体连线],
)

== 重读的话我会怎么进

按这个顺序：

- 先看参数计数和特殊写回口常量
- 再看它和后端之间的边界接口
- 然后完整跟一条 load lane、一条 store-address lane 和一条 store-data lane
- 最后再扩展到 DTLB/PTW/PMP、DCache、uncache 和向量访存

第一遍不求全懂，先把地图立住。后面的细节得有地方挂，不然读码会一直散。

#series-navbar("zh", nav)
