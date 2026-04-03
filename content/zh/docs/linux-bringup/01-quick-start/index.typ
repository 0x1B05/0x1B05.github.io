#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": linux-bringup-series
#show: template.with(locale: "zh", route: "docs/linux-bringup/01-quick-start/", title: "RISC-V 特权级与启动上下文")

#let series = linux-bringup-series
#let nav = series-context(series, "docs/linux-bringup/01-quick-start/")

= RISC-V 特权级与启动上下文

#series-navbar("zh", nav)

#tufted.margin-note[
  延伸阅读 \
  #link("https://riscv.github.io/riscv-isa-manual/snapshot/privileged")[Privileged Architecture Manual]
]

一旦开始碰 Linux bring-up，特权级就不再只是规格书里的概念了。目标从“能不能执行几条指令”变成“当前在哪个 privilege mode、trap 到哪里、下一层由谁接手”，很多之前看起来抽象的东西都会立刻变得具体。

== Machine、Supervisor 和 User

RISC-V 的特权架构把软件栈分成几个不同层次：

- `M-mode` 是最高 privilege level，也是硬件平台唯一强制要求实现的模式。
- `S-mode` 是 Linux 这类 supervisor-level OS 预期工作的层次。
- `U-mode` 则是内核把环境准备好之后，普通应用所在的层次。

这个区分之所以重要，是因为 Linux 不是凭空启动的。必须先有更低层的软件把运行环境准备好，再按照预期把控制权交给内核。

== 为什么 CSR 和 trap 会很快出现

一旦启动链路变成实际问题，CSR 和 trap 就很难继续被当成背景知识：

- 状态寄存器会告诉你 hart 当前处在什么 privilege state
- trap 相关 CSR 决定异常和中断会落到哪里
- 像 `satp` 这样的地址翻译状态会影响虚拟内存相关假设从什么时候开始成立
- delegation 则决定哪一层先看到哪一类 trap

即使我不会一开始就把每个 CSR 都抠细，至少也要搞清楚大图景：如果 trap 落错层，或者 privilege transition 不对，Linux bring-up 往往会在还来不及打印有效信息之前就停住。

== 启动上下文不只是“能跑代码”

我现在更关心的是这些更偏上下文的问题：

- hart 上电以后首先在哪个 mode 里执行？
- 下一次 privilege transition 由谁负责？
- 设备树和启动参数由哪一层传下去？
- Linux 依赖的 SBI 调用由谁提供？
- 如果路径正确，最早应该在哪里看到“活着”的信号？

这些问题看起来更像启动链路问题，但它们其实都直接站在特权架构这套模型上。

== 这一章我现在的结论

- privilege split 不是纯概念，它决定了 firmware、kernel 和应用之间的分工边界。
- CSR 和 trap 之所以早早出现，是因为它们决定控制权是否真的到达了预期层次。
- 在碰 Linux 细节之前，我首先需要把 privilege 和 handoff 的故事讲清楚。

#series-navbar("zh", nav)
