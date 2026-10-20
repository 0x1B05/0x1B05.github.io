#import "../index.typ": *
#import "./registry.typ": blog-posts
#show: template.with(locale: "en", route: "blog/", title: "Blog")

= Blog

// TODO: one-sentence intro for this section.

#html.div(class: "content-grid")[
  // Add posts to registry.typ, newest first.
  #for post in blog-posts [
    #content-card(
      locale-url("en", route: post.route),
      post.thumbnail,
      post.title,
      post.summary,
    )
  ]
]
