#import "../index.typ": template, tufted
#show: template.with(locale: "zh", route: "search/", title: "搜索")

= 搜索结果

#html.p(class: "search-page__intro")[
  在顶部搜索框中输入关键词，即可查看全站结果。
]

#html.div(id: "search-results", class: "search-page__results")[
  #html.p(class: "search-page__status")[搜索正在加载……]
]
