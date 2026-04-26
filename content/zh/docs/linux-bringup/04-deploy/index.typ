#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": linux-bringup-series
#show: template.with(locale: "zh", route: "docs/linux-bringup/04-deploy/", title: "一份正在使用的 Linux Bring-up 检查框架")

#let series = linux-bringup-series
#let nav = series-context(series, "docs/linux-bringup/04-deploy/")

= 一份正在使用的 Linux Bring-up 检查框架

#series-navbar("zh", nav)

这一章是我现在还会拿出来看的 bring-up 检查清单。它不讲“最后怎么成功了”，只把最先该确认的东西放在一起，免得卡住以后直接开始乱猜。

== 在进入内核之前

我最先确认的是这些前提：

- 控制到达当前阶段时，hart 处在什么 privilege mode？
- firmware 到 payload 的 handoff 路径是否明确？
- entry address、payload offset 和预期加载地址之间是否彼此一致？
- 当前 device tree 真的是这个 payload 预期看到的那个吗？

如果这些问题都还说不清楚，再去解释后面的症状，往往会很快掉进猜谜里。

== firmware handoff

当 OpenSBI 进入路径之后，我现在会先检查：

- payload 是怎么链接进去的
- device tree 路径和 payload 路径是不是当前这次构建真正使用的版本
- firmware image 采用的 handoff 约定是不是 payload 侧假设的那一种
- firmware 这一层能不能给出足够的信息，让我知道控制权确实往前走了

这一层一旦错了，看起来很像“内核没起来”，但它们其实不是同一种诊断。

== device tree 和 memory map 的基本一致性

我还会用一份更枯燥但很必要的 memory-map 检查：

- payload 放置的位置是否真是当前 firmware build 假设的那个地址
- 有没有 reserved region 和 Linux 或当前 boot payload 想用的空间撞上
- device tree 描述的平台信息是否真的和当前运行目标匹配
- 如果中间还有 checkpoint、initramfs 或 payload wrapper，它们隐式占用了哪些地址范围

这些问题很烦，但它们就是最容易把 bring-up 搞得看上去莫名其妙的那类不一致。

== 最早的“活着”信号

最先有价值的观察通常很小：

- 一条 console 输出
- 一个到达过的已知阶段
- 一个落在预期位置的 trap
- 一个至少能说明“停在这里”的 timeout 或 watchdog 迹象

比起没有证据就直接猜更深层的原因，我更愿意先拿到一个可信的小进展信号。

== 当启动流程卡住时

当什么明显信号都没有时，我会继续问自己：

- 控制是在进入内核之前停住了，还是已经过了 firmware 阶段才停？
- 是真的没有发生预期 transition，还是我根本没有把日志信号接出来？
- 在改更多代码之前，有没有哪个前提可以先低成本验证？
- 如果拿 NEMU 作为基线，最先发生偏离的是哪一层？

这份清单本来就应该有点无聊。先按一条固定路径排掉低级不一致，再去猜更深的问题，效率会高很多。

#series-navbar("zh", nav)
