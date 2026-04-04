#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": xiangshan-memblock-series
#show: template.with(locale: "zh", route: "docs/xiangshan-memblock/02-interfaces/", title: "ooo_to_mem 与 mem_to_ooo")

#let series = xiangshan-memblock-series
#let nav = series-context(series, "docs/xiangshan-memblock/02-interfaces/")

= MemBlock 和后端之间的大门：`ooo_to_mem` / `mem_to_ooo`

#series-navbar("zh", nav)

一旦把总图立住，下一步最有用的入口就是 MemBlock 和后端之间的那对接口。它们会先告诉你：后端究竟希望 MemBlock 吃进什么、又希望它吐出什么。这样读内部连线时，不会失去系统边界感。

== `ooo_to_mem` 往里送了什么

进入 MemBlock 的 issue 流本来就已经按访存角色拆开了，而不是一个统一的黑盒请求流：

- `issueLda` 负责 load-address 这一侧
- `issueSta` 负责 store-address 这一侧
- `issueStd` 负责 store-data 这一侧
- 像 `issueVldu` 这样的向量访存 issue 口
- 以及 `csrCtrl`、`sfence`、redirect 相关控制输入

这个拆分本身就很说明问题。MemBlock 内部的路径分工，不是读代码的人后来总结出来的，而是后端接口层已经在显式表达。

== `mem_to_ooo` 返回的不只是 writeback

返回后端的东西远不只是“执行结果”：

- load、store、vector 对应的 writeback
- IQ feedback
- wakeup
- load cancel
- memory violation 和 replay 相关反馈
- LSQ 状态与 rollback 相关控制信息

这也是为什么我倾向于先看边界接口。它立刻会提醒我：MemBlock 不只是数据通道，也是控制反馈枢纽。

== 为什么这里适合作为第一层阅读抓手

如果太早就扎进某个子模块，很容易局部看懂、全局丢失。边界接口能先回答这些问题：

- 进入 MemBlock 的访存 uop 到底分成了哪些类
- 哪些控制事件天然需要扇出到很多子模块
- 哪些结果和反馈是后端真正可见、真正依赖的

它还会帮我给代码正确命名。writeback 是一类东西，replay/violation feedback 又是另一类东西。它们都叫“反馈”会让判断变模糊。

== 这一层我会先问什么

我会先带着这几类问题往后读：

- 每条 issue lane 有没有清楚的 owner 和返回路径？
- cancel、wakeup、feedback 是否始终跟着同一种指令类别走？
- redirect 或 violation 到来时，会不会和正在借用共享资源的特殊路径冲突？
- 多个 rollback 候选同时出现时，到底在哪里统一决出真正生效的那个？

这些问题先立住，后面读内部 wiring 的时候才知道自己在验证什么，而不是只是在跟线。

#series-navbar("zh", nav)
