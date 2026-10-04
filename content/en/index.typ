#import "../../config.typ": *
#show: template.with(locale: "en", route: "")

#html.div(class: "home-hero")[
  #html.div(class: "home-hero__copy")[

    // TODO: one or two sentences about what this site is.

    == About Me

    // TODO: short bio.
  ]
  #html.div(class: "home-hero__profile")[
    #profile-image()
  ]
]

#home-links("en")
