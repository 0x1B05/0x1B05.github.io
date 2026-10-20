#import "../index.typ": *
#import "./registry.typ": blog-posts
#show: template.with(locale: "zh", route: "blog/", title: "博客")

= 博客

// TODO: 一句话介绍这个栏目。

#html.div(class: "content-grid")[
  // 每篇文章加一张 content-card,新的放前面。
  #for post in blog-posts [
    #content-card(
      locale-url("zh", route: post.route),
      post.thumbnail,
      post.title,
      post.summary,
    )
  ]
]
