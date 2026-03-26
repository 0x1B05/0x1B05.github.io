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
  zhCvHtml,
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

function sectionBetween(htmlText, startLabel, endLabel) {
  const startIndex = htmlText.indexOf(`>${startLabel}<`);
  const endIndex = htmlText.indexOf(`>${endLabel}<`, startIndex + startLabel.length);

  return startIndex === -1 || endIndex === -1
    ? ""
    : htmlText.slice(startIndex, endIndex);
}

function trailingSection(htmlText, startLabel) {
  const startIndex = htmlText.indexOf(`>${startLabel}<`);
  const footerIndex = htmlText.indexOf('<div class="site-footer">', startIndex + startLabel.length);

  return startIndex === -1 || footerIndex === -1
    ? ""
    : htmlText.slice(startIndex, footerIndex);
}

function extractCardSlugs(sectionHtml, locale) {
  const slugPattern = new RegExp(`<a href="/${locale}/docs/([^/"]+)/" class="content-card"`, "g");
  return [...sectionHtml.matchAll(slugPattern)].map((match) => match[1]);
}

function extractDocRoutes(htmlText, locale) {
  const routePattern = new RegExp(`href="/${locale}/docs/([^"]+)"`, "g");
  return [...htmlText.matchAll(routePattern)].map((match) => match[1]);
}

function assertNavPlacement(htmlText, href, topMarker, message) {
  const firstIndex = htmlText.indexOf(href);
  const lastIndex = htmlText.lastIndexOf(href);
  const topMarkerIndex = htmlText.indexOf(topMarker);

  assert(firstIndex !== -1 && lastIndex !== -1 && firstIndex !== lastIndex, message);
  assert(firstIndex < topMarkerIndex, `${message} (first nav link should be above the main body)`);
  assert(
    lastIndex > htmlText.length * 0.75,
    `${message} (second nav link should appear near the bottom of the page)`,
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
const docsSeriesSectionEn = sectionBetween(enDocsLandingHtml, "Series", "Reference");
const docsSeriesSectionZh = sectionBetween(zhDocsLandingHtml, "系列", "参考");
const docsReferenceSectionEn = trailingSection(enDocsLandingHtml, "Reference");
const docsReferenceSectionZh = trailingSection(zhDocsLandingHtml, "参考");
const nestedEnglishChapterRoutes = chapterSlugs.map(
  (slug) => `href="/en/docs/getting-started/${slug}/"`,
);
const nestedChineseChapterRoutes = chapterSlugs.map(
  (slug) => `href="/zh/docs/getting-started/${slug}/"`,
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
  enHtml.includes("Build a deliberate personal site in Typst"),
  "English localized home page should render the English hero content",
);
assert(
  zhHtml.includes("用 Typst 打造一个克制而明确的个人网站"),
  "Chinese localized home page should render the Chinese hero content",
);
assert(
  !fs.existsSync(path.join(siteDir, "en", "docs", "series.html")) &&
    !fs.existsSync(path.join(siteDir, "zh", "docs", "series.html")),
  "docs series metadata should not compile into standalone series.html outputs",
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
  enDocsLandingHtml.includes(">Series<") &&
    enDocsLandingHtml.includes(">Reference<") &&
    enDocsLandingHtml.indexOf(">Series<") < enDocsLandingHtml.indexOf(">Reference<"),
  "English docs landing page should render Series above Reference",
);
assert(
  zhDocsLandingHtml.includes(">系列<") &&
    zhDocsLandingHtml.includes(">参考<") &&
    zhDocsLandingHtml.indexOf(">系列<") < zhDocsLandingHtml.indexOf(">参考<"),
  "Chinese docs landing page should render 系列 above 参考",
);
assert(
  docsSeriesSectionEn.includes('class="content-grid"') &&
    docsSeriesSectionEn.includes("content-card__thumb") &&
    docsSeriesSectionEn.includes("content-card__title"),
  "English Series region should preserve the card-grid, thumbnail, and title structure",
);
assert(
  docsSeriesSectionZh.includes('class="content-grid"') &&
    docsSeriesSectionZh.includes("content-card__thumb") &&
    docsSeriesSectionZh.includes("content-card__title"),
  "Chinese 系列 region should preserve the card-grid, thumbnail, and title structure",
);
assert(
  JSON.stringify(extractCardSlugs(docsSeriesSectionEn, "en")) ===
    JSON.stringify(["getting-started"]) &&
    JSON.stringify(extractCardSlugs(docsSeriesSectionZh, "zh")) ===
      JSON.stringify(["getting-started"]),
  "docs landing pages should collapse the setup tutorial into a single getting-started series card",
);
assert(
  docsReferenceSectionEn.includes('class="content-grid"') &&
    docsReferenceSectionEn.includes("content-card__thumb") &&
    docsReferenceSectionEn.includes("content-card__title"),
  "English Reference region should preserve the card-grid, thumbnail, and title structure",
);
assert(
  docsReferenceSectionZh.includes('class="content-grid"') &&
    docsReferenceSectionZh.includes("content-card__thumb") &&
    docsReferenceSectionZh.includes("content-card__title"),
  "Chinese 参考 region should preserve the card-grid, thumbnail, and title structure",
);
assert(
  JSON.stringify(extractCardSlugs(docsReferenceSectionEn, "en")) ===
    JSON.stringify(["embedding-markdown"]) &&
    JSON.stringify(extractCardSlugs(docsReferenceSectionZh, "zh")) ===
      JSON.stringify(["embedding-markdown"]),
  "docs landing pages should keep embedding-markdown isolated in the reference area",
);
assert(
  enSeriesHomeHtml.toLowerCase().includes("recommended") &&
    zhSeriesHomeHtml.includes("阅读"),
  "series homepages should include a short recommended reading pattern in both locales",
);
assert(
  chapterSlugs.every((slug) => enSeriesHomeHtml.includes(`href="/en/docs/${slug}/"`)) &&
    chapterSlugs.every((slug) => zhSeriesHomeHtml.includes(`href="/zh/docs/${slug}/"`)),
  "series homepages should list the included flat chapter routes in both locales",
);
assert(
  extractDocRoutes(enSeriesHomeHtml, "en").at(-1) === "01-quick-start/" &&
    extractDocRoutes(zhSeriesHomeHtml, "zh").at(-1) === "01-quick-start/",
  "series homepages should end with a begin action pointing to the first flat chapter route",
);
assert(
  enSeriesHomeHtml.includes('class="language-switcher"') &&
    enSeriesHomeHtml.includes('href="/zh/docs/getting-started/"') &&
    zhSeriesHomeHtml.includes('href="/en/docs/getting-started/"'),
  "series homepages should keep the language switcher on the sibling series route",
);
assert(
  enDocHtml.includes('class="language-switcher"') &&
    enDocHtml.includes('href="/zh/docs/01-quick-start/"') &&
    zhDocHtml.includes('href="/en/docs/01-quick-start/"') &&
    enConfigurationDocHtml.includes('href="/zh/docs/02-configuration/"') &&
    zhConfigurationDocHtml.includes('href="/en/docs/02-configuration/"') &&
    enDeployDocHtml.includes('href="/zh/docs/04-deploy/"') &&
    zhDeployDocHtml.includes('href="/en/docs/04-deploy/"'),
  "chapter pages should render a sibling-language switcher that keeps readers on the matching route",
);
assert(
  enReferenceDocHtml.includes('href="/zh/docs/embedding-markdown/"') &&
    zhReferenceDocHtml.includes('href="/en/docs/embedding-markdown/"'),
  "reference pages should keep the language switcher on the sibling reference route",
);
assert(
  countOccurrences(enDocHtml, 'href="/en/docs/getting-started/"') === 2 &&
    countOccurrences(enDocHtml, 'href="/en/docs/02-configuration/"') === 2 &&
    !enDocHtml.includes('href="/en/docs/03-styling/"'),
  "first English chapter should link only to series home and the next flat chapter",
);
assert(
  countOccurrences(zhDocHtml, 'href="/zh/docs/getting-started/"') === 2 &&
    countOccurrences(zhDocHtml, 'href="/zh/docs/02-configuration/"') === 2 &&
    !zhDocHtml.includes('href="/zh/docs/03-styling/"'),
  "first Chinese chapter should link only to series home and the next flat chapter",
);
assert(
  countOccurrences(enConfigurationDocHtml, 'href="/en/docs/01-quick-start/"') === 2 &&
    countOccurrences(enConfigurationDocHtml, 'href="/en/docs/getting-started/"') === 2 &&
    countOccurrences(enConfigurationDocHtml, 'href="/en/docs/03-styling/"') === 2,
  "middle English chapter should link to previous, series home, and next flat chapter routes",
);
assert(
  countOccurrences(zhConfigurationDocHtml, 'href="/zh/docs/01-quick-start/"') === 2 &&
    countOccurrences(zhConfigurationDocHtml, 'href="/zh/docs/getting-started/"') === 2 &&
    countOccurrences(zhConfigurationDocHtml, 'href="/zh/docs/03-styling/"') === 2,
  "middle Chinese chapter should link to previous, series home, and next flat chapter routes",
);
assert(
  countOccurrences(enDeployDocHtml, 'href="/en/docs/03-styling/"') === 2 &&
    countOccurrences(enDeployDocHtml, 'href="/en/docs/getting-started/"') === 2 &&
    !enDeployDocHtml.includes('href="/en/docs/02-configuration/"'),
  "last English chapter should link only to the previous flat chapter and series home",
);
assert(
  countOccurrences(zhDeployDocHtml, 'href="/zh/docs/03-styling/"') === 2 &&
    countOccurrences(zhDeployDocHtml, 'href="/zh/docs/getting-started/"') === 2 &&
    !zhDeployDocHtml.includes('href="/zh/docs/02-configuration/"'),
  "last Chinese chapter should link only to the previous flat chapter and series home",
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
  'href="/en/docs/getting-started/"',
  "Installation",
  "first English chapter should place the series navigation near the top and bottom",
);
assertNavPlacement(
  zhDocHtml,
  'href="/zh/docs/getting-started/"',
  "安装",
  "first Chinese chapter should place the series navigation near the top and bottom",
);
assertNavPlacement(
  enConfigurationDocHtml,
  'href="/en/docs/getting-started/"',
  "Default Asset Roles",
  "middle English chapter should place the series navigation near the top and bottom",
);
assertNavPlacement(
  zhConfigurationDocHtml,
  'href="/zh/docs/getting-started/"',
  "默认资源角色",
  "middle Chinese chapter should place the series navigation near the top and bottom",
);
assertNavPlacement(
  enDeployDocHtml,
  'href="/en/docs/getting-started/"',
  "Local Preview",
  "last English chapter should place the series navigation near the top and bottom",
);
assertNavPlacement(
  zhDeployDocHtml,
  'href="/zh/docs/getting-started/"',
  "本地预览",
  "last Chinese chapter should place the series navigation near the top and bottom",
);
assert(
  nestedEnglishChapterRoutes.every(
    (href) =>
      !enDocsLandingHtml.includes(href) &&
      !enSeriesHomeHtml.includes(href) &&
      !enDocHtml.includes(href) &&
      !enConfigurationDocHtml.includes(href) &&
      !enDeployDocHtml.includes(href),
  ) &&
    nestedChineseChapterRoutes.every(
      (href) =>
        !zhDocsLandingHtml.includes(href) &&
        !zhSeriesHomeHtml.includes(href) &&
        !zhDocHtml.includes(href) &&
        !zhConfigurationDocHtml.includes(href) &&
        !zhDeployDocHtml.includes(href),
    ),
  "phase-1 docs series should not introduce nested getting-started chapter URLs in rendered output",
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
  zhCvHtml.includes("<em>Visual explanations: images and quantities, evidence and narrative</em>") &&
    zhCvHtml.includes("<em>American Political Science Review</em>"),
  "Chinese profile page should preserve the original emphasized work titles",
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
