#import "../../config.typ": *
#show: template.with(locale: "zh", route: "")

#html.div(class: "home-hero")[
  #html.div(class: "home-hero__copy")[

    // TODO: 一两句话介绍这个站点。

    == 关于我

    // TODO: 简短的个人简介。
  ]
  #html.div(class: "home-hero__profile")[
    #profile-image()
  ]
]

#home-links("zh")
