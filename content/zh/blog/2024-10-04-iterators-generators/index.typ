#import "../index.typ": template, tufted
#show: template.with(
  locale: "zh",
  route: "blog/2024-10-04-iterators-generators/",
  title: "我理解的 LightSSS 在优化什么",
)

= 我理解的 LightSSS 在优化什么

#tufted.margin-note[
  参考链接 \
  #link("https://docs.xiangshan.cc/zh-cn/latest/tools/lightsss/")[香山 LightSSS 文档] \
  #link("https://docs.xiangshan.cc/zh-cn/latest/tools/difftest/")[DiffTest 文档]
]

#tufted.margin-note[
  #image("imgs/lightsss-window.svg")
  调试长仿真时，麻烦的常常不是发现失败，而是重新拿到失败前后那一点波形。
]

我第一次看 LightSSS 文档时，最直接的反应是：它不是在炫耀“我能保存 snapshot”，而是在处理长时间 RTL 调试里很烦的一件事。失败已经出现了，但为了看清失败前后那一点波形，又要从很早的位置重新跑一遍。

== 为什么普通 snapshot 叙事不够

LightSSS 文档先把问题讲得很实际：调试时并不需要完整过程的波形，更多时候只需要错误发生点前后那一小段窗口。传统 snapshot 功能当然有帮助，但文档也直接指出了两个限制：

- 保存的往往主要是 RTL 状态，而不是整个仿真上下文
- 电路规模一大，状态文件的存储开销会明显上升

所以问题不是单纯的“能不能存快照”，而是这种快照到底能不能少跑几次冗长的重放。

== `fork` 这个思路才是关键

文档给出的机制不是围绕“状态文件”展开，而是围绕“进程快照”展开。主仿真进程会周期性地 `fork` 子进程，子进程阻塞等待信号，相当于保留了父进程在某个时间点的仿真状态。等父进程真正出错时，再唤醒离错误点最近的那个子进程，去导出波形或 debug 信息。

这套设计关心的是离错误点足够近，而不是把状态归档这件事做得多完整。

#figure(
  image("imgs/fork-snapshot-loop.svg"),
  caption: [一个简化视图：长期运行的父进程、被挂起的子进程快照，以及失败点附近真正有价值的调试窗口],
)

== 为什么这对长时间 RTL 调试很有价值

DiffTest 文档一直在讲仿真和通信成本，所以我会把 LightSSS 放到同一类工程问题里看：长仿真已经够贵了，失败之后最好别再把整段历史重新付一遍。

我现在会把它理解成一个调试周转时间工具。它用 `fork` 把几个可能有用的时间点先留住，等失败出现时，再回到离失败最近的位置导出信息。

== 先记下来的几个判断

- LightSSS 更像一个调试效率工具，而不只是泛化的 snapshot 功能。
- `fork` 这套思路的价值在于把错误附近那一小段状态保留下来。
- 就算不看具体实现，文档本身也已经很明确地告诉我，它想解决的是长仿真调试里的周转时间问题。
