#import "../index.typ": template, tufted
#show: template.with(locale: "zh", route: "docs/bring-up-checklist/", title: "Bring-up 检查清单参考")

= Bring-up 检查清单参考

#tufted.margin-note[
  一页可快速扫读的 \
  bring-up 参考清单
]

这一页就是给调试时快速扫的，不走完整叙述。卡住的时候先看这些问题，确认自己没有跳过最基本的边界。

== 特权级前提

- 当前阶段由哪个 privilege mode 控制？
- 下一次 trap 或 exception 预期落到哪一层？
- 如果要返回，代码默认走的是哪条 `xRET` 路径？

== firmware handoff

- firmware 真的是为当前 payload 和 device tree 构建的吗？
- payload 放置位置和 offset 假设是否仍与现在的镜像布局一致？
- 有没有一个清晰的 handoff 点可以确认或插桩？

== memory map 与设备树

- firmware、checkpoint 工具或 initramfs 打包过程分别预留了哪些地址范围？
- 当前 device tree 描述的平台信息，和实际启动目标是否一致？
- 如果多层共享同一片内存区域，谁先默认拥有它？

== 最早能看到的信号

- 最早的一条 console 输出
- 最早一个可信的 trap 落点
- NEMU 和 NPC 首次出现分歧的位置
- 日志开始沉默的第一个阶段

== 低成本调试提示

- 有没有什么可以先在不重构整条路径的前提下验证？
- 哪一层最适合先拿已知基线做对比？
- 现在缺的是信号，还是 transition 本身就没有发生？
