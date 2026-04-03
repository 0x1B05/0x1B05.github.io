#import "../../index.typ": template, tufted, series-context, series-navbar
#import "../series.typ": linux-bringup-series
#show: template.with(locale: "zh", route: "docs/linux-bringup/03-styling/", title: "我如何区分使用 NEMU、NPC 和 gem5")

#let series = linux-bringup-series
#let nav = series-context(series, "docs/linux-bringup/03-styling/")

= 我如何区分使用 NEMU、NPC 和 gem5

#series-navbar("zh", nav)

#tufted.margin-note[
  参考资料 \
  #link("https://www.gem5.org/about/")[What gem5 is] \
  #link("https://www.gem5.org/documentation/learning_gem5/introduction")[Learning gem5]
]

刚开始把这些工具放在一起看时，我很容易把它们理解成“几种不同的 RISC-V 运行方式”。但这个划分太粗了。更有用的做法，是把它们看成帮助我回答不同问题的不同入口。

#figure(
  image("imgs/tool-roles.svg"),
  caption: [我当前把基线仿真、自己的核 bring-up 和面向观察的模拟器分别放在不同位置],
)

== NEMU 更像一个可以对照的基线

在我现在的工作流里，`NEMU` 更像是一生一芯语境下的教学型全系统模拟器，也是一个相对稳定的参考基线。它不一定意味着“简单”，但它能让我先回答一个更基础的问题：一个大致正确的全系统路径应该是什么样子？

所以当我先想确认软件栈的大方向时，NEMU 会是比较自然的起点。

== NPC 是把问题直接压到我自己的核上

`NPC` 不一样，因为它是我自己实现和维护的 `RISC-V64` 核项目。这样一来，问题就不再只是“软件期望是什么”，而会直接变成“我自己的实现有没有真的把这些前提满足好”。同样是 bring-up，硬件边界一旦是自己的，很多假设都会立刻变得更具体。

这也是为什么我会把 NPC 当成真正的 bring-up 目标，而不是把它看成另一种“能跑程序的工具”。

#figure(
  image("imgs/tool-questions.svg"),
  caption: [真正开始调试之前，我通常先问每个工具的那个核心问题],
)

== gem5 对我来说更像是下一阶段的方法工具

gem5 官方文档把它描述成一个模块化的 computer-system simulation platform，而 Learning gem5 的导论也很直白地提醒：要真正用好 gem5，不能只会抄命令，还得理解模拟器自身是怎么工作的。

这对我很有帮助，因为我现在想学 gem5 的动机，不只是“再跑一个程序”，而是希望未来围绕 workload 和微结构行为建立更稳定的观察方法。所以目前我更愿意把 gem5 写成“正在学习的方法工具”，而不是已经成熟掌握的工作流。

== 为什么我不把它们当成替代关系

现在这个划分对我最有帮助：

- `NEMU` 用来建立全系统行为的基线直觉
- `NPC` 用来直接面对自己的核和 handoff 路径是否真的正确
- `gem5` 用来逐步进入 workload 观察和微结构研究的方法空间

这套分工还在继续调整，但已经比把它们统称为“几种 RISC-V 模拟工具”更有用得多。

#series-navbar("zh", nav)
