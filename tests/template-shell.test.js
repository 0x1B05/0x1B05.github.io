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
  css,
} = loadTemplateFixture();

const chapterSlugs = [
  "01-quick-start",
  "02-configuration",
  "03-styling",
  "04-deploy",
];

function countOccurrences(text, snippet) {
  return text.split(snippet).length - 1;
}

function extractCardSlugs(sectionHtml, locale) {
  const slugPattern = new RegExp(`<a href="/${locale}/docs/([^/"]+)/" class="content-card"`, "g");
  return [...sectionHtml.matchAll(slugPattern)].map((match) => match[1]);
}

function extractDocRoutes(htmlText, locale) {
  const routePattern = new RegExp(`href="/${locale}/docs/([^"]+)"`, "g");
  return [...htmlText.matchAll(routePattern)].map((match) => match[1]);
}

function assertNavPlacement(htmlText, href, message) {
  const firstIndex = htmlText.indexOf(href);
  const lastIndex = htmlText.lastIndexOf(href);
  const firstNavIndex = htmlText.indexOf('<nav class="series-nav">');
  const lastNavIndex = htmlText.lastIndexOf('<nav class="series-nav">');
  const headingIndex = htmlText.indexOf("<h2>");
  const firstSubheadingIndex = htmlText.indexOf("<h3>", headingIndex);
  const footerIndex = htmlText.indexOf('<div class="site-footer">');

  assert(firstIndex !== -1 && lastIndex !== -1 && firstIndex !== lastIndex, message);
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
const seriesEnglishChapterRoutes = chapterSlugs.map(
  (slug) => `href="/en/docs/linux-bringup/${slug}/"`,
);
const seriesChineseChapterRoutes = chapterSlugs.map(
  (slug) => `href="/zh/docs/linux-bringup/${slug}/"`,
);
const legacyFlatEnglishChapterRoutes = chapterSlugs.map(
  (slug) => `href="/en/docs/${slug}/"`,
);
const legacyFlatChineseChapterRoutes = chapterSlugs.map(
  (slug) => `href="/zh/docs/${slug}/"`,
);

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
  enHtml.includes('class="home-hero"') &&
    zhHtml.includes('class="home-hero"') &&
    countOccurrences(enHtml, 'class="home-link"') === 3 &&
    countOccurrences(zhHtml, 'class="home-link"') === 3,
  "localized home pages should keep the shared hero shell and three primary entry links",
);
assert(
  !fs.existsSync(path.join(siteDir, "en", "docs", "series.html")) &&
    !fs.existsSync(path.join(siteDir, "zh", "docs", "series.html")),
  "docs series metadata should not compile into standalone series.html outputs",
);
assert(
  !fs.existsSync(path.join(siteDir, "en", "docs", "registry.html")) &&
    !fs.existsSync(path.join(siteDir, "zh", "docs", "registry.html")),
  "docs registry metadata should not compile into standalone registry.html outputs",
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
  themeButtonIndex > navStart &&
    languageSwitcherIndex > navStart &&
    themeButtonIndex < navEnd &&
    languageSwitcherIndex < navEnd &&
    navEnd < articleIndex,
  "theme switcher should render inside the site navigation instead of floating over the article",
);
assert(
  !enHtml.includes("theme-switcher__label"),
  "theme switcher should use an icon button instead of the old inline text label",
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
  countOccurrences(enDocsLandingHtml, 'class="content-card"') === 2 &&
    countOccurrences(zhDocsLandingHtml, 'class="content-card"') === 2 &&
    enDocsLandingHtml.includes("content-card__thumb") &&
    zhDocsLandingHtml.includes("content-card__thumb") &&
    JSON.stringify(extractCardSlugs(enDocsLandingHtml, "en")) ===
      JSON.stringify(["linux-bringup", "bring-up-checklist"]) &&
    JSON.stringify(extractCardSlugs(zhDocsLandingHtml, "zh")) ===
      JSON.stringify(["linux-bringup", "bring-up-checklist"]),
  "docs landing pages should render the localized series and reference cards in a stable order",
);
assert(
  chapterSlugs.every((slug) => enSeriesHomeHtml.includes(`href="/en/docs/linux-bringup/${slug}/"`)) &&
    chapterSlugs.every((slug) => zhSeriesHomeHtml.includes(`href="/zh/docs/linux-bringup/${slug}/"`)),
  "series homepages should list the included nested chapter routes in both locales",
);
assert(
  extractDocRoutes(enSeriesHomeHtml, "en").at(-1) === "linux-bringup/01-quick-start/" &&
    extractDocRoutes(zhSeriesHomeHtml, "zh").at(-1) === "linux-bringup/01-quick-start/",
  "series homepages should end with a begin action pointing to the first nested chapter route",
);
assert(
  enSeriesHomeHtml.includes('class="language-switcher"') &&
    enSeriesHomeHtml.includes('href="/zh/docs/linux-bringup/"') &&
    zhSeriesHomeHtml.includes('href="/en/docs/linux-bringup/"'),
  "series homepages should keep the language switcher on the sibling series route",
);
assert(
  enDocHtml.includes('class="language-switcher"') &&
    enDocHtml.includes('href="/zh/docs/linux-bringup/01-quick-start/"') &&
    zhDocHtml.includes('href="/en/docs/linux-bringup/01-quick-start/"') &&
    enConfigurationDocHtml.includes('href="/zh/docs/linux-bringup/02-configuration/"') &&
    zhConfigurationDocHtml.includes('href="/en/docs/linux-bringup/02-configuration/"') &&
    enDeployDocHtml.includes('href="/zh/docs/linux-bringup/04-deploy/"') &&
    zhDeployDocHtml.includes('href="/en/docs/linux-bringup/04-deploy/"'),
  "chapter pages should render a sibling-language switcher that keeps readers on the matching route",
);
assert(
  enReferenceDocHtml.includes('href="/zh/docs/bring-up-checklist/"') &&
    zhReferenceDocHtml.includes('href="/en/docs/bring-up-checklist/"'),
  "reference pages should keep the language switcher on the sibling reference route",
);
assert(
  countOccurrences(enDocHtml, 'href="/en/docs/linux-bringup/"') === 2 &&
    countOccurrences(enDocHtml, 'href="/en/docs/linux-bringup/02-configuration/"') === 2 &&
    !enDocHtml.includes('href="/en/docs/linux-bringup/03-styling/"'),
  "first English chapter should link only to series home and the next nested chapter",
);
assert(
  countOccurrences(zhDocHtml, 'href="/zh/docs/linux-bringup/"') === 2 &&
    countOccurrences(zhDocHtml, 'href="/zh/docs/linux-bringup/02-configuration/"') === 2 &&
    !zhDocHtml.includes('href="/zh/docs/linux-bringup/03-styling/"'),
  "first Chinese chapter should link only to series home and the next nested chapter",
);
assert(
  countOccurrences(enConfigurationDocHtml, 'href="/en/docs/linux-bringup/01-quick-start/"') === 2 &&
    countOccurrences(enConfigurationDocHtml, 'href="/en/docs/linux-bringup/"') === 2 &&
    countOccurrences(enConfigurationDocHtml, 'href="/en/docs/linux-bringup/03-styling/"') === 2,
  "middle English chapter should link to previous, series home, and next nested chapter routes",
);
assert(
  countOccurrences(zhConfigurationDocHtml, 'href="/zh/docs/linux-bringup/01-quick-start/"') === 2 &&
    countOccurrences(zhConfigurationDocHtml, 'href="/zh/docs/linux-bringup/"') === 2 &&
    countOccurrences(zhConfigurationDocHtml, 'href="/zh/docs/linux-bringup/03-styling/"') === 2,
  "middle Chinese chapter should link to previous, series home, and next nested chapter routes",
);
assert(
  countOccurrences(enDeployDocHtml, 'href="/en/docs/linux-bringup/03-styling/"') === 2 &&
    countOccurrences(enDeployDocHtml, 'href="/en/docs/linux-bringup/"') === 2 &&
    !enDeployDocHtml.includes('href="/en/docs/linux-bringup/02-configuration/"'),
  "last English chapter should link only to the previous nested chapter and series home",
);
assert(
  countOccurrences(zhDeployDocHtml, 'href="/zh/docs/linux-bringup/03-styling/"') === 2 &&
    countOccurrences(zhDeployDocHtml, 'href="/zh/docs/linux-bringup/"') === 2 &&
    !zhDeployDocHtml.includes('href="/zh/docs/linux-bringup/02-configuration/"'),
  "last Chinese chapter should link only to the previous nested chapter and series home",
);
assert(
  enDocHtml.includes("Previous") || enConfigurationDocHtml.includes("Previous"),
  "English chapter navigation should render localized previous labels",
);
assert(
  enDocHtml.includes("Next") || enConfigurationDocHtml.includes("Next"),
  "English chapter navigation should render localized next labels",
);
assert(
  zhDocHtml.includes("上一") || zhConfigurationDocHtml.includes("上一"),
  "Chinese chapter navigation should render localized previous labels",
);
assert(
  zhDocHtml.includes("下一") || zhConfigurationDocHtml.includes("下一"),
  "Chinese chapter navigation should render localized next labels",
);
assertNavPlacement(
  enDocHtml,
  'href="/en/docs/linux-bringup/"',
  "first English chapter should place the series navigation near the top and bottom",
);
assertNavPlacement(
  zhDocHtml,
  'href="/zh/docs/linux-bringup/"',
  "first Chinese chapter should place the series navigation near the top and bottom",
);
assertNavPlacement(
  enConfigurationDocHtml,
  'href="/en/docs/linux-bringup/"',
  "middle English chapter should place the series navigation near the top and bottom",
);
assertNavPlacement(
  zhConfigurationDocHtml,
  'href="/zh/docs/linux-bringup/"',
  "middle Chinese chapter should place the series navigation near the top and bottom",
);
assertNavPlacement(
  enDeployDocHtml,
  'href="/en/docs/linux-bringup/"',
  "last English chapter should place the series navigation near the top and bottom",
);
assertNavPlacement(
  zhDeployDocHtml,
  'href="/zh/docs/linux-bringup/"',
  "last Chinese chapter should place the series navigation near the top and bottom",
);
assert(
  seriesEnglishChapterRoutes.every(
    (href) =>
      enSeriesHomeHtml.includes(href) ||
      enDocHtml.includes(href) ||
      enConfigurationDocHtml.includes(href) ||
      enDeployDocHtml.includes(href),
  ) &&
    seriesChineseChapterRoutes.every(
      (href) =>
        zhSeriesHomeHtml.includes(href) ||
        zhDocHtml.includes(href) ||
        zhConfigurationDocHtml.includes(href) ||
        zhDeployDocHtml.includes(href),
    ),
  "series pages should render nested linux-bringup chapter URLs after the restructure",
);
assert(
  legacyFlatEnglishChapterRoutes.every(
    (href) =>
      !enDocsLandingHtml.includes(href) &&
      !enSeriesHomeHtml.includes(href) &&
      !enDocHtml.includes(href) &&
      !enConfigurationDocHtml.includes(href) &&
      !enDeployDocHtml.includes(href),
  ) &&
    legacyFlatChineseChapterRoutes.every(
      (href) =>
        !zhDocsLandingHtml.includes(href) &&
        !zhSeriesHomeHtml.includes(href) &&
        !zhDocHtml.includes(href) &&
        !zhConfigurationDocHtml.includes(href) &&
        !zhDeployDocHtml.includes(href),
    ),
  "old flat chapter routes should disappear from rendered output once the series owns nested URLs",
);
assert(
  enHtml.includes('class="theme-switcher__button-icon theme-switcher__button-icon--sun"') &&
    enHtml.includes("<svg") &&
    !enHtml.includes(">☀<") &&
    !enHtml.includes(">☾<"),
  "theme switcher should render SVG icons instead of theme glyph characters",
);
assert(
  css.includes(".site-nav__link--brand"),
  "brand navigation styling should target the dedicated brand link class",
);
assert(
  !css.includes("header nav a:first-child"),
  "brand navigation styling should not depend on the first nav link",
);
assert(
  css.includes(".theme-switcher__button"),
  "theme switcher styling should target the new icon button trigger",
);
assert(
  css.includes(".theme-switcher__menu"),
  "theme switcher styling should include the dropdown menu",
);
assert(
  css.includes(".language-switcher"),
  "localized header styling should include the language switcher",
);
assert(
  /html\s*\{\s*font-size:\s*12pt;/.test(css),
  "site typography should use the larger base font size",
);
assert(
  /article p,\s*article li\s*\{[^}]*font-size:\s*1\.24rem;/.test(css),
  "article copy should override the upstream paragraph scale with a slightly smaller size",
);
assert(
  /article h2\s*\{[^}]*font-size:\s*1\.72rem;/.test(css),
  "article h2 headings should be slightly smaller than the upstream default scale",
);
assert(
  /article h3\s*\{[^}]*font-size:\s*1\.44rem;/.test(css),
  "article h3 headings should be slightly smaller than the upstream default scale",
);
assert(
  /html\[lang="zh"\]\s+article p,\s*html\[lang="zh"\]\s+article li\s*\{[\s\S]*font-size:\s*1\.04rem;/.test(css),
  "Chinese article copy should be reduced a touch more to offset denser glyph shapes",
);
assert(
  /html\[lang="zh"\]\s+h1,\s*html\[lang="zh"\]\s+h2,\s*html\[lang="zh"\]\s+h3,\s*html\[lang="zh"\]\s+h4,\s*html\[lang="zh"\]\s+h5,\s*html\[lang="zh"\]\s+h6,\s*html\[lang="zh"\]\s+\.home-link__title,\s*html\[lang="zh"\]\s+\.content-card__title\s*\{[\s\S]*font-style:\s*normal\s*!important;/.test(
    css,
  ),
  "Chinese titles should override the upstream italic heading treatment",
);
assert(
  /\.site-brand\s*\{[\s\S]*width:\s*8rem;/.test(css),
  "brand logo container should keep a stable width so nav links do not shift between themes",
);
assert(
  /header nav > p\s*\{[\s\S]*display:\s*flex;[\s\S]*align-items:\s*center;[\s\S]*flex:\s*0 1 auto;[\s\S]*margin:\s*0;/.test(
    css,
  ),
  "navigation paragraph wrapper should be normalized into a flex row so light and dark themes do not change nav height",
);
assert(
  /\.site-brand\s*\{[\s\S]*line-height:\s*0;/.test(css),
  "brand logo should suppress inline line-box differences between light and dark variants",
);
assert(
  /header nav \.site-nav__link\s*\{[\s\S]*font-size:\s*1\.1rem;/.test(css),
  "navigation links should use the larger font size",
);
assert(
  /\.theme-switcher__button-icon svg\s*\{[\s\S]*width:\s*1\.1rem;/.test(css),
  "theme switcher button icons should size the inline SVG explicitly",
);
assert(
  /\.home-link__title\s*\{[\s\S]*font-size:\s*1\.12rem;/.test(css),
  "home link titles should be larger for better readability",
);
assert(
  /\.home-link__description\s*\{[\s\S]*font-size:\s*1rem;/.test(css),
  "home link descriptions should stay readable without overpowering the page body",
);
assert(
  /\.content-card__title\s*\{[\s\S]*font-size:\s*1\.24rem;/.test(css),
  "content card titles should be larger across docs and blog indexes",
);
assert(
  /\.content-card__description\s*\{[\s\S]*font-size:\s*1\.02rem;/.test(css),
  "content card descriptions should sit closer to the body copy scale",
);
assert(
  /\.content-grid\s*\{[\s\S]*width:\s*min\(100%,\s*44rem\);/.test(css),
  "content grids should keep a capped width so cards do not press against the far-right edge",
);
assert(
  /\.home-links\s*\{[^}]*width:\s*min\(100%,\s*48rem\);/.test(css),
  "home page link cards should keep the same capped width so they do not press against the far-right edge",
);
assert(
  /\.home-hero__profile\s*\{[^}]*width:\s*20rem;/.test(css),
  "home hero portrait should use a fixed smaller footprint",
);
assert(
  /\.home-hero__profile img,\s*\.home-hero__profile svg\s*\{[^}]*width:\s*20rem;[^}]*height:\s*20rem;[^}]*object-fit:\s*cover;[^}]*border-radius:\s*50%;/.test(
    css,
  ),
  "home hero portrait should render as a circular cropped avatar",
);

console.log("PASS template shell emits bilingual navigation, docs series navigation, and localized pages");
