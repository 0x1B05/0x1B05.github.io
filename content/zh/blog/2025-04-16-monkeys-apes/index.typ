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

我一开始看 checkpoint 工具，只是想知道它怎么恢复状态。后来再看 `LibCheckpointAlpha`，注意力反而被另一些词带走了：payload、bootloader、direct boot、SimPoint。一个 restore 工具如果同时在讲这些东西，那它处理的就不只是“把状态恢复回来”。

== 为什么 LibCheckpointAlpha 会引起我的注意

`LibCheckpointAlpha` 的 README 非常直接：它把自己描述成 `LibCheckpoint` 的一个过渡版本，并且明确写出当前有两种用途：

- 恢复 checkpoint 状态
- 链接下一层 bootloader，例如 `riscv-pk` 或 `OpenSBI`

这点很关键。它不是一个藏在工作流末尾的 restore utility，而是卡在“恢复执行”和“把下一层启动起来”之间。

== 香山 workload 文档把这个角色说得更具体

香山关于 OpenSBI Linux workload 的文档，把这个 README 里的角色变成了可执行流程。文档在构建完 OpenSBI 之后，会明确要求克隆 `LibCheckpointAlpha`，设置 `GCPT_HOME`，再通过 `make GCPT_PAYLOAD_PATH=...` 生成 `gcpt.bin`，这个产物既可以直接启动，也可以拿去做 SimPoint profiling 和 checkpoint 相关 workload。

读到这里，我就很难再把它当成调试之后才用的小工具。它更像一段中间层：把已经构建好的 payload 重新包装成可以直接启动、可以复用、也可以拿去做 profiling 的工件。

#figure(
  image("imgs/checkpoint-handoff.svg"),
  caption: [我现在更愿意这样理解 checkpoint 工具：它站在 payload 构建产物、可复用启动工件和后续 bring-up 复用之间],
)

== 更新后的 LibCheckpoint 又把重点放到了哪里

新的 `LibCheckpoint` README 把标题写得更聚焦：它把自己定义成一个面向 `rvgcpt` checkpoint 的 restorer，重点是把内存中的体系结构状态恢复到寄存器里。但与此同时，它仍然保留了“链接下一层 bootloader”的使用方式。

所以我的理解是：新仓库把“恢复”这个主线说得更清楚了，但它仍然没有完全离开 bootloader 链接和启动工件组织这件事。

== 为什么我会关心这种项目

这类项目会让我重新看 bring-up 的边界。它不是只有 CPU 核和 Linux image 两头，中间那些看起来很不起眼的工件也会决定控制权怎么交接、状态怎么组织、启动怎么重新进入。

这些东西不太显眼，但如果想把一条启动路径反复跑起来，就绕不开它们。
