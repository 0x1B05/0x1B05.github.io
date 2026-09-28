#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": linux-bringup-series
#show: template.with(locale: "zh", route: "docs/linux-bringup/02-configuration/", title: "OpenSBI 在启动链路里做什么")

#let series = linux-bringup-series
#let nav = series-context(series, "docs/linux-bringup/02-configuration/")

= OpenSBI 在启动链路里做什么

#series-navbar("zh", nav)

#doc-toc("zh")

#tufted.margin-note[
  参考资料 \
  #link("https://github.com/riscv-software-src/opensbi")[OpenSBI README] \
  #link("https://docs.xiangshan.cc/zh-cn/latest/workloads/opensbi-kernel-for-xs/")[香山 OpenSBI 内核文档]
]

以前我容易把 Linux 当成启动链路上第一个要关心的软件。但只要认真问一句“是谁把控制权交给 Linux”，machine-mode firmware 这一层就绕不开了，OpenSBI 就坐在这个位置上。

#tufted.margin-note[
  #image("imgs/sbi-boundary.svg")
  SBI 边界就是 machine-mode 控制能力转化成 payload 可以依赖的那层服务界面。
]

#figure(
  image("imgs/boot-chain.svg"),
  caption: [把平台复位、machine-mode firmware、S-mode payload 和用户态放在一条可见链路里],
)

== 它在什么位置

OpenSBI 的 README 直接把它放在一个很明确的位置上：SBI 是运行在 `M-mode` 的平台固件与运行在 `S-mode` 或 `HS-mode` 的软件之间推荐使用的接口，而 OpenSBI 则是这套接口在 machine-mode firmware 侧的开源参考实现。

OpenSBI 不算内核，也不算普通程序。它干的事是把 machine mode 的控制能力，转换成 supervisor-level 软件能依赖的接口和交接约定。

#figure(
  image("imgs/opensbi-handoff-checks.svg"),
  caption: [现在我会放在一起看的三个检查点：payload 放置、device tree handoff，以及 SBI 服务边界],
)

== 这一层通常负责什么

README 里把 `libsbi.a` 描述成一个平台无关的 SBI 接口实现，平台相关的固件代码再去接上硬件相关操作。console access、IPI 控制、定时器相关平台操作，到这一层就开始变得具体。

这正是 bring-up 时必须开始在意的边界：有些失败不是“内核错了”，而是 firmware handoff 或 SBI 服务这一层没有按预期准备好。

== 为什么一做 Linux bring-up 就会遇到它

香山文档会直接把这层变成实践问题：用 OpenSBI 承载 Linux payload、同时传入设备树之后，它就落到实处了——构建命令、镜像布局、地址假设里都有它。

所以 Linux 不往前走的时候，我现在的第一反应是：firmware 有没有按 payload 的预期构建，handoff 是不是真的按软件栈假设的方式发生了。

== 我现在想记住的点

OpenSBI 定义了 Linux 之下那层契约。Linux 一旦成为 payload，firmware build 参数、payload 位置和设备树处理就都变成了要查的细节。

#series-navbar("zh", nav)
