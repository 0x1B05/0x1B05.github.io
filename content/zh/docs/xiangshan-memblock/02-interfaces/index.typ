#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/02-interfaces/", title: "ooo_to_mem 与 mem_to_ooo")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/02-interfaces/")

= MemBlock 和后端之间的大门：`ooo_to_mem` / `mem_to_ooo`

#series-navbar("zh", nav)

#doc-toc("zh")

总图有了之后，下一步看 MemBlock 和后端之间的那对接口。它们回答两个问题：后端往 MemBlock 里送什么、MemBlock 往回吐什么。先把这层看清，读内部连线时才不容易丢掉边界感。

== `ooo_to_mem` 往里送了什么

进入 MemBlock 的 issue 流已经按访存角色拆开了，不是一团统一的请求流：

- `issueLda` 负责 load-address 这一侧
- `issueSta` 负责 store-address 这一侧
- `issueStd` 负责 store-data 这一侧
- 像 `issueVldu` 这样的向量访存 issue 口
- 以及 `csrCtrl`、`sfence`、redirect 相关控制输入

这个拆分本身就说明问题：MemBlock 内部的路径分工，后端在接口层已经显式写出来了，不用读者自己去归纳。

== `mem_to_ooo` 返回的不只是 writeback

返回后端的东西远不只是“执行结果”：

- load、store、vector 对应的 writeback
- IQ feedback
- wakeup
- load cancel
- memory violation 和 replay 相关反馈
- LSQ 状态与 rollback 相关控制信息

这也是为什么我习惯先看边界接口：它直接说明 MemBlock 除了搬数据，还是控制反馈的枢纽。

== 为什么先抓这一层

太早扎进某个子模块，容易局部看懂、全局丢失。边界接口先回答三个问题：

- 进入 MemBlock 的访存 uop 到底分成了哪些类
- 哪些控制事件天然需要扇出到很多子模块
- 哪些结果和反馈是后端真正可见、真正依赖的

顺便还能把名字叫对：writeback 是一类东西，replay/violation feedback 是另一类。都叫“反馈”的话，判断会变模糊。

== 带着什么问题往后读

- 每条 issue lane 有没有清楚的 owner 和返回路径？
- cancel、wakeup、feedback 是否始终跟着同一种指令类别走？
- redirect 或 violation 到来时，会不会和正在借用共享资源的特殊路径冲突？
- 多个 rollback 候选同时出现时，到底在哪里统一决出真正生效的那个？

先把这些问题立住，后面读内部 wiring 时才知道自己在验证什么，不至于只是在跟线。

#series-navbar("zh", nav)
