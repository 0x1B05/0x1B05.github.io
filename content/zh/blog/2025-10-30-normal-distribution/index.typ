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

当我开始把 Linux bring-up 当成一个现实中的任务，而不是遥远的“以后再说”，OpenSBI 就很难继续被当成背景知识了。在那之前，很容易把特权级阅读停留在模式划分和规格术语上；一旦目标变成真实的启动链路，位于 machine mode 和 supervisor-level 软件之间的那层固件就会突然变得非常具体。

== SBI 边界是一份真实契约

OpenSBI README 的表述很直接：RISC-V SBI 是运行在 `M-mode` 的平台固件和运行在 `S-mode` 或 `HS-mode` 的软件之间推荐使用的接口，而 OpenSBI 则是这套接口在 machine-mode firmware 侧的开源参考实现。

这句话的重要性在于，它把一个抽象边界变成了一份真实契约。一旦 Linux 成为我要启动的目标，我就不能再只说“内核总会在某个时刻开始运行”。我必须认真问：是谁负责把控制权交过去，Linux 又期待在这层之下得到什么服务？

== 构建流程会把这层固件强行拉到台前

香山关于 OpenSBI Linux workload 的文档，会把这条边界立刻变成一个实践问题。它要求在构建 OpenSBI 时，通过 `FW_PAYLOAD_PATH` 指向 Linux kernel image，通过 `FW_FDT_PATH` 指向设备树，再通过 `FW_PAYLOAD_OFFSET` 指定 payload 放置的位置。

这样一来，firmware 就不再是“在后面默默存在的库”，而会直接出现在启动工件、镜像布局和地址假设里。

== 为什么这会改变我的阅读方式

特权架构手册当然仍然重要，但我现在读它的方式已经变了。我不再只是想把每个概念孤立地记下来，而是更想顺着一条具体链路去问：

- 当前执行属于哪个 privilege level
- 下一次 handoff 应该由哪一层负责
- Linux 在 SBI 这一侧到底期待什么
- 现在看到的失败更像 firmware 问题，还是更像内核自身的问题

这也是为什么 OpenSBI 会突然变得绕不开。它恰好站在“启动链路不再是抽象图示，而开始成为具体问题”的那个位置上。

== 我现在的 takeaway

- OpenSBI 不是构建流程里顺手拉进来的一个仓库，而是 SBI 边界真正可见的实现。
- 一旦 Linux 成为 payload，firmware 的构建参数就会进入 bring-up 推理本身。
- 把特权级阅读和实际 handoff 链路连起来之后，规格书会变得更有抓手。
