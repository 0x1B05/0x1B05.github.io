#import "../index.typ": *
#import "./registry.typ": series-registry, note-registry
#show: template.with(locale: "en", route: "docs/", title: "Docs")

= Docs

// TODO: one-sentence intro for this section. Series and short notes below are
// rendered from docs/registry.typ.

#docs-landing("en", series-registry, note-registry)
