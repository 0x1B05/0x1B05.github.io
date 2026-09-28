#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/04-mmu-and-permission/", title: "DTLB、PTW 与 PMP")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/04-mmu-and-permission/")

= DTLB、PTW 和 PMP：翻译和权限检查集中在 MemBlock

#series-navbar("zh", nav)

#doc-toc("zh")

到这一章，地址翻译和权限检查开始进入 MemBlock 的控制面。load、store、prefetch、向量访存几条路径都压在 MMU 上，它的仲裁和 flush 会直接影响整个访存子系统的调度。

#figure(
  image("imgs/two-stage-translation-sv39-sv39x4.svg"),
  caption: [香山 MMU 文档里的两阶段翻译流程图。进入两阶段之后，一次地址翻译就不再是单次 TLB 查询，而是多阶段协调],
)

== DTLB 为什么分成多组

先别预设 DTLB 应该是一个统一的大块。MemBlock 把 requester 分成几组，因为不同流量类别的时序压力和冲突模式本来就不一样：

- 一组偏向 load requester
- 一组偏向 store requester
- 一组偏向 prefetch 或更靠 L2 的 requester

作者没有把不同访存类别硬塞进一个完全统一的端口模型；塞进去的话，替换、仲裁和 replay 都会更难处理。

== 为什么 PTW 的扇入扇出会出现在这里

PTW 是共享的，但 requester 很多。这就意味着 MemBlock 需要自己去做几件事：

- 收拢多个 requester 的 page walk 请求
- 把共享 PTW 的返回结果重新分发出去
- 让多个 DTLB 面向同一个 PTW 时仍然保持身份和时序关系

所以 PTW 在这里是个需要仲裁和广播的共享资源，挂上去就不管是不行的。

== PMP 和 PMPChecker 为什么分开

另一个观察点是区分“全局配置来源”和“按 requester 并行检查”：

- 全局 PMP 模块持有统一配置视图
- 多个 `PMPChecker` 分别针对各 requester 路径做并行检查

这种拆分能把权限检查贴近活跃 requester，同时又不必把全局状态逻辑复制进每个执行单元。

== 为什么 `sfence`、CSR 控制和 redirect 会在这里集中

翻译状态有全局一致性要求，MemBlock 就成了这些事件的广播点：

- `sfence`
- 影响地址翻译的 CSR 状态变化
- redirect 和类似 flush 的控制事件

这些不适合让某条 load pipe 自己“顺手处理”，因为它们影响的是整个翻译层的有效性。

== 这一层的高危点

如果从风险角度读，我会重点看：

- flush 或 redirect 后，旧翻译状态会不会残留
- 多 requester 共享翻译资源时，仲裁会不会在错误时机偏向错误对象
- 翻译成功与权限检查结果之间，时序是否总能对齐
- 向量或特殊路径借用翻译端口时，有没有打破原本的顺序假设

#series-navbar("zh", nav)
