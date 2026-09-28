#import "../index.typ": template, tufted
#show: template.with(
  locale: "zh",
  route: "blog/lightsss/",
  title: "LightSSS 在解决什么问题",
)

= LightSSS 在解决什么问题

#tufted.margin-note[
  参考链接 \
  #link("https://docs.xiangshan.cc/zh-cn/latest/tools/lightsss/")[香山 LightSSS 文档] \
  #link("https://docs.xiangshan.cc/zh-cn/latest/tools/difftest/")[DiffTest 文档]
]

#tufted.margin-note[
  #image("imgs/lightsss-window.svg")
  调试长仿真时，麻烦的常常不是发现失败，而是重新拿到失败前后那一点波形。
]

长仿真跑到一半挂了，想看失败前后那一点波形，得从很早的位置重新跑一遍。LightSSS 就是冲着这个重跑成本来的。

== 普通 snapshot 差在哪

调试时一般不需要完整过程的波形，要的就是错误发生点前后那一小段窗口。传统 snapshot 有用，但文档自己指出了两个限制：

- 保存的往往主要是 RTL 状态，而不是整个仿真上下文
- 电路规模一大，状态文件的存储开销会明显上升

存快照本身不难，难的是存了之后能少跑几次冗长的重放。

== 用 `fork` 做进程快照

LightSSS 存的是进程快照，不是状态文件。主仿真进程会周期性地 `fork` 子进程，子进程阻塞等待信号，相当于保留了父进程在某个时间点的仿真状态。等父进程真正出错时，再唤醒离错误点最近的那个子进程，去导出波形或 debug 信息。

它在意的是离错误点足够近，状态归档完不完整反而无所谓。

#figure(
  image("imgs/fork-snapshot-loop.svg"),
  caption: [一个简化视图：长期运行的父进程、被挂起的子进程快照，以及失败点附近那段真正要看的调试窗口],
)

== 对长时间调试意味着什么

DiffTest 文档反复强调的也是仿真和通信成本。长仿真本来就贵，失败之后再把整段历史重跑一遍，等于把这笔成本付了两次。

LightSSS 干的就是省掉第二次：用 `fork` 把几个可能用得上的时间点先留住，失败了就回到离失败最近的那个点导出信息，不用从头再来。
