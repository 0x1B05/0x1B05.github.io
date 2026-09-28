#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/06-vector-memory/", title: "MemBlock 中的向量访存")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/06-vector-memory/")

= 向量访存为什么更复杂：Split、Merge、Segment 和 FOF

#series-navbar("zh", nav)

#doc-toc("zh")

向量访存一上来就显得复杂，因为它同时在解决几件事：一条向量访存指令会扩成很多内部操作，这些操作仍然要保顺序、要反馈，底下还经常借用标量访存资源，最后又要把结果拼回向量语义。

== 先拆，再合

放弃“向量指令整体往下走”的预设，split 和 merge 就很好懂：

- splitter 先把一条向量访存指令拆成更细粒度的内部操作
- 这些内部操作再去借用底下的标量执行资源
- merge buffer 最后再把结果重新拼回向量可见的语义

这层结构做的事，就是把“向量语义”翻译到“底层标量化执行基底”上。

== segment 和 first-fault 又增加了特殊语义

这里还有两类特殊路径：

- segment 访存，不是普通 vector load/store 的简单放大版
- first-fault 行为，当成“再加一个 load”是处理不完的

所以向量访存不只更宽，语义本身就比标量 path 特殊，需要专门的控制支持。

== 但底下仍然是标量资源

要注意的一点：向量逻辑底下复用的还是标量端口。最典型的例子是 vector segment 路会抢占 load port 0 的 DCache 和 DTLB 资源。

也就是说，某条看起来普通的标量 lane 同时是多个子系统的共享入口。仲裁、时序和 owner 规则在这里都会变成风险点。

#figure(
  image("imgs/VSegmentUnit-FSM.svg"),
  caption: [VSegmentUnit 的状态机。segment 访存是一条独立的控制路径，不是 split / merge 的自然延伸],
)

== 这一段我会重点看什么

review 这一段时，我主要会盯这些问题：

- split 出去的内部操作，和 merge 回来的结果，是否还保持同一条指令的身份语义
- 标量资源被向量路径借用后，会不会饿死或污染标量流量
- segment 和 first-fault 路径是否真的接进了 rollback、exception 和 writeback 主逻辑
- 向量 feedback 到底是在正确的边界重组，还是只是“晚一点再说”

到了这里，MemBlock 已经不再像传统 LSU 了。它更像是两个部分重叠的访存世界之间的协调层。

#series-navbar("zh", nav)
