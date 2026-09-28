#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/07-review-checklist/", title: "MemBlock Review 检查框架")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/07-review-checklist/")

= 怎么 review MemBlock：高风险路径检查清单

#series-navbar("zh", nav)

#doc-toc("zh")

前面几章把系统拆开看完了，这里把问题收成一份 review 时用得上的清单。MemBlock 太大，手里没有固定的问题清单，很容易变成顺着代码往下滑，看完什么也没抓住。

== 我会先看的结构性问题

- `loadUnits(0)`、`loadUnits(1)`、`loadUnits(2)` 的 owner 规则是不是仍然清楚且一致？
- 任何特殊路径借用某条 lane 时，代码里有没有同时把抢占规则写清楚？
- writeback override 是不是只有一个明确的胜者来源，没有几处局部逻辑在争？
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
- 像 uncache return lane 这种特殊 lane，特殊属性是否贯穿整条路径，还是只在某一个点上生效？

== 向量与特殊路径

- 向量访存借用标量资源时，仲裁规则是不是显式可见？
- split / merge 边界是否保持了异常与 feedback 的一致叙事？
- first-fault 和 segment 路径是否真的进入了 rollback / writeback 主逻辑，还是只是旁边挂了个功能？
- atomics 或 misalign 复用某条 lane 时，周围所有路径是否仍然知道这一拍谁才是 owner？

== 我会怎么把这些问题变成测试

要落到验证上，我不会指望跑一个大系统让某个 corner 自己露出来，而是围绕这份清单构造小场景：

- 每条被借用的 lane 都至少构一个 case
- 每条特殊返回路径都至少构一个 case
- 把一个控制事件，例如 redirect 或异常，和一个共享资源路径组合起来
- 记录清楚覆盖了哪些组合，而不只是“读过哪些文件”

这也是我把这些笔记整理成系列的原因。MemBlock 足够大，读的时候必须不断把结构问题落回具体 case。

#series-navbar("zh", nav)
