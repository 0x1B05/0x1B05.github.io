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
  最贵的往往不是知道错误已经发生，而是怎样尽快回到错误附近那段真正有调试价值的窗口。
]

我第一次看 LightSSS 文档时，最直接的感受是：它想优化的并不只是“保存一个 snapshot”这件事，而是长时间 RTL 调试里最痛的那段回放成本。真正昂贵的不是知道错误发生了，而是为了把错误附近那一小段信息重新拿回来，不得不把很长的仿真再跑一遍。

== 为什么普通 snapshot 叙事不够

LightSSS 文档先把问题讲得很实际：调试时并不需要完整过程的波形，更多时候只需要错误发生点前后那一小段窗口。传统 snapshot 功能当然有帮助，但文档也直接指出了两个限制：

- 保存的往往主要是 RTL 状态，而不是整个仿真上下文
- 电路规模一大，状态文件的存储开销会明显上升

这样一来，问题就不再只是“能不能存快照”，而是“什么样的快照方式，才真的能改善调试周转时间”。

== `fork` 这个思路才是关键

文档给出的机制不是围绕“状态文件”展开，而是围绕“进程快照”展开。主仿真进程会周期性地 `fork` 子进程，子进程阻塞等待信号，相当于保留了父进程在某个时间点的仿真状态。等父进程真正出错时，再唤醒离错误点最近的那个子进程，去导出波形或 debug 信息。

这就很说明问题了：它并不是在追求最一般意义上的状态归档，而是在追求“离错误点足够近，从而还能高效地把调试窗口拿回来”。

#figure(
  image("imgs/fork-snapshot-loop.svg"),
  caption: [一个简化视图：长期运行的父进程、被挂起的子进程快照，以及失败点附近真正有价值的调试窗口],
)

== 为什么这对长时间 RTL 调试很有价值

DiffTest 文档本身就一直在强调仿真和通信成本，因此我很容易把 LightSSS 看成同一类思路下的工具：不要把时间浪费在“把整段历史再支付一遍”上，而是尽量把恢复和观察集中在真正有价值的最后那一小段。

所以在我的理解里，LightSSS 优化的不是“快照”这个名词本身，而是失败点附近的调试回放效率。这很像体系结构实验室里常见的取舍：把机制收缩到真正浪费工程时间的那个位置上。

== 我现在的 takeaway

- LightSSS 更像一个调试效率工具，而不只是泛化的 snapshot 功能。
- `fork` 这套思路的价值在于把错误附近那一小段状态保留下来。
- 就算不看具体实现，文档本身也已经很明确地告诉我，它想解决的是长仿真调试里的周转时间问题。
