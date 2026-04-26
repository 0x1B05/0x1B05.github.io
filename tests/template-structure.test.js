const fs = require("node:fs");
const path = require("node:path");
const { assert } = require("./helpers/assert");

const repoRoot = path.join(__dirname, "..");
const contentRoot = path.join(repoRoot, "content");
const config = fs.readFileSync(path.join(repoRoot, "config.typ"), "utf8");
const rootIndex = fs.readFileSync(path.join(contentRoot, "index.typ"), "utf8");
const enIndex = fs.readFileSync(path.join(contentRoot, "en", "index.typ"), "utf8");
const zhIndex = fs.readFileSync(path.join(contentRoot, "zh", "index.typ"), "utf8");
const enSearchPage = fs.readFileSync(
  path.join(contentRoot, "en", "search", "index.typ"),
  "utf8",
);
const zhSearchPage = fs.readFileSync(
  path.join(contentRoot, "zh", "search", "index.typ"),
  "utf8",
);

const requiredPaths = [
  path.join(contentRoot, "en", "docs", "index.typ"),
  path.join(contentRoot, "zh", "docs", "index.typ"),
  path.join(contentRoot, "en", "docs", "registry.typ"),
  path.join(contentRoot, "zh", "docs", "registry.typ"),
  path.join(contentRoot, "en", "blog", "index.typ"),
  path.join(contentRoot, "zh", "blog", "index.typ"),
  path.join(contentRoot, "en", "cv", "index.typ"),
  path.join(contentRoot, "zh", "cv", "index.typ"),
  path.join(contentRoot, "en", "search", "index.typ"),
  path.join(contentRoot, "zh", "search", "index.typ"),
];

assert(
  !config.includes('html.div(class: "site-frame")'),
  "config.typ should not wrap page content in an extra site-frame div",
);
assert(
  config.includes("#let language-switcher(") &&
    config.includes("#let language-switcher-entry("),
  "config.typ should define reusable language switcher helpers",
);
assert(
  config.includes("#let theme-switcher-option(") &&
    config.includes('html.elem("svg"'),
  "config.typ should define the shared theme-switcher helper and inline SVG icons",
);
assert(
  config.includes("#let site-search("),
  "config.typ should define a reusable site-search helper",
);
assert(
  rootIndex.includes("/en/") && rootIndex.includes("/zh/"),
  "root index should keep acting as a language gateway",
);
assert(
  enIndex.includes('#show: template.with(locale: "en"') &&
    zhIndex.includes('#show: template.with(locale: "zh"'),
  "localized home pages should pass their locale into the shared template wrapper",
);
assert(
  enSearchPage.includes('#show: template.with(locale: "en"') &&
    zhSearchPage.includes('#show: template.with(locale: "zh"'),
  "localized search pages should use the shared template wrapper in both locales",
);
assert(
  requiredPaths.every((filePath) => fs.existsSync(filePath)),
  "localized docs, blog, cv, and search entry pages should exist in both locales",
);
assert(
  !fs.existsSync(path.join(contentRoot, "docs")) &&
    !fs.existsSync(path.join(contentRoot, "blog")) &&
    !fs.existsSync(path.join(contentRoot, "cv")),
  "legacy top-level single-language content trees should stay removed",
);

console.log("PASS template structure keeps shared shell and localized content tree aligned");
