#import "../index.typ": template, tufted
#import "@preview/lilaq:0.6.0" as lq
#show: template.with(
  locale: "zh",
  route: "blog/2025-10-30-normal-distribution/",
  title: "正态分布",
)

= 正态分布

正态分布，也常被称为高斯分布或钟形曲线，是统计学与概率论中最基础的概念之一 @degroot2012probability。它那条对称、平滑的曲线在自然界和人类活动中都十分常见，从身高、考试成绩，到测量误差和生物差异，都经常会呈现出这种形态。

== 核心性质

正态分布由两个参数完全决定：均值 ($mu$) 和标准差 ($sigma$) @rice2006mathematical。均值决定分布的中心位置，标准差决定曲线展开的宽度。大约 68% 的数据会落在均值左右一个标准差内，95% 落在两个标准差内，99.7% 落在三个标准差内，这就是熟悉的经验法则。

它的概率密度函数为：

$ f(x) = 1/(sigma sqrt(2pi)) e^(-(x-mu)^2/(2sigma^2)) $

这个公式最初由 Gauss 在天文学研究中系统化 @gauss1809theoria，后来成为现代统计学的基础之一 @stigler1982gauss。

#{
  let diagram = html.frame(lq.diagram(
    xaxis: (subticks: none),
    yaxis: (subticks: none),
    lq.bar(
      range(-7, 8).map(x => x / 2.0),
      range(-7, 8).map(x => {
        let z = x / 2.0
        calc.exp(-z * z / 2) / calc.sqrt(2 * calc.pi)
      }),
      fill: blue.lighten(50%),
    ),
  ))

  figure(caption: [正态分布], diagram)
}

== 为什么它重要

正态分布的重要性很大程度上来自中心极限定理。#footnote[中心极限定理要求被相加的随机变量彼此独立、同分布，并且具有有限方差。] 这个定理告诉我们：无论原始分布是什么样，许多独立随机变量的和都会逐渐趋近正态分布。这也解释了为什么钟形曲线会在现实数据中反复出现。

在实践中，正态分布支撑着很多经典任务：

- 统计推断与假设检验
- 制造业中的质量控制
- 金融风险评估
- 自然测量数据建模

== 现实中的应用

科学家会用正态分布描述从智商分数到气体分子速度的各种现象。工程师在可靠性分析和信号处理中经常依赖它。金融分析师也会在投资组合理论和期权定价中使用它，尽管真实市场收益率往往并不严格服从正态分布。#footnote[金融收益率常常表现出“肥尾”和偏度，这意味着极端事件发生的概率比正态分布预测的更高。]

理解正态分布，会为统计思维和数据分析打下基础，因此它几乎是研究者、分析师和决策者都绕不开的一种工具。

#bibliography("refs.bib")
