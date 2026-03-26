#import "../index.typ": template, tufted
#show: template.with(locale: "zh", route: "cv/", title: "简历")
#import "@preview/citegeist:0.2.2": load-bibliography

= Edward R. Tufte

#tufted.margin-note[
  统计学家、艺术家、荣休教授 \
  Website: #link("https://www.edwardtufte.com")[edwardtufte.com] \
  Email: #link("mailto:noreply@edwardtufte.com")[`noreply@edwardtufte.com`]
]

长期研究统计证据与信息可视化中的分析性设计，将统计学、图形设计和认知科学结合起来，以提升定量信息的表达效果。

== 工作经历

- *1983--Present*: Graphics Press 创始人兼出版人，专注于信息设计与数据可视化的独立出版社。
- *1977--1999*: Yale University 荣休教授，任职于政治学、统计学与计算机科学等院系。
- *1967--1977*: Princeton University 教师，隶属 Woodrow Wilson School of Public and International Affairs。

== 艺术作品

#tufted.margin-note[
  #image("escaping-flatland.webp")
]

#tufted.margin-note[
  向 Edward R. Tufte 的大型不锈钢雕塑 _Escaping Flatland_ 致意
]

创办位于康涅狄格州 Woodbury 的 Hogpen Hill Farms 雕塑园，占地 234 英亩。代表性大型作品包括 _Larkin's Twig_ 与 _Escaping Flatland_ 系列，并曾在 Aldrich Contemporary Art Museum 展出。

== 研究贡献

提出 sparkline 这一可在正文中嵌入高分辨率数据图形的方法，并将 data-ink ratio 概念发展为衡量图形表达效率的定量标准。

== 著作

#{
  let bib = load-bibliography(read("books.bib"))
  for item in bib.values().rev() [
    #let data = item.fields
    - #strong(data.year): #emph(data.title)
  ]
}

== 论文

#{
  let bib = load-bibliography(read("papers.bib"))
  for item in bib.values().rev() [
    #let data = item.fields
    - #data.author, "#data.title," #emph(data.journal), #data.year. DOI: #link(data.url)[#data.doi]
  ]
}

== 教育经历

- PhD in Political Science: Yale University (1968)。
- MS in Statistics: Stanford University。
- BS in Statistics: Stanford University。
