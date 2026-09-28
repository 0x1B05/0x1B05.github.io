#import "../../index.typ": template, tufted, series-context, series-navbar, doc-toc
#import "../series.typ": linux-bringup-series
#show: template.with(locale: "zh", route: "docs/linux-bringup/03-styling/", title: "我如何区分使用 NEMU、NPC 和 gem5")

#let series = linux-bringup-series
#let nav = series-context(series, "docs/linux-bringup/03-styling/")

= 我如何区分使用 NEMU、NPC 和 gem5

#series-navbar("zh", nav)

#doc-toc("zh")

#tufted.margin-note[
  参考资料 \
  #link("https://www.gem5.org/about/")[What gem5 is] \
  #link("https://www.gem5.org/documentation/learning_gem5/introduction")[Learning gem5]
]

刚开始我容易把这几个工具笼统地看成“几种跑 RISC-V 的方式”。这个划分太粗了。它们各自回答不同的问题，入口也不一样。

#figure(
  image("imgs/tool-roles.svg"),
  caption: [我当前把基线仿真、自己的核 bring-up 和面向观察的模拟器分别放在不同位置],
)

== NEMU 更像一个可以对照的基线

在我现在的工作流里，`NEMU` 是一生一芯语境下的教学型全系统模拟器，也是一个相对稳定的参考基线。它不等于“简单”，但能让我先回答一个更基础的问题：一个大致正确的全系统路径应该是什么样子？

所以想先确认软件栈大方向的时候，NEMU 是比较自然的起点。

== NPC 是把问题直接压到我自己的核上

`NPC` 不一样：它是我自己实现和维护的 `RISC-V64` 核项目。在这里问题会直接变成“我自己的实现有没有把这些前提满足好”。同样是 bring-up，硬件边界是自己的，很多假设立刻变得具体。

所以我把 NPC 当成真正的 bring-up 目标。

#figure(
  image("imgs/tool-questions.svg"),
  caption: [真正开始调试之前，我通常先问每个工具的那个核心问题],
)

== gem5 对我来说更像是下一阶段的方法工具

gem5 官方文档把它描述成一个模块化的 computer-system simulation platform。Learning gem5 的导论也提醒得很直白：要用好 gem5，不能只抄命令，得理解模拟器自己是怎么工作的。

这也对上了我学 gem5 的动机：不是再跑一个程序，而是想围绕 workload 和微结构行为建立一套稳定的观察方法。所以 gem5 目前在我这里还是“正在学习的方法工具”，谈不上成熟的工作流。

== 为什么我不把它们当成替代关系

目前这么分工：

- `NEMU` 用来建立全系统行为的基线直觉
- `NPC` 用来直接面对自己的核和 handoff 路径是否真的正确
- `gem5` 用来逐步进入 workload 观察和微结构研究的方法空间

这套分工还在调整，但比笼统叫“几种 RISC-V 模拟工具”清楚多了。

#series-navbar("zh", nav)
