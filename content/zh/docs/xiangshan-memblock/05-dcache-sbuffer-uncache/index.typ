#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/05-dcache-sbuffer-uncache/", title: "DCache、SBuffer 与 Uncache")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/05-dcache-sbuffer-uncache/")

= DCache、SBuffer 和 Uncache/MMIO：cacheable 与 uncacheable 路径怎么分家

#series-navbar("zh", nav)

#doc-toc("zh")

MemBlock 会越长越大，一个重要原因是“memory traffic”根本不是一种东西。cacheable load、已经准备好往下推的 store、uncache/MMIO 请求，遵循的是不同的推进规则。代码必须让它们相关，又不能混在一起。

== DCache 是执行侧的共享资源

load unit 会连到 DCache 的请求口、forward 路径和一些与 refill 相关的状态。所以 DCache 在这里不是被动终点：load 除了往下发请求，还会收 fast-forward、ready 和时序相关的返回信息。

== 为什么 SBuffer 没有被并进 LSQ

LSQ 和 SBuffer 的职责其实不一样：

- LSQ 更关心顺序、依赖、replay 和指令生命周期协调
- SBuffer 更关心那些已经可以继续向 cache 或 memory 推进的 store 数据

所以这条路更像：

`StoreUnit / store-data 路 -> LSQ -> SBuffer -> DCache 或更低层 memory`

把 SBuffer 保持独立，有助于把“store 的顺序状态”和“store 的写出缓冲”分开。

#figure(
  image("imgs/sbuffer.svg"),
  caption: [香山设计文档里的 SBuffer 总图：committed-store buffering 和 LSQ 的顺序职责是分开的两件事],
)

== 为什么 uncache/MMIO 要单独有控制路径

uncache 不是边角功能。它的 outstanding 规则、返回方式和风险形态都和普通 cacheable access 不一样，所以旁边配了专门的控制路径，甚至小状态机。

这里 lane ownership 又一次成了关键。标量 uncache 返回固定绑在某条 load lane 上，说明返回路径依赖一个写死的设计决定——并不存在一张天生对称的网。

== 这里我会怎么 review

这章我盯的是 ready/valid 和路径隔离：

- cacheable 和 uncacheable 路径之间，有没有不应该共享的隐含假设？
- 返回流量是否总能回到正确的 lane？
- 一个 outstanding uncache 请求会不会无意间阻塞或污染无关的 cacheable 流？
- LSQ 到 SBuffer 的 handoff，是否还保持了后端预期的顺序语义？

很多访存问题不出在 cacheable happy path 上，而出在某条路径开始“不像别的路径”之后的边界处。

#series-navbar("zh", nav)
