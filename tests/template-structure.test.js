const fs = require("node:fs");
const path = require("node:path");
const { assert } = require("./helpers/assert");

const config = fs.readFileSync(
  path.join(__dirname, "..", "config.typ"),
  "utf8",
);
const rootIndexPath = path.join(__dirname, "..", "content", "index.typ");
const enIndexPath = path.join(__dirname, "..", "content", "en", "index.typ");
const zhIndexPath = path.join(__dirname, "..", "content", "zh", "index.typ");
const enDocsIndexPath = path.join(__dirname, "..", "content", "en", "docs", "index.typ");
const zhDocsIndexPath = path.join(__dirname, "..", "content", "zh", "docs", "index.typ");
const enDocsRegistryPath = path.join(__dirname, "..", "content", "en", "docs", "registry.typ");
const zhDocsRegistryPath = path.join(__dirname, "..", "content", "zh", "docs", "registry.typ");
const enDocsSeriesPath = path.join(
  __dirname,
  "..",
  "content",
  "en",
  "docs",
  "linux-bringup",
  "series.typ",
);
const zhDocsSeriesPath = path.join(
  __dirname,
  "..",
  "content",
  "zh",
  "docs",
  "linux-bringup",
  "series.typ",
);
const enSeriesHomePath = path.join(
  __dirname,
  "..",
  "content",
  "en",
  "docs",
  "linux-bringup",
  "index.typ",
);
const zhSeriesHomePath = path.join(
  __dirname,
  "..",
  "content",
  "zh",
  "docs",
  "linux-bringup",
  "index.typ",
);
const enQuickStartDocPath = path.join(
  __dirname,
  "..",
  "content",
  "en",
  "docs",
  "linux-bringup",
  "01-quick-start",
  "index.typ",
);
const zhQuickStartDocPath = path.join(
  __dirname,
  "..",
  "content",
  "zh",
  "docs",
  "linux-bringup",
  "01-quick-start",
  "index.typ",
);
const enConfigurationDocPath = path.join(
  __dirname,
  "..",
  "content",
  "en",
  "docs",
  "linux-bringup",
  "02-configuration",
  "index.typ",
);
const zhConfigurationDocPath = path.join(
  __dirname,
  "..",
  "content",
  "zh",
  "docs",
  "linux-bringup",
  "02-configuration",
  "index.typ",
);
const enStylingDocPath = path.join(
  __dirname,
  "..",
  "content",
  "en",
  "docs",
  "linux-bringup",
  "03-styling",
  "index.typ",
);
const zhStylingDocPath = path.join(
  __dirname,
  "..",
  "content",
  "zh",
  "docs",
  "linux-bringup",
  "03-styling",
  "index.typ",
);
const legacyBlogDirPath = path.join(__dirname, "..", "content", "blog");
const legacyCvDirPath = path.join(__dirname, "..", "content", "cv");
const legacyDocsDirPath = path.join(__dirname, "..", "content", "docs");
const enDeployDocPath = path.join(
  __dirname,
  "..",
  "content",
  "en",
  "docs",
  "linux-bringup",
  "04-deploy",
  "index.typ",
);
const zhDeployDocPath = path.join(
  __dirname,
  "..",
  "content",
  "zh",
  "docs",
  "linux-bringup",
  "04-deploy",
  "index.typ",
);
const enLegacySeriesHomePath = path.join(
  __dirname,
  "..",
  "content",
  "en",
  "docs",
  "getting-started",
  "index.typ",
);
const zhLegacySeriesHomePath = path.join(
  __dirname,
  "..",
  "content",
  "zh",
  "docs",
  "getting-started",
  "index.typ",
);
const enLegacyReferencePath = path.join(
  __dirname,
  "..",
  "content",
  "en",
  "docs",
  "embedding-markdown",
);
const zhLegacyReferencePath = path.join(
  __dirname,
  "..",
  "content",
  "zh",
  "docs",
  "embedding-markdown",
);
const enReferenceDocPath = path.join(
  __dirname,
  "..",
  "content",
  "en",
  "docs",
  "bring-up-checklist",
  "index.typ",
);
const zhReferenceDocPath = path.join(
  __dirname,
  "..",
  "content",
  "zh",
  "docs",
  "bring-up-checklist",
  "index.typ",
);
const rootIndex = fs.existsSync(rootIndexPath)
  ? fs.readFileSync(rootIndexPath, "utf8")
  : "";
const enIndex = fs.existsSync(enIndexPath) ? fs.readFileSync(enIndexPath, "utf8") : "";
const zhIndex = fs.existsSync(zhIndexPath) ? fs.readFileSync(zhIndexPath, "utf8") : "";
const enDocsIndex = fs.existsSync(enDocsIndexPath)
  ? fs.readFileSync(enDocsIndexPath, "utf8")
  : "";
const zhDocsIndex = fs.existsSync(zhDocsIndexPath)
  ? fs.readFileSync(zhDocsIndexPath, "utf8")
  : "";
const enDocsSeries = fs.existsSync(enDocsSeriesPath)
  ? fs.readFileSync(enDocsSeriesPath, "utf8")
  : "";
const zhDocsSeries = fs.existsSync(zhDocsSeriesPath)
  ? fs.readFileSync(zhDocsSeriesPath, "utf8")
  : "";
const enDocsRegistry = fs.existsSync(enDocsRegistryPath)
  ? fs.readFileSync(enDocsRegistryPath, "utf8")
  : "";
const zhDocsRegistry = fs.existsSync(zhDocsRegistryPath)
  ? fs.readFileSync(zhDocsRegistryPath, "utf8")
  : "";
const enQuickStartDoc = fs.existsSync(enQuickStartDocPath)
  ? fs.readFileSync(enQuickStartDocPath, "utf8")
  : "";
const zhQuickStartDoc = fs.existsSync(zhQuickStartDocPath)
  ? fs.readFileSync(zhQuickStartDocPath, "utf8")
  : "";
const enConfigurationDoc = fs.existsSync(enConfigurationDocPath)
  ? fs.readFileSync(enConfigurationDocPath, "utf8")
  : "";
const zhConfigurationDoc = fs.existsSync(zhConfigurationDocPath)
  ? fs.readFileSync(zhConfigurationDocPath, "utf8")
  : "";
const enStylingDoc = fs.existsSync(enStylingDocPath)
  ? fs.readFileSync(enStylingDocPath, "utf8")
  : "";
const zhStylingDoc = fs.existsSync(zhStylingDocPath)
  ? fs.readFileSync(zhStylingDocPath, "utf8")
  : "";
const enDeployDoc = fs.existsSync(enDeployDocPath)
  ? fs.readFileSync(enDeployDocPath, "utf8")
  : "";
const zhDeployDoc = fs.existsSync(zhDeployDocPath)
  ? fs.readFileSync(zhDeployDocPath, "utf8")
  : "";
const enReferenceDoc = fs.existsSync(enReferenceDocPath)
  ? fs.readFileSync(enReferenceDocPath, "utf8")
  : "";
const zhReferenceDoc = fs.existsSync(zhReferenceDocPath)
  ? fs.readFileSync(zhReferenceDocPath, "utf8")
  : "";
const enSeriesRegistrySource = enDocsSeries;
const zhSeriesRegistrySource = zhDocsSeries;
const expectedSeriesRoutes = [
  "docs/linux-bringup/",
  "docs/linux-bringup/01-quick-start/",
  "docs/linux-bringup/02-configuration/",
  "docs/linux-bringup/03-styling/",
  "docs/linux-bringup/04-deploy/",
];
const expectedChapterOrder = ["1", "2", "3", "4"];

function extractOrderedMatches(content, regex) {
  const values = [];
  for (const match of content.matchAll(regex)) {
    values.push(match[1]);
  }
  return values;
}

assert(
  !config.includes('html.div(class: "site-frame")'),
  "site-web should not wrap page content in an extra site-frame div",
);
assert(
  config.includes("#let language-switcher("),
  "config.typ should define a reusable language switcher helper",
);
assert(
  config.includes("#let language-switcher-entry("),
  "config.typ should factor localized language switcher entries into a reusable helper",
);
assert(
  config.includes("#let theme-switcher-option("),
  "config.typ should factor theme menu options into a reusable helper",
);
assert(
  config.includes('html.elem("svg"'),
  "theme switcher markup should use inline svg elements in config.typ",
);
assert(
  fs.existsSync(enIndexPath) && fs.existsSync(zhIndexPath),
  "localized English and Chinese root pages should both exist",
);
assert(
  rootIndex.includes("/en/") && rootIndex.includes("/zh/"),
  "root index should act as a language gateway instead of the old single-language home page",
);
assert(
  enIndex.includes('#show: template.with(locale: "en"') &&
    zhIndex.includes('#show: template.with(locale: "zh"'),
  "localized root pages should pass their locale into the shared template wrapper",
);
assert(
  enDocsIndex.includes('#import "../index.typ": template, tufted, content-card') &&
    zhDocsIndex.includes('#import "../index.typ": template, tufted, content-card'),
  "localized docs index pages should inherit from their language root index files",
);
assert(
  fs.existsSync(enDocsRegistryPath) && fs.existsSync(zhDocsRegistryPath),
  "localized docs registry files should exist in both locales",
);
assert(
  fs.existsSync(enDocsSeriesPath) && fs.existsSync(zhDocsSeriesPath),
  "localized series metadata files should live under the series directory in both locales",
);
assert(
  fs.existsSync(enSeriesHomePath) && fs.existsSync(zhSeriesHomePath),
  "localized linux-bringup series homepages should exist in both locales",
);
assert(
  enDocsIndex.includes("== Series") &&
    enDocsIndex.includes("== Short Notes") &&
    enDocsIndex.indexOf("== Series") < enDocsIndex.indexOf("== Short Notes"),
  "English docs index should render Series above Short Notes",
);
assert(
  zhDocsIndex.includes("== 系列") &&
    zhDocsIndex.includes("== 短文") &&
    zhDocsIndex.indexOf("== 系列") < zhDocsIndex.indexOf("== 短文"),
  "Chinese docs index should render 系列 above 短文",
);
assert(
  enDocsIndex.includes('#import "./registry.typ": series-registry, note-registry') &&
    zhDocsIndex.includes('#import "./registry.typ": series-registry, note-registry') &&
    enDocsRegistry.includes('#import "./linux-bringup/series.typ": linux-bringup-series') &&
    zhDocsRegistry.includes('#import "./linux-bringup/series.typ": linux-bringup-series') &&
    enDocsIndex.includes("#for entry in series-registry") &&
    zhDocsIndex.includes("#for entry in series-registry") &&
    enDocsIndex.includes("#for entry in note-registry") &&
    zhDocsIndex.includes("#for entry in note-registry"),
  "docs landing pages should render their cards from localized docs registry files",
);
assert(
  !enDocsIndex.includes('locale-url("en", route: "docs/01-quick-start/")') &&
    !enDocsIndex.includes('locale-url("en", route: "docs/02-configuration/")') &&
    !enDocsIndex.includes('locale-url("en", route: "docs/03-styling/")') &&
    !enDocsIndex.includes('locale-url("en", route: "docs/04-deploy/")') &&
    !zhDocsIndex.includes('locale-url("zh", route: "docs/01-quick-start/")') &&
    !zhDocsIndex.includes('locale-url("zh", route: "docs/02-configuration/")') &&
    !zhDocsIndex.includes('locale-url("zh", route: "docs/03-styling/")') &&
    !zhDocsIndex.includes('locale-url("zh", route: "docs/04-deploy/")'),
  "phase-1 docs landing should no longer list quick-start, configuration, styling, and deploy as top-level cards",
);
assert(
  enQuickStartDoc.includes('route: "docs/linux-bringup/01-quick-start/"') &&
    enConfigurationDoc.includes('route: "docs/linux-bringup/02-configuration/"') &&
    enStylingDoc.includes('route: "docs/linux-bringup/03-styling/"') &&
    enDeployDoc.includes('route: "docs/linux-bringup/04-deploy/"') &&
    zhQuickStartDoc.includes('route: "docs/linux-bringup/01-quick-start/"') &&
    zhConfigurationDoc.includes('route: "docs/linux-bringup/02-configuration/"') &&
    zhStylingDoc.includes('route: "docs/linux-bringup/03-styling/"') &&
    zhDeployDoc.includes('route: "docs/linux-bringup/04-deploy/"'),
  "chapter URLs should move under the series-owned linux-bringup route for both locales",
);
assert(
  enDocsRegistry.includes('id: "bring-up-checklist"') &&
    zhDocsRegistry.includes('id: "bring-up-checklist"'),
  "bring-up-checklist should stay listed in the localized short-note registry",
);
assert(
  !enSeriesRegistrySource.includes("bring-up-checklist") &&
    !zhSeriesRegistrySource.includes("bring-up-checklist"),
  "flat docs should stay outside the series metadata files",
);
const enSeriesIds = extractOrderedMatches(enSeriesRegistrySource, /(?:^|\n)\s*id:\s*"([^"]+)"/g);
const zhSeriesIds = extractOrderedMatches(zhSeriesRegistrySource, /(?:^|\n)\s*id:\s*"([^"]+)"/g);
const enChapterRoutes = extractOrderedMatches(enSeriesRegistrySource, /(?:^|\n)\s*route:\s*"([^"]+)"/g);
const zhChapterRoutes = extractOrderedMatches(zhSeriesRegistrySource, /(?:^|\n)\s*route:\s*"([^"]+)"/g);
const enChapterOrder = extractOrderedMatches(enSeriesRegistrySource, /order:\s*([0-9]+)/g);
const zhChapterOrder = extractOrderedMatches(zhSeriesRegistrySource, /order:\s*([0-9]+)/g);
assert(
  enSeriesIds[0] === "linux-bringup" && zhSeriesIds[0] === "linux-bringup",
  "English and Chinese docs series metadata should register linux-bringup as the mirrored series id",
);
assert(
  JSON.stringify(enChapterRoutes) === JSON.stringify(expectedSeriesRoutes) &&
    JSON.stringify(zhChapterRoutes) === JSON.stringify(expectedSeriesRoutes),
  "English and Chinese docs series metadata should expose the nested series homepage and chapter routes in order",
);
assert(
  JSON.stringify(enChapterOrder) === JSON.stringify(expectedChapterOrder) &&
    JSON.stringify(zhChapterOrder) === JSON.stringify(expectedChapterOrder),
  "English and Chinese docs series metadata should keep the chapter order fields aligned with the approved reading order",
);
assert(
  !fs.existsSync(enLegacySeriesHomePath) &&
    !fs.existsSync(zhLegacySeriesHomePath) &&
    !fs.existsSync(enLegacyReferencePath) &&
    !fs.existsSync(zhLegacyReferencePath),
  "superseded getting-started and embedding-markdown source directories should be removed after the restructure",
);
assert(
  fs.existsSync(enReferenceDocPath) &&
    fs.existsSync(zhReferenceDocPath) &&
    enReferenceDoc.includes('route: "docs/bring-up-checklist/"') &&
    zhReferenceDoc.includes('route: "docs/bring-up-checklist/"'),
  "renamed short-note pages should exist under the bring-up-checklist route in both locales",
);
assert(
  !enReferenceDoc.includes("tufted-titmouse") &&
    !zhReferenceDoc.includes("tufted-titmouse"),
  "renamed short-note pages should not reference the removed tufted-titmouse assets",
);
assert(
  !fs.existsSync(legacyDocsDirPath) &&
    !fs.existsSync(legacyBlogDirPath) &&
    !fs.existsSync(legacyCvDirPath),
  "the old top-level single-language section trees should be removed once localized trees own the content",
);

console.log("PASS template structure keeps shell, inheritance, and bilingual content aligned");
