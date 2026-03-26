#import "../index.typ": template, tufted
#import "@preview/lilaq:0.6.0" as lq
#show: template.with(
  locale: "en",
  route: "blog/2025-10-30-normal-distribution/",
  title: "The Normal Distribution",
)

= The Normal Distribution

The normal distribution, often called the Gaussian distribution or bell curve, is one of the most fundamental ideas in statistics and probability theory @degroot2012probability. Its characteristic symmetric curve appears throughout nature and human activity, from heights and test scores to measurement errors and biological variation.

== Key Properties

The normal distribution is completely described by two parameters: the mean ($mu$) and the standard deviation ($sigma$) @rice2006mathematical. The mean determines the center of the distribution, while the standard deviation controls its spread. Approximately 68% of values fall within one standard deviation of the mean, 95% within two, and 99.7% within three — the familiar empirical rule.

The probability density function is:

$ f(x) = 1/(sigma sqrt(2pi)) e^(-(x-mu)^2/(2sigma^2)) $

This formula, developed by Gauss in his astronomical work @gauss1809theoria, became foundational to modern statistics @stigler1982gauss.

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

  figure(caption: [Normal distribution], diagram)
}

== Why It Matters

The importance of the normal distribution comes largely from the Central Limit Theorem,#footnote[The Central Limit Theorem requires the summed random variables to be independent, identically distributed, and to have finite variance.] which says that sums of many independent random variables tend toward a normal distribution regardless of the original distribution. That helps explain why the bell curve appears so often in real data.

In practice, the normal distribution supports:

- statistical inference and hypothesis testing
- quality control in manufacturing
- risk assessment in finance
- modeling of natural measurements

== Real-World Applications

Scientists use normal distributions to model everything from IQ scores to particle velocities in gases. Engineers rely on them for reliability analysis and signal processing. Financial analysts use them in portfolio theory and option pricing, even though real market returns often deviate from normality.#footnote[Financial returns frequently show fat tails and skewness, which means extreme events are more common than the normal distribution predicts.]

Understanding the normal distribution provides a foundation for statistical thinking and data analysis, making it a practical tool for researchers, analysts, and decision-makers across many fields.

#bibliography("refs.bib")
