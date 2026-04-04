#import "../index.typ": template, tufted
#show: template.with(locale: "en", route: "search/", title: "Search")

= Search Results

#html.p(class: "search-page__intro")[
  Enter keywords in the top search box to explore results across the whole site.
]

#html.div(id: "search-results", class: "search-page__results")[
  #html.p(class: "search-page__status")[Search is loading...]
]
