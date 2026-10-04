# AGENTS.md

## Project Overview

This repository is the personal website `0x1B05.github.io` — a bilingual (English / Chinese) static site with notes, docs, blog posts, and an about page, published at `https://0x1B05.github.io/`.

The site is written in **Typst** and compiled to static HTML with `typst compile --features html --format html`. There is no traditional application runtime: the "source code" is Typst markup plus a small set of hand-written CSS/JS assets, and the build output (`_site/`) is deployed directly to GitHub Pages. Because this is a GitHub *user-site* repository, the site lives at the domain root — all internal URLs are written absolute against `/`, never against a project subpath.

### Requirements

- `typst >= 0.15.0` (CI pins `0.15.0`)
- `make`
- `node` + `npm` (only for Pagefind search indexing; the single npm dependency is `pagefind` in `package.json`)
- `python3` (only for the local preview server)

## Repository Layout

- `config.typ` — the shared site shell. Exports `site-web`/`template` (the page template that emits `<html>`, header/nav, search box, language switcher, theme switcher, footer), URL helpers (`site-url`, `locale-url`, `normalize-route`), localized copy tables (`locale-copy`), and reusable components (callouts like `note`/`tip`/`warning`, `doc-toc`, `content-card`, series navigation helpers `series-context`/`series-navbar`/`series-begin`). Shared shell changes usually belong here or in `assets/site.css`.
- `content/` — all pages, mirrored per locale: `content/en/…` and `content/zh/…` are parallel trees, plus the language-gateway landing page `content/index.typ`. Every page is an `index.typ` inside a directory; page-local images live in an `imgs/` subdirectory next to it.
- `assets/` — CSS and JS copied verbatim to `_site/assets/`:
  - `site.css` — the only stylesheet (theme tokens via `light-dark()`, layout, component styles); there is no external CSS dependency.
  - `fonts/et-book/` — self-hosted ET Book serif (WOFF + MIT LICENSE) declared in `site.css`.
  - `theme-bootstrap.js` — runs in `<head>` before first paint to apply the stored/system theme.
  - `theme-switcher.js`, `language-switcher.js`, `language-redirect.js`, `dropdown.js` — header controls and root-gateway redirect; `dropdown.js` drives every dropdown menu (language, theme, search) via `data-dropdown` attributes; preferences are persisted in `localStorage` under keys like `site-theme`.
  - `search.js` — client-side search UI backed by the Pagefind index at `/pagefind/`.
  - Logos (`logo-light.svg`, `logo-dark.svg`), `profile.png`. Card thumbnails go in `assets/content-thumbnails/` (create it when you add the first card).
- `Makefile` — the entire build pipeline (see below).
- `.github/workflows/deploy.yml` — CI/CD to GitHub Pages.
- `_site/` — generated build output; never edit by hand. `.deps/` (typst-generated Make depfiles), `node_modules/`, `.reference/`, and `plans/` are also local-only and gitignored.

## Content model

- Pages apply the shell with `#show: template.with(locale: "en" | "zh", route: "<path>/", title: "…")`. Routes are directory-style, must match the page's directory, and must end with a trailing slash.
- Content directories and file slugs are kebab-case; blog post directories are named by topic slug (no date prefix).
- English and Chinese trees must stay structurally mirrored; the header language switcher navigates to the *same route* in the opposite locale. (Current exception: `docs/arch-notes/` exists only in the en tree, since the source notes are English.)
- Files the Makefile excludes from page compilation (they are imports/metadata, not pages): `series.typ`, `registry.typ`, and any file under a path component starting with `_` (`content/**/_*.typ` are shared Typst includes).

## Writing Content

### Anatomy of a page

Every page is an `index.typ` in its own directory, with images in an `imgs/` subdirectory next to it:

```typst
#import "../index.typ": template
#show: template.with(
  locale: "en",          // or "zh"
  route: "blog/<slug>/", // must match the directory, trailing slash
  title: "<page title>",
)

= <page title>

Content goes here.
```

The relative import depth varies (`../index.typ`, `../../index.typ`, …) because each locale root wildcard-re-exports the shell (`#import "../../config.typ": *`) and each section landing page wildcard-re-exports the locale root, so importing from the nearest ancestor `index.typ` gives every page the full component set with a short, uniform path. (`--deps` records the transitive closure of files actually read, so the build sees `config.typ` regardless of the chain's shape; the chain exists purely for import ergonomics, not for build visibility.)

### Adding a blog post

1. Create `content/<locale>/blog/<slug>/index.typ` using the page skeleton above (route `blog/<slug>/`). Put images in `content/<locale>/blog/<slug>/imgs/`.
2. Add a card for it at the top of the grid in `content/<locale>/blog/index.typ` (newest first) — a commented example lives in that file.
3. Mirror the same directory and card in the other locale.

### Adding a docs series

A **series** is a directory `content/<locale>/docs/<series-slug>/` containing:

1. `series.typ` — the series metadata (excluded from page compilation):

```typst
#let my-series = (
  id: "my-series",
  title: "<series title>",
  summary: "<one-line summary for the docs landing card>",
  route: "docs/my-series/",
  thumbnail: "<thumbnail.svg>",
  begin-route: "docs/my-series/01-first/",
  chapters: (
    (
      id: "first",
      title: "<chapter title>",
      summary: "<one-line summary>",
      route: "docs/my-series/01-first/",
      order: 1,
    ),
    // more chapters, in reading order
  ),
)
```

2. Chapter pages `NN-<slug>/index.typ` (numbered prefixes keep reading order):

```typst
#import "../../index.typ": *
#import "../series.typ": my-series
#show: series-chapter.with(my-series, route: "docs/my-series/01-first/", title: "<chapter title>")

…content…
```

`series-chapter` applies the page template and renders the chapter title, the previous/home/next navbar, and the on-page TOC around the body (navbar again at the bottom), so the route and title are each written exactly once. `series-context` computes the navbar links from the `chapters` list, so the route given here must match the chapter's `route` in `series.typ` exactly. Chapters that need extra imports (diagram helpers, packages) simply add their own `#import` lines.

3. A series landing page `index.typ` in the series directory, which renders the chapter list from the same metadata:

```typst
#import "../index.typ": template, content-card, locale-url, series-begin, doc-toc
#import "./series.typ": my-series
#show: template.with(locale: "en", route: "docs/my-series/", title: "<series title>")

#let series = my-series

= <series title>

#doc-toc()

<introduction>

== Chapters

#html.div(class: "content-grid")[
  #for chapter in series.chapters [
    #content-card(
      locale-url("en", route: chapter.route),
      "<thumbnail.svg>",
      chapter.title,
      chapter.summary,
      label: "Chapter " + str(chapter.order),
    )
  ]
]

#series-begin("en", series.begin-route)
```

4. Register the series in `content/<locale>/docs/registry.typ`: import `series.typ` and add it to `series-registry`. The docs landing page renders its cards from this registry.

### Adding a standalone docs note

1. Create `content/<locale>/docs/<slug>/index.typ` as a plain page (the `doc-toc` and callout re-exports can be imported from `../index.typ`).
2. Append an entry to `note-registry` in `content/<locale>/docs/registry.typ` — a commented example lives in that file.

### Components and boxes

Callouts (`note`, `tip`, `example`, `definition`, `warning`) render as titled boxes; the default title comes from `locale-copy` in `config.typ`, follows the page language automatically, and can be overridden with `title:`:

```typst
#note[Something worth remembering.]
#warning(title: "Do not do this")[The explanation.]
```

All components and the callout titles follow the page language automatically: `site-web` sets `text(lang: …)`, and locale-aware components (`callout-kind`, `doc-toc`) read it back through a `context` block at layout time, so no `locale:` argument is threaded through pages. Every page imports components from the nearest ancestor `index.typ` (blog posts use `../index.typ`, docs chapters `../../index.typ`, and so on); both chain levels are wildcard re-exports, so a new shared component only needs to be defined once in `config.typ`. Importing from `config.typ` directly is only needed when building new kinds of pages. (One edge case: a local `set text(lang: "en")` scope, like the bibliography block in the zh about page, flips the automatic locale inside that scope.)

Other building blocks:

- `#doc-toc()` — table of contents for the current page, used near the top of docs chapters and series landing pages (the "Contents"/"目录" title follows the page language).
- `#margin-note[…]` — small in-flow aside (also used for "further reading" link blocks). Numbered notes written as `#sidenote[…]` (`#footnote[…]` also works) render as superscript markers that reveal their body in a hover/focus popup, and figure captions render like a paper — above tables, below images and diagrams — the site does not use page-margin notes; the layout is a single centered column.
- `#bibliography("refs.bib", title: none)` — paper citations; keep the .bib file next to the page, cite with `@key`, and give the section its own `==` heading (`title: none` suppresses the built-in one, which renders one level too large). On zh pages, wrap it in `#{ set text(lang: "en"); bibliography(…) }` so English entries keep English IEEE connectors instead of zh-localized ones.
- `#figure(image("imgs/<file>.svg"), caption: […])` — captioned figure. `#figure(table(…), caption: […])` gets a numbered "Table N" caption above the table; image/diagram captions stay below.
- `#figure(table(…), caption: […], numbering: none)` — unnumbered caption above the table, for worked-example table names (e.g. "Register File (RF)") that should not consume a "Table N" number; the caption renders as the body alone, without supplement or number, and unnumbered figures do not step the counter.
- `#table-pair(left, right)` — two tables side by side (stacked on narrow screens). Each side is usually its own unnumbered table figure; for a shared group title, wrap the pair itself in `#figure(table-pair(…), caption: […], kind: table, numbering: none)`.
- `#figure(html.frame(<cetz/finite call>), caption: […])` — cetz/finite diagrams; the HTML export drops them unless wrapped in `html.frame`. Shared diagram sources live in a series-local `_diagrams/` directory (see `docs/arch-notes/`). Also note that `#grid` and `#align` contents are dropped by the HTML export and must be unwrapped. Diagrams are always drawn for a light page; in dark mode `site.css` inverts `figure > svg`/`figure > img` with `filter: invert(…) hue-rotate(180deg)`, which flips the canvas dark while keeping annotation colors recognizable — so keep drawing diagrams in the light palette only.
- `#content-card(href, thumbnail, title, description, label: …)` — landing-page card; the thumbnail is referenced by bare filename and loaded from `assets/content-thumbnails/`.
- `#home-link(href, title, description, eyebrow: …)` — home-page link card; with `eyebrow:` it doubles as a language-gateway entry. `#home-links(locale)` renders the three standard home cards from `locale-copy` (card labels stay in sync with the header navigation).
- `#docs-landing(locale, series-registry, note-registry)` — the whole docs landing body (series + notes card grids); empty sections are omitted, and when both registries are empty a muted `docs_empty` fallback line renders instead.
- `#series-chapter(series, route: …, title: …)` — the whole chapter page wrapper (used via `#show: series-chapter.with(…)`); emits the title, navbar, and TOC around the body so chapters don't repeat the boilerplate.
- `#series-navbar(locale, nav)` — previous/home/next navigation; emitted by `series-chapter`, so chapters no longer call it directly.
- `#series-begin(locale, route)` — "start reading" link, used at the bottom of series landing pages.
- `#quote(block: true, attribution: […])[…]` — block quote; a template show rule keeps the attribution inside the quote as a small footer line instead of a detached paragraph.
- Standard Typst markup works as usual: `= headings`, `- lists`, `` `code` ``, fenced code blocks, `#link(url)[…]`, `#image("imgs/…")`.

### Adding a new callout kind

The five kinds share one implementation (`callout-kind` in `config.typ`), so a new kind (say `important`) takes two small edits:

1. `config.typ` — add a one-line wrapper next to the existing ones:
   ```typst
   #let important(body, title: auto, locale: none) = callout-kind("important", body, title: title, locale: locale)
   ```
2. `config.typ` — add the default title to both `locale-copy` tables (the field name must be `callout_` + the kind name): `callout_important: "重要",` in the zh table and `callout_important: "Important",` in the en table.
3. `assets/site.css` — add one accent line next to the other kinds (light and dark values in a single `light-dark()`; the tinted background is derived from the accent via `color-mix`, so nothing else is needed):
   ```css
   .callout--important { --callout-accent: light-dark(#3a7ca5, #81a1c1); }
   ```

The default title follows the page language automatically (via `context text.lang`), so no per-locale binding step is needed.

## Build and Test Commands

Install JS dependencies once (provides `./node_modules/.bin/pagefind`):

```sh
npm install
```

Build the full site into `_site/` (compiles every page, copies `assets/`, builds the Pagefind search index):

```sh
make html
```

Preview locally at `http://localhost:8000` (override with `make preview PORT=9000`):

```sh
make preview
```

Clean build for GitHub Pages (also creates `_site/.nojekyll`):

```sh
make pages        # alias: make github-pages
```

Clean generated output:

```sh
make clean
```

### How the Makefile works

- `TYP_FILES` are found with `find content -name '*.typ'` minus the metadata files above; each `content/<path>.typ` maps to `_site/<path>.html` via `typst compile --root .. --features html --format html`.
- Rebuild dependencies are exact, not convention-based: each page compiles with `typst compile --deps .deps/<path>.d --deps-format make`, which records every file the compilation actually reads (`config.typ`, imports, `series.typ`, images, bibliographies, package files) as a Make rule; the Makefile then `-include`s those `.d` files. Missing `.d` files on a fresh build are expected (compiling generates them); if a stale `.d` ever references a deleted file, run `make clean`.
- The `search-index` target runs Pagefind with `--force-language en` into `_site/pagefind/` and fails with a clear message if `node_modules/.bin/pagefind` is missing.

## Code Style and Conventions

- Typst: use the `html.*` element API (`html.div`, `html.elem("svg", attrs: …)`, etc.) for markup; keep localized strings out of content files — extend the `locale-copy` table in `config.typ` instead. Helper names use kebab-case (`series-navbar`, `content-card`); CSS classes use BEM-ish names (`theme-switcher__option--dark`).
- JavaScript: plain ES5-compatible IIFEs, no imports/build step, `const`-heavy, defensive `try/catch` around `localStorage` and `matchMedia`. `theme-bootstrap.js` must stay dependency-free and synchronous because it runs before first paint.
- Keep prose and comments in the same bilingual spirit as the rest of the repo: shell/config code and docs are English; page content exists in both `en` and `zh`.

## Deployment

`.github/workflows/deploy.yml` runs on every push to `main` (and manually): checkout → Node 24 → `npm ci` → Typst `0.15.0` via `typst-community/setup-typst` → `make pages` → upload `_site/` as a Pages artifact → deploy to GitHub Pages. There is no separate deploy command to run locally; `make pages` reproduces exactly what CI builds.

## Security Considerations

- No secrets or credentials are stored in the repo; the only npm dependency is Pagefind, pinned via `package-lock.json` and installed with `npm ci` in CI.
- Generated HTML loads no third-party resources at all: CSS, fonts, and JS are self-hosted under `assets/` (ET Book is vendored in `assets/fonts/et-book/` under MIT).
- Never edit `_site/` directly and never commit it (gitignored); treat `.deps/`, `node_modules/`, `.reference/`, and `plans/` as local-only.
