#import "../index.typ": template, tufted
#show: template.with(
  locale: "zh",
  route: "blog/libcheckpoint-alpha/",
  title: "把 LibCheckpointAlpha 当作基础设施来读",
)

= 把 LibCheckpointAlpha 当作基础设施来读

#tufted.margin-note[
  参考链接 \
  #link("https://github.com/OpenXiangShan/LibCheckpointAlpha")[LibCheckpointAlpha README] \
  #link("https://github.com/OpenXiangShan/LibCheckpoint")[LibCheckpoint README] \
  #link("https://docs.xiangshan.cc/zh-cn/latest/workloads/opensbi-kernel-for-xs/")[香山 OpenSBI workload 文档]
]

我一开始看 checkpoint 工具，只是想知道它怎么恢复状态。后来再看 `LibCheckpointAlpha`，反复冒出来的是另外几个词：payload、bootloader、direct boot、SimPoint。一个 restore 工具同时讲这些，那它管的就不只是“把状态恢复回来”。

== README 里写了什么

`LibCheckpointAlpha` 的 README 很直白：它把自己描述成 `LibCheckpoint` 的一个过渡版本，并且明确写出当前有两种用途：

- 恢复 checkpoint 状态
- 链接下一层 bootloader，例如 `riscv-pk` 或 `OpenSBI`

也就是说，它的位置卡在“恢复执行”和“把下一层启动起来”之间，不是工作流末尾一个单纯的 restore utility。

== 香山 workload 文档里是怎么用的

香山关于 OpenSBI Linux workload 的文档把这个角色变成了具体步骤：构建完 OpenSBI 之后，要求克隆 `LibCheckpointAlpha`，设置 `GCPT_HOME`，再通过 `make GCPT_PAYLOAD_PATH=...` 生成 `gcpt.bin`。这个产物既可以直接启动，也可以拿去做 SimPoint profiling 和 checkpoint 相关 workload。

读到这里，它就不太像“调试完才用的小工具”了，更像一段中间层：把已经构建好的 payload 重新包装成可以直接启动、可以复用、也可以拿去做 profiling 的工件。

#figure(
  image("imgs/checkpoint-handoff.svg"),
  caption: [checkpoint 工具的位置：payload 构建产物、可复用启动工件、后续 bring-up 复用之间],
)

== 新版 LibCheckpoint 的侧重点

新的 `LibCheckpoint` README 把自己定义成一个面向 `rvgcpt` checkpoint 的 restorer：重点是把内存中的体系结构状态恢复到寄存器里。不过“链接下一层 bootloader”的用法还保留着。

换句话说，新仓库把“恢复”这条主线讲清楚了，但 bootloader 链接和启动工件组织这件事并没有被拿掉。

== 这和 bring-up 有什么关系

这类项目提醒我，bring-up 不是只有 CPU 核和 Linux image 两头。中间这些不起眼的工件决定了控制权怎么交接、状态怎么组织、启动怎么重新进入。

想把一条启动路径反复跑起来，就绕不开它们。
