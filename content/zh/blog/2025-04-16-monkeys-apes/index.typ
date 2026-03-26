#import "../index.typ": template, tufted
#show: template.with(
  locale: "zh",
  route: "blog/2025-04-16-monkeys-apes/",
  title: "把 LibCheckpointAlpha 当作基础设施来读",
)

= 把 LibCheckpointAlpha 当作基础设施来读

#tufted.margin-note[
  参考链接 \
  #link("https://github.com/OpenXiangShan/LibCheckpointAlpha")[LibCheckpointAlpha README] \
  #link("https://github.com/OpenXiangShan/LibCheckpoint")[LibCheckpoint README] \
  #link("https://docs.xiangshan.cc/zh-cn/latest/workloads/opensbi-kernel-for-xs/")[香山 OpenSBI workload 文档]
]

我对 checkpoint 工具感兴趣，并不只是因为它能“恢复一个状态”，而是因为它往往会把很多本来分散在不同层里的事情拉到一起看：恢复、payload 链接、直接启动、重新进入执行流。只要一个项目把这些都放在同一个 README 里，它其实就在提醒我，启动链路并没有我原来想得那么线性。

== 为什么 LibCheckpointAlpha 会引起我的注意

`LibCheckpointAlpha` 的 README 非常直接：它把自己描述成 `LibCheckpoint` 的一个过渡版本，并且明确写出当前有两种用途：

- 恢复 checkpoint 状态
- 链接下一层 bootloader，例如 `riscv-pk` 或 `OpenSBI`

这一点很有意思，因为它说明这个项目不是一个藏在工作流边角的 restore utility。它正好站在“恢复执行”和“把下一层启动起来”相交的那个位置上。

== 香山 workload 文档把这个角色说得更具体

香山关于 OpenSBI Linux workload 的文档，把这个 README 里的角色变成了可执行流程。文档在构建完 OpenSBI 之后，会明确要求克隆 `LibCheckpointAlpha`，设置 `GCPT_HOME`，再通过 `make GCPT_PAYLOAD_PATH=...` 生成 `gcpt.bin`，这个产物既可以直接启动，也可以拿去做 SimPoint profiling 和 checkpoint 相关 workload。

这样一来，我很难再把它理解成一个“调试后处理小工具”。它更像一段真正的中间层基础设施：把已经构建好的 payload 组织成可重复使用的启动工件。

#figure(
  image("imgs/checkpoint-handoff.svg"),
  caption: [我现在更愿意这样理解 checkpoint 工具：它站在 payload 构建产物、可复用启动工件和后续 bring-up 复用之间],
)

== 更新后的 LibCheckpoint 又把重点放到了哪里

新的 `LibCheckpoint` README 把标题写得更聚焦：它把自己定义成一个面向 `rvgcpt` checkpoint 的 restorer，重点是把内存中的体系结构状态恢复到寄存器里。但与此同时，它仍然保留了“链接下一层 bootloader”的使用方式。

所以我更愿意把它理解成：新的仓库把“恢复”这件事表达得更清楚了，但它作为基础设施连接点的角色并没有消失。

== 为什么我会关心这种项目

这类项目会改变我对整条软件栈的理解。它提醒我，bring-up 不只是 CPU 核本身的事，也不只是 Linux image 本身的事。中间这些看起来很“土木”的工件同样决定了控制权怎么交接、状态怎么被组织、启动怎么被重新进入。

这种有点“无聊”、但真正决定路径是否可复用的基础设施，正是我现在想补齐理解的部分。
