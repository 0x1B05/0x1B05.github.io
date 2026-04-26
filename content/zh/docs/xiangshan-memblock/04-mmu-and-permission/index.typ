#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/04-mmu-and-permission/", title: "DTLB、PTW 与 PMP")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/04-mmu-and-permission/")

= DTLB、PTW 和 PMP：为什么地址翻译与权限检查在这里集中出现

#series-navbar("zh", nav)

#doc-toc("zh")

MemBlock 也是地址翻译和权限检查真正开始进入控制面的位置。等 load、store、prefetch、向量访存这些路径都叠在一起之后，MMU 这一侧就不再只是“后台服务”，而会直接影响整个访存子系统的调度与一致性。

#figure(
  image("imgs/two-stage-translation-sv39-sv39x4.svg"),
  caption: [香山 MMU 文档里的两阶段翻译流程图很适合提醒自己：翻译很快就会从单次 TLB 查询变成多阶段协调问题],
)

== 为什么 DTLB 不是一大坨，而是多组

如果先不要预设“应该只有一个巨大 DTLB”，这块会更好读。MemBlock 把 requester 分成几组，是因为不同流量类别的时序压力和冲突模式本来就不一样：

- 一组偏向 load requester
- 一组偏向 store requester
- 一组偏向 prefetch 或更靠 L2 的 requester

这个组织方式本身就在暗示：不同访存类别不值得硬塞进一个完全统一的端口模型里，否则替换、仲裁和 replay 都会更难处理。

== 为什么 PTW 的扇入扇出会出现在这里

PTW 是共享的，但 requester 很多。这就意味着 MemBlock 需要自己去做几件事：

- 收拢多个 requester 的 page walk 请求
- 把共享 PTW 的返回结果重新分发出去
- 让多个 DTLB 面向同一个 PTW 时仍然保持身份和时序关系

所以 PTW 在这里不是一个“挂在下面就行”的模块，而是一个需要仲裁和广播的共享资源。

== PMP 和 PMPChecker 为什么分开

另一个很好用的观察点是区分“全局配置来源”和“按 requester 并行检查”：

- 全局 PMP 模块持有统一配置视图
- 多个 `PMPChecker` 分别针对各 requester 路径做并行检查

这种拆分能把权限检查贴近活跃 requester，同时又不必把全局状态逻辑复制进每个执行单元。

== 为什么 `sfence`、CSR 控制和 redirect 会在这里集中

翻译状态天然带有全局一致性要求，所以 MemBlock 很自然会变成这些事件的广播点：

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

到了这里，MMU 已经不是一个孤立基础设施，而是 MemBlock 控制面的组成部分。

#series-navbar("zh", nav)
