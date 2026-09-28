#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": linux-bringup-series
#show: template.with(locale: "zh", route: "docs/linux-bringup/01-quick-start/", title: "RISC-V 特权级与启动上下文")

#let series = linux-bringup-series
#let nav = series-context(series, "docs/linux-bringup/01-quick-start/")

= RISC-V 特权级与启动上下文

#series-navbar("zh", nav)

#doc-toc("zh")

#tufted.margin-note[
  延伸阅读 \
  #link("https://riscv.github.io/riscv-isa-manual/snapshot/privileged")[Privileged Architecture Manual]
]

做 Linux bring-up 时，最先要搞清楚的不是能不能执行几条指令，而是当前在哪个 privilege mode、trap 落到哪里、下一层由谁接手。特权级在这里从规格书概念变成了每天要查的东西。

== Machine、Supervisor 和 User

RISC-V 的特权架构把软件栈分成几个不同层次：

- `M-mode` 是最高 privilege level，也是硬件平台唯一强制要求实现的模式。
- `S-mode` 是 Linux 这类 supervisor-level OS 预期工作的层次。
- `U-mode` 则是内核把环境准备好之后，普通应用所在的层次。

Linux 不是凭空启动的：得先有更低层的软件把运行环境准备好，再按约定把控制权交给内核。

== 为什么 CSR 和 trap 会很快出现

启动链路一出问题，CSR 和 trap 就没法只当背景知识了：

- 状态寄存器会告诉你 hart 当前处在什么 privilege state
- trap 相关 CSR 决定异常和中断会落到哪里
- 像 `satp` 这样的地址翻译状态会影响虚拟内存相关假设从什么时候开始成立
- delegation 则决定哪一层先看到哪一类 trap

没必要一开始就把每个 CSR 都抠细，但大图景要清楚：trap 落错层，或者 privilege transition 不对，Linux 往往在还没来得及打印有效信息之前就停住了。

== 启动上下文不只是“能跑代码”

动手前要回答的是这些偏上下文的问题：

- hart 上电以后首先在哪个 mode 里执行？
- 下一次 privilege transition 由谁负责？
- 设备树和启动参数由哪一层传下去？
- Linux 依赖的 SBI 调用由谁提供？
- 如果路径正确，最早应该在哪里看到“活着”的信号？

这些问题的答案都落在特权架构这套模型里。所以在碰 Linux 细节之前，得先把 privilege 和 handoff 这条线理顺。

#series-navbar("zh", nav)
