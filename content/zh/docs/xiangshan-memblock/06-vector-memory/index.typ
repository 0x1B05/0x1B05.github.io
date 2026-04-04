#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/06-vector-memory/", title: "MemBlock 中的向量访存")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/06-vector-memory/")

= 向量访存为什么更复杂：Split、Merge、Segment 和 FOF

#series-navbar("zh", nav)

向量访存这一段之所以一上来就显得很复杂，是因为它同时在解决几件事：一条向量访存指令会扩成很多内部操作，仍然需要顺序和反馈，而且底下经常还要借用标量访存资源，同时最后又要把结果重新还原成向量语义。

== 先拆，再合

只要先放弃“向量指令应该整体不动地往下走”这个预设，split 和 merge 结构就会很好理解：

- splitter 先把一条向量访存指令拆成更细粒度的内部操作
- 这些内部操作再去借用底下的标量执行资源
- merge buffer 最后再把结果重新拼回向量可见的语义

这本质上是在做“向量语义”和“底层标量化执行基底”之间的翻译层。

== segment 和 first-fault 又增加了特殊语义

这里至少还有两类很关键的特殊路径：

- segment 访存，它不是普通 vector load/store 的简单放大版
- first-fault 行为，它也不能被当成“再加一个 load”就结束

这说明向量访存不仅更宽，而且语义本身就比标量 path 更特殊，所以需要专门控制支持。

== 但底下仍然是标量资源

这一章里最值得警惕的事实之一，就是向量逻辑底下仍然会复用标量端口。在你的笔记里最典型的例子，就是 vector segment 路会抢占 load port 0 的 DCache 和 DTLB 资源。

这意味着某条看起来普通的标量 lane，其实并不只服务标量流量，而是多个子系统共享的入口。于是仲裁、时序和 owner 规则都会变成风险点。

#figure(
  image("imgs/VSegmentUnit-FSM.svg"),
  caption: [VSegmentUnit 的状态机图很适合提醒自己：segment 访存是一条独立控制路径，而不是 split / merge 的自然延伸],
)

== 这一段我会重点看什么

review 这一段时，我主要会盯这些问题：

- split 出去的内部操作，和 merge 回来的结果，是否还保持同一条指令的身份语义
- 标量资源被向量路径借用后，会不会饿死或污染标量流量
- segment 和 first-fault 路径是否真的接进了 rollback、exception 和 writeback 主逻辑
- 向量 feedback 到底是在正确的边界重组，还是只是“晚一点再说”

到了这里，MemBlock 已经不再像传统 LSU 了。它更像是两个部分重叠的访存世界之间的协调层。

#series-navbar("zh", nav)
