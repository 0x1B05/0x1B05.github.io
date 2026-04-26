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

OpenSBI 是最近让我明显感觉“启动链路不再抽象”的那一层。以前容易把 Linux 当成第一个真正值得关心的软件，但一旦认真问“是谁把控制权交给 Linux”，machine-mode firmware 这一层就不再是可有可无的背景知识了。

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

也就是说，OpenSBI 既不是内核，也不是普通程序。它真正重要的地方在于：它把 machine mode 的控制能力，转换成 supervisor-level 软件能够依赖的那套接口和交接关系。

#figure(
  image("imgs/opensbi-handoff-checks.svg"),
  caption: [现在我会放在一起看的三个检查点：payload 放置、device tree handoff，以及 SBI 服务边界],
)

== 这一层通常负责什么

OpenSBI README 里有一个很有帮助的点：它把 `libsbi.a` 描述成一个平台无关的 SBI 接口实现，而平台相关的固件代码再去接上硬件相关操作。像 console access、IPI 控制、定时器相关平台操作这样的事情，就会在这一层开始变得具体。

这正是 bring-up 时必须开始在意的边界：有些失败并不是“内核错了”，而是 firmware handoff 或 SBI 服务这一层没有按预期准备好。

== 为什么一做 Linux bring-up 就会遇到它

香山文档会很快把这个问题变成实践问题：当你用 OpenSBI 去承载 Linux payload，并且同时传入设备树之后，OpenSBI 这一层就不再只是概念中的“固件”。它会直接出现在构建命令、镜像布局和地址假设里。

这也改变了我现在看 bring-up 的方式。如果 Linux 没有继续往前走，一个很自然的问题就是：firmware 是否按 payload 的预期构建好了，handoff 是否真的按照软件栈假设的方式发生了。

== 我现在想记住的点

- OpenSBI 是 machine-mode firmware 和 supervisor-level software 之间那层明确可见的交接面。
- 它之所以重要，不在于它有多大，而在于它定义了 Linux 之下那层契约。
- 一旦 Linux 成为 payload，firmware build 参数、payload 位置和设备树处理都不再是次要细节。

#series-navbar("zh", nav)
