#import "../index.typ": template, tufted
#show: template.with(
  locale: "zh",
  route: "blog/2025-10-30-normal-distribution/",
  title: "为什么一做 Linux Bring-up 就绕不开 OpenSBI",
)

= 为什么一做 Linux Bring-up 就绕不开 OpenSBI

#tufted.margin-note[
  参考链接 \
  #link("https://github.com/riscv-software-src/opensbi")[OpenSBI README] \
  #link("https://riscv.github.io/riscv-isa-manual/snapshot/privileged")[Privileged Architecture Manual] \
  #link("https://docs.xiangshan.cc/zh-cn/latest/workloads/opensbi-kernel-for-xs/")[香山 OpenSBI workload 文档]
]

以前读 RISC-V 特权级时，我更多是在记 `M-mode`、`S-mode`、trap、delegation 这些概念。后来真的开始想让 Linux 起起来，OpenSBI 就不再是“旁边顺手看一下”的东西了。内核之前到底是谁在跑、谁把控制权交过去、哪些服务必须先准备好，这些问题都会落到那层 machine-mode firmware 上。

== SBI 边界是一份真实契约

OpenSBI README 的表述很直接：RISC-V SBI 是运行在 `M-mode` 的平台固件和运行在 `S-mode` 或 `HS-mode` 的软件之间推荐使用的接口，而 OpenSBI 则是这套接口在 machine-mode firmware 侧的开源参考实现。

这句话对 bring-up 很有用，因为它把边界说死了：Linux 不是凭空开始运行的。下面那层 firmware 要负责一部分平台服务，也要把控制权交到正确的位置。哪里没准备好，后面就很可能不是“内核自己坏了”这么简单。

== 构建流程会把这层固件强行拉到台前

香山关于 OpenSBI Linux workload 的文档，会把这条边界立刻变成一个实践问题。它要求在构建 OpenSBI 时，通过 `FW_PAYLOAD_PATH` 指向 Linux kernel image，通过 `FW_FDT_PATH` 指向设备树，再通过 `FW_PAYLOAD_OFFSET` 指定 payload 放置的位置。

这时 firmware 已经不只是代码树里的一个依赖了。它会直接影响启动工件长什么样、payload 放在哪里、设备树从哪里来。

== 为什么这会改变我的阅读方式

特权架构手册当然还是要读，但我现在更容易带着启动链路去看它：

- 当前执行属于哪个 privilege level
- 下一次 handoff 应该由哪一层负责
- Linux 在 SBI 这一侧到底期待什么
- 现在看到的失败更像 firmware 问题，还是更像内核自身的问题

所以 OpenSBI 会突然变得绕不开。它就在规格书里的特权级模型和实际 Linux 启动之间。

== 先记下来的几个判断

- OpenSBI 不是构建流程里顺手拉进来的一个仓库，而是 SBI 边界真正可见的实现。
- 一旦 Linux 成为 payload，firmware 的构建参数就会进入 bring-up 推理本身。
- 把特权级阅读和实际 handoff 链路连起来之后，规格书会变得更有抓手。
