#let series-registry = (
  (
    id: "getting-started",
    title: "Getting Started",
    summary: "Set up the bilingual template, learn the folder layout, and finish with a publishable GitHub Pages build.",
    route: "docs/getting-started/",
    thumbnail: "starter-series.svg",
    begin-route: "docs/01-quick-start/",
    chapters: (
      (
        id: "quick-start",
        title: "Quick Start",
        summary: "Create the site from the template, build it locally, and preview the generated output.",
        route: "docs/01-quick-start/",
        order: 1,
      ),
      (
        id: "configuration",
        title: "Configuration",
        summary: "Replace shared assets, understand the localized content tree, and map the site shell to your own content.",
        route: "docs/02-configuration/",
        order: 2,
      ),
      (
        id: "styling",
        title: "Styling",
        summary: "Tune theme colors, link treatment, spacing, and the CSS override points that shape the site.",
        route: "docs/03-styling/",
        order: 3,
      ),
      (
        id: "deploy",
        title: "Deployment",
        summary: "Prepare the static build for GitHub Pages and understand the deployment path end to end.",
        route: "docs/04-deploy/",
        order: 4,
      ),
    ),
  ),
)

#let reference-registry = (
  (
    id: "embedding-markdown",
    title: "Embedding Markdown",
    summary: "Mix Typst pages with Markdown content when you want article convenience without giving up localized template control.",
    route: "docs/embedding-markdown/",
    thumbnail: "sandbox-project.svg",
    label: "Extension",
  ),
)
