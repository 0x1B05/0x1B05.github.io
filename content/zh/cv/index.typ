#import "../index.typ": margin-note, sidenote, template
#show: template.with(locale: "zh", route: "cv/", title: "简历")

= 0x1B05

#margin-note[
  上海科技大学电子信息硕士生 \
  一生一芯课题组 \
  关注体系结构、系统与性能问题
]

我是上海科技大学电子信息硕士生，目前在一生一芯课题组#sidenote[一个开放的芯片设计教学项目：每位学员从零设计一颗 RISC-V 处理器，并在上面完成 Linux 启动。]。我的基础主要在 CPU 和数字系统这一块，最近的时间大多花在 Linux bring-up、模拟器、香山昆明湖 `v2`#sidenote[香山是开源的高性能 RISC-V 处理器项目，昆明湖是其一代微架构。] 的 review 和验证上。

#quote(block: true, attribution: [Hennessy 与 Patterson，《计算机体系结构：量化研究方法》])[
  加速大概率事件。
]

== 基本情况

- 上海科技大学电子信息硕士生。
- 一生一芯课题组成员。
- 已完成一生一芯 B 线训练。
- 现在主要补体系结构、系统软件和性能分析之间的连接（见 @technical-interests）。

== 当前工作 <current-work>

最近这段时间，我一边继续做系统 bring-up 和模拟器相关的学习，一边跟香山昆明湖 `v2` 的 review 和验证。

- 我最近在做香山昆明湖 `v2` @xiangshan-micro22 相关的 review 和验证。
- 我也还在尝试让 `NEMU` 和 `NPC` 的核心启动 Linux。
- 这里的 `NEMU` 是一生一芯训练体系中常用的教学型全系统模拟器。
- `NPC` 是我自己实现和维护的 `RISC-V64` @riscv-isa-2011 核项目，所以 bring-up 和调试会直接落在硬件与软件的边界上。
- 我也在继续学习 `gem5` @gem5-2011，主要想把 workload 观察和微结构分析这件事做得更成体系。

== 背景与训练

- 我现在的基础主要还是 CPU 与数字系统入门，包括对流水线、cache、分支预测等概念的初步理解。
- 一生一芯 B 线给了我一个比较务实的起点，让我能在核、工具链和系统层面继续往前做。
- 虽然我之前也接触过 `gem5`，但现在仍在把它整理成更稳定的分析工作流，而不是把它当成已经完全掌握的能力。
- 最近在香山昆明湖 `v2` 上的 review 和验证，也让我更具体地看到读代码、提问题和做验证是怎么连起来的。

== 技术兴趣 <technical-interests>

- CPU perf 与微结构性能分析
- workload characterization 与测量方法
- AI 芯片性能分析
- AI 系统性能优化

== 接下来

- 近阶段先继续做 @current-work 里那些 Linux bring-up、模拟器使用、调试过程，以及 CPU 类系统里的 review 和问题分析。
- 后面再逐步补 AI workload 与 accelerator performance。

== 参考文献

// English references read better in English IEEE format; scope the language
// switch to the bibliography so the rest of the page stays zh.
#{
  set text(lang: "en")
  bibliography("refs.bib", title: none)
}
