#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/07-review-checklist/", title: "MemBlock Review 检查框架")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/07-review-checklist/")

= 我会怎么 review MemBlock：一份高风险路径检查框架

#series-navbar("zh", nav)

前面几章把系统拆开看完之后，我更想把它重新压缩成一份真正能用的检查框架。重点不是预设每个细节都有问题，而是避免面对这么大的子系统时只是在被动读代码，没有稳定的问题意识。

== 我会先看的结构性问题

- `loadUnits(0)`、`loadUnits(1)`、`loadUnits(2)` 的 owner 规则是不是仍然清楚且一致？
- 任何特殊路径借用某条 lane 时，代码里有没有同时把抢占规则写清楚？
- writeback override 是不是只有一个明确胜者来源，而不是几处局部都在争？
- 多个 rollback 候选并存时，是否有一个显眼的统一位置负责选出“最老且真正应该生效”的那个？

== MMU 与权限这一层

- 每类 requester 是否进入了预期的 DTLB 分组？
- 多 requester 共享 PTW 时，返回结果还能不能稳住 requester 身份？
- `sfence`、地址翻译相关 CSR 变化和 redirect 事件，是否到达了所有会缓存翻译状态的路径？
- PMP 检查结果是否始终和发起该访问的 requester 对齐？

== 数据路径与 memory-system 边界

- load、store-address、store-data 三条路径在 LSQ 里汇合时，生命周期和顺序假设是否还成立？
- LSQ 到 SBuffer 的边界，是否清楚地区分了“顺序状态”和“写出状态”？
- cacheable 和 uncacheable 返回路径是不是显式分开的？
- 像 uncache return lane 这种特殊 lane，是否在整条路径上都保持特殊，而不是只在一个点上特殊？

== 向量与特殊路径

- 向量访存借用标量资源时，仲裁规则是不是显式可见？
- split / merge 边界是否保持了异常与 feedback 的一致叙事？
- first-fault 和 segment 路径是否真的进入了 rollback / writeback 主逻辑，而不只是“旁边多了个功能”？
- atomics 或 misalign 复用某条 lane 时，周围所有路径是否仍然知道这一拍谁才是 owner？

== 我会怎么把这些问题变成测试

如果要进一步落到验证上，我不会先跑一个大系统然后希望某个 corner 自己露出来。我更想围绕这份清单构造小场景：

- 每条被借用的 lane 都至少构一个 case
- 每条特殊返回路径都至少构一个 case
- 把一个控制事件，例如 redirect 或异常，和一个共享资源路径组合起来
- 记录清楚覆盖了哪些组合，而不只是“读过哪些文件”

这也是我想把这些笔记整理成系列的原因。MemBlock 足够大，大到如果没有检查框架，阅读很快就会退化成一种被动浏览。

#series-navbar("zh", nav)
