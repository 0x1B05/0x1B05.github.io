const fs = require("node:fs");
const path = require("node:path");
const { assert } = require("./helpers/assert");
const { loadTemplateFixture } = require("./helpers/html-fixture");

const {
  siteDir,
  html,
  enHtml,
  zhHtml,
  enDocsLandingHtml,
  zhDocsLandingHtml,
  enSeriesHomeHtml,
  zhSeriesHomeHtml,
  enDocHtml,
  zhDocHtml,
  enConfigurationDocHtml,
  zhConfigurationDocHtml,
  enDeployDocHtml,
  zhDeployDocHtml,
  enReferenceDocHtml,
  zhReferenceDocHtml,
  enSearchHtml,
  zhSearchHtml,
} = loadTemplateFixture();

function countOccurrences(text, snippet) {
  return text.split(snippet).length - 1;
}

function assertSeriesNavPlacement(htmlText, message) {
  const firstNavIndex = htmlText.indexOf('<nav class="series-nav">');
  const lastNavIndex = htmlText.lastIndexOf('<nav class="series-nav">');
  const headingIndex = htmlText.indexOf("<h2>");
  const firstSubheadingIndex = htmlText.indexOf("<h3>", headingIndex);
  const footerIndex = htmlText.indexOf('<div class="site-footer">');

  assert(
    countOccurrences(htmlText, 'class="series-nav"') === 2,
    `${message} (page should render series navigation twice)`,
  );
  assert(
    firstNavIndex > headingIndex && firstNavIndex < firstSubheadingIndex,
    `${message} (first nav block should sit between the page title and the first section body)`,
  );
  assert(
    lastNavIndex > htmlText.length * 0.7 && lastNavIndex < footerIndex,
    `${message} (second nav block should appear near the bottom of the page, before the footer)`,
  );
}

const headStart = enHtml.indexOf("<head>");
const headEnd = enHtml.indexOf("</head>");
const bootstrapIndex = Math.max(
  enHtml.indexOf("theme-bootstrap.js"),
  enHtml.indexOf("tufted-theme"),
);
const firstStylesheetIndex = enHtml.indexOf('rel="stylesheet"');
const navStart = enHtml.indexOf("<nav>");
const navEnd = enHtml.indexOf("</nav>");
const articleIndex = enHtml.indexOf("<article>");
const themeButtonIndex = enHtml.indexOf("theme-switcher__button");
const languageSwitcherIndex = enHtml.indexOf("language-switcher");
const searchBoxIndex = enHtml.indexOf("site-search");
const primaryGroupIndex = enHtml.indexOf("site-nav__primary");
const controlsGroupIndex = enHtml.indexOf("site-nav__controls");
const primarySection =
  primaryGroupIndex === -1
    ? ""
    : enHtml.slice(primaryGroupIndex, controlsGroupIndex === -1 ? navEnd : controlsGroupIndex);
const controlsSection =
  controlsGroupIndex === -1 ? "" : enHtml.slice(controlsGroupIndex, navEnd);
const controlsSearchIndex = controlsSection.indexOf("site-search");
const controlsLanguageIndex = controlsSection.indexOf("language-switcher");
const controlsThemeIndex = controlsSection.indexOf("theme-switcher__button");

assert(headStart !== -1 && headEnd !== -1, "generated home page should include a head");
assert(
  bootstrapIndex !== -1 &&
    bootstrapIndex > headStart &&
    bootstrapIndex < headEnd &&
    bootstrapIndex < firstStylesheetIndex,
  "theme bootstrap should be emitted in the head before stylesheets load",
);
assert(
  html.includes('href="/en/"') && html.includes('href="/zh/"'),
  "root index should expose explicit English and Chinese entry links",
);
assert(
  html.includes("language-redirect.js"),
  "root index should include the language redirect script",
);
assert(
  enHtml.includes('class="home-hero"') && zhHtml.includes('class="home-hero"'),
  "localized home pages should keep the shared hero shell",
);
assert(
  enHtml.includes('src="/assets/profile.png"') &&
    zhHtml.includes('src="/assets/profile.png"'),
  "localized home pages should serve the shared profile image from the assets path",
);
assert(
  !enHtml.includes('src="data:image/png') && !zhHtml.includes('src="data:image/png'),
  "localized home pages should not embed the profile image as a data URL",
);
assert(
  !fs.existsSync(path.join(siteDir, "en", "docs", "series.html")) &&
    !fs.existsSync(path.join(siteDir, "zh", "docs", "series.html")) &&
    !fs.existsSync(path.join(siteDir, "en", "docs", "registry.html")) &&
    !fs.existsSync(path.join(siteDir, "zh", "docs", "registry.html")),
  "docs metadata files should not compile into standalone HTML outputs",
);
assert(
  fs.existsSync(path.join(siteDir, "pagefind")),
  "generated site should include Pagefind assets under /pagefind/",
);
assert(
  themeButtonIndex > navStart &&
    languageSwitcherIndex > navStart &&
    searchBoxIndex > navStart &&
    themeButtonIndex < navEnd &&
    languageSwitcherIndex < navEnd &&
    searchBoxIndex < navEnd &&
    navEnd < articleIndex,
  "theme switcher, language switcher, and search should render inside the site navigation",
);
assert(
  primaryGroupIndex > navStart && primaryGroupIndex < navEnd,
  "top-bar links should render inside a dedicated primary navigation group",
);
assert(
  controlsGroupIndex > navStart && controlsGroupIndex < navEnd,
  "top-bar controls should render inside a dedicated controls group",
);
assert(
  primarySection.includes('href="/en/docs/"') &&
    primarySection.includes('href="/en/blog/"') &&
    primarySection.includes('href="/en/cv/"'),
  "primary navigation group should contain the main Docs, Blog, and CV links",
);
assert(
  controlsSearchIndex !== -1 &&
    controlsLanguageIndex !== -1 &&
    controlsThemeIndex !== -1 &&
    controlsSearchIndex < controlsLanguageIndex &&
    controlsLanguageIndex < controlsThemeIndex,
  "controls group should contain search, language switcher, then theme switcher in that order",
);
assert(
  enHtml.includes("assets/search.js") && zhHtml.includes("assets/search.js"),
  "localized pages should load the site search runtime script",
);
assert(
  enHtml.includes('class="site-search"') &&
    enHtml.includes('class="site-search__icon"') &&
    enHtml.includes('class="site-search__input"') &&
    enHtml.includes('class="site-search__dropdown"'),
  "English pages should include the search shell hooks",
);
assert(
  zhHtml.includes('class="site-search"') &&
    zhHtml.includes('class="site-search__icon"') &&
    zhHtml.includes('class="site-search__input"') &&
    zhHtml.includes('class="site-search__dropdown"'),
  "Chinese pages should include the search shell hooks",
);
assert(
  enHtml.includes('id="site-search-result-template"') &&
    enHtml.includes('class="site-search-result__title"') &&
    enHtml.includes('class="site-search-result__section"') &&
    enHtml.includes('class="site-search-result__locale"') &&
    enHtml.includes('class="site-search-result__excerpt"'),
  "search result template should include the expected runtime hooks",
);
assert(
  enSearchHtml.includes('id="search-results"') &&
    zhSearchHtml.includes('id="search-results"'),
  "localized search pages should include a results container for runtime rendering",
);
assert(
  !enHtml.includes("theme-switcher__label"),
  "theme switcher should use an icon button instead of the old inline text label",
);
assert(
  enHtml.includes('class="theme-switcher__button-icon theme-switcher__button-icon--sun"') &&
    enHtml.includes("<svg") &&
    !enHtml.includes(">☀<") &&
    !enHtml.includes(">☾<"),
  "theme switcher should render SVG icons instead of text glyphs",
);
assert(
  /<a[^>]*class="[^"]*site-nav__link--brand[^"]*"[^>]*><span class="site-brand">/.test(
    enHtml,
  ),
  "brand navigation link should have a dedicated class",
);
assert(
  /<html[^>]*lang="en"/.test(enHtml) && /<html[^>]*lang="zh"/.test(zhHtml),
  "localized pages should declare the correct html lang attribute",
);
assert(
  enDocsLandingHtml.includes('class="content-card"') &&
    zhDocsLandingHtml.includes('class="content-card"') &&
    enDocsLandingHtml.includes("content-card__thumb") &&
    zhDocsLandingHtml.includes("content-card__thumb"),
  "docs landing pages should render card shells with thumbnail hooks",
);
assert(
  enSeriesHomeHtml.includes('class="language-switcher"') &&
    enSeriesHomeHtml.includes('href="/zh/docs/linux-bringup/"') &&
    zhSeriesHomeHtml.includes('href="/en/docs/linux-bringup/"'),
  "series homepages should keep the language switcher on the sibling series route",
);
assert(
  enDocHtml.includes('href="/zh/docs/linux-bringup/01-quick-start/"') &&
    zhDocHtml.includes('href="/en/docs/linux-bringup/01-quick-start/"') &&
    enConfigurationDocHtml.includes('href="/zh/docs/linux-bringup/02-configuration/"') &&
    zhConfigurationDocHtml.includes('href="/en/docs/linux-bringup/02-configuration/"') &&
    enDeployDocHtml.includes('href="/zh/docs/linux-bringup/04-deploy/"') &&
    zhDeployDocHtml.includes('href="/en/docs/linux-bringup/04-deploy/"'),
  "chapter pages should keep the language switcher on the sibling chapter route",
);
assert(
  enReferenceDocHtml.includes('href="/zh/docs/bring-up-checklist/"') &&
    zhReferenceDocHtml.includes('href="/en/docs/bring-up-checklist/"'),
  "reference pages should keep the language switcher on the sibling route",
);
assertSeriesNavPlacement(
  enDocHtml,
  "first English chapter should place the series navigation near the top and bottom",
);
assertSeriesNavPlacement(
  zhDocHtml,
  "first Chinese chapter should place the series navigation near the top and bottom",
);
assertSeriesNavPlacement(
  enConfigurationDocHtml,
  "middle English chapter should place the series navigation near the top and bottom",
);
assertSeriesNavPlacement(
  zhConfigurationDocHtml,
  "middle Chinese chapter should place the series navigation near the top and bottom",
);
assertSeriesNavPlacement(
  enDeployDocHtml,
  "last English chapter should place the series navigation near the top and bottom",
);
assertSeriesNavPlacement(
  zhDeployDocHtml,
  "last Chinese chapter should place the series navigation near the top and bottom",
);

console.log("PASS template shell emits the shared navigation, controls, and runtime hooks");
