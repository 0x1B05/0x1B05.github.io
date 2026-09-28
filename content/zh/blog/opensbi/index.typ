#import "../index.typ": template, tufted
#show: template.with(
  locale: "zh",
  route: "blog/opensbi/",
  title: "为什么一做 Linux Bring-up 就绕不开 OpenSBI",
)

= 为什么一做 Linux Bring-up 就绕不开 OpenSBI

#tufted.margin-note[
  参考链接 \
  #link("https://github.com/riscv-software-src/opensbi")[OpenSBI README] \
  #link("https://riscv.github.io/riscv-isa-manual/snapshot/privileged")[Privileged Architecture Manual] \
  #link("https://docs.xiangshan.cc/zh-cn/latest/workloads/opensbi-kernel-for-xs/")[香山 OpenSBI workload 文档]
]

以前读 RISC-V 特权级时，基本是在记 `M-mode`、`S-mode`、trap、delegation 这些概念。后来真的要让 Linux 跑起来，问题就具体了：内核之前是谁在跑、控制权怎么交过去、哪些服务得先准备好。这些事的答案都在那层 machine-mode firmware 上，也就是 OpenSBI。

== SBI 边界是一份真实契约

OpenSBI README 的表述很直接：RISC-V SBI 是运行在 `M-mode` 的平台固件和运行在 `S-mode` 或 `HS-mode` 的软件之间推荐使用的接口，而 OpenSBI 则是这套接口在 machine-mode firmware 侧的开源参考实现。

这句话把边界说死了：Linux 不是凭空开始运行的。下面那层 firmware 要负责一部分平台服务，还要把控制权交到正确的位置。哪一步没准备好，后面看到的失败未必是内核自己的问题。

== 构建流程会把这层固件强行拉到台前

香山关于 OpenSBI Linux workload 的文档，会把这条边界立刻变成一个实践问题。它要求在构建 OpenSBI 时，通过 `FW_PAYLOAD_PATH` 指向 Linux kernel image，通过 `FW_FDT_PATH` 指向设备树，再通过 `FW_PAYLOAD_OFFSET` 指定 payload 放置的位置。

到这一步，firmware 直接决定启动工件长什么样、payload 放在哪里、设备树从哪里来。

== 带着启动链路去读手册

特权架构手册还是要读，但带着启动链路去读会顺很多：

- 当前执行属于哪个 privilege level
- 下一次 handoff 应该由哪一层负责
- Linux 在 SBI 这一侧到底期待什么
- 现在看到的失败更像 firmware 问题，还是更像内核自身的问题

OpenSBI 就卡在规格书的特权级模型和实际 Linux 启动之间，所以绕不开它。
