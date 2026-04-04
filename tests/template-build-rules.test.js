const fs = require("node:fs");
const path = require("node:path");
const { assert } = require("./helpers/assert");

const makefile = fs.readFileSync(
  path.join(__dirname, "..", "Makefile"),
  "utf8",
);
const shellTest = fs.readFileSync(
  path.join(__dirname, "template-shell.test.js"),
  "utf8",
);
const htmlFixtureHelper = fs.readFileSync(
  path.join(__dirname, "helpers", "html-fixture.js"),
  "utf8",
);
const deployWorkflow = fs.readFileSync(
  path.join(__dirname, "..", ".github", "workflows", "deploy.yml"),
  "utf8",
);

assert(
  /SITE_DIR\s*:=\s*_site/.test(makefile),
  "Makefile should centralize the generated site directory in a dedicated variable",
);
assert(
  /SITE_ASSET_DIR\s*:=\s*\$\(SITE_DIR\)\/assets/.test(makefile),
  "Makefile should centralize the generated asset directory in a dedicated variable",
);
assert(
  /TYPST_HTML_FLAGS\s*:=\s*--root \.\. --features html --format html/.test(makefile),
  "Makefile should centralize the shared Typst HTML compile flags",
);
assert(
  /find content [^\n]*-name '\*\.typ'[^\n]*(-not -name 'series\.typ'|! -name 'series\.typ')/.test(
    makefile,
  ),
  "Makefile should exclude docs series metadata files from the standalone HTML page list",
);
assert(
  /find content [^\n]*-name '\*\.typ'[^\n]*(-not -name 'registry\.typ'|! -name 'registry\.typ')/.test(
    makefile,
  ),
  "Makefile should exclude docs registry metadata files from the standalone HTML page list",
);
assert(
  /pagefind/.test(makefile),
  "Makefile should run Pagefind as a post-build step so the static site includes a search index",
);
assert(
  /--force-language\s+en/.test(makefile),
  "Makefile should force a single Pagefind language so search can return results across locales from one search box",
);
assert(
  /page-shared-typs[\s\S]*series\.typ/.test(makefile),
  "Makefile should track parent docs/series.typ files as shared Typst prerequisites when chapter pages import series metadata",
);
assert(
  makefile.includes("LC_ALL=C sort"),
  "Makefile should sort discovered file lists for stable dependency ordering",
);
assert(
  !makefile.includes("_site/%.html: content/%.typ $(SOURCE_TYPS) $(ASSET_FILES)"),
  "HTML builds should not depend on every copied asset file",
);
assert(
  makefile.includes("EMBEDDED_ASSET_FILES"),
  "Makefile should track only embedded assets as HTML prerequisites",
);
assert(
  !makefile.includes("SOURCE_TYPS"),
  "HTML builds should not depend on every Typst source file in the project",
);
assert(
  makefile.includes(".SECONDEXPANSION:"),
  "Makefile should use second expansion for page-specific shared Typst prerequisites",
);
assert(
  makefile.includes("page-shared-typs"),
  "Makefile should compute shared Typst prerequisites per page",
);
assert(
  !makefile.includes("firstword $(subst /, ,$(1))"),
  "shared Typst prerequisites should not stop at the top-level section index",
);
assert(
  makefile.includes('while [ "$$page_dir" != "content" ] && [ "$$page_dir" != "." ]; do'),
  "Makefile should walk all parent directories when collecting inherited index.typ files",
);
assert(
  !makefile.includes("$(CONTENT_SUPPORT_FILES)"),
  "HTML builds should not depend on every non-Typst content file",
);
assert(
  !makefile.includes("$(EMBEDDED_ASSET_FILES)"),
  "HTML builds should not depend on every embedded asset file",
);
assert(
  makefile.includes("page-support-files"),
  "Makefile should compute non-Typst content prerequisites per page",
);
assert(
  makefile.includes("page-embedded-assets"),
  "Makefile should compute embedded asset prerequisites per page",
);
assert(
  !makefile.includes("pages: clean html"),
  "pages target should not express clean and html as parallelizable prerequisites",
);
assert(
  makefile.includes("pages:\n\t@$(MAKE) clean\n\t@$(MAKE) html"),
  "pages target should run clean and html serially via recursive make",
);
assert(
  /PORT\s*\?=\s*8000/.test(makefile),
  "Makefile should expose a default preview port variable",
);
assert(
  /preview:\n\t@\$\(MAKE\) html\n\t@python3 -m http\.server -d \$\(SITE_DIR\) \$\(PORT\)/.test(makefile),
  "Makefile should provide a preview target that builds and serves the generated site",
);
assert(
  /\$\(SITE_DIR\)\/%\.html: content\/%\.typ/.test(makefile),
  "HTML pattern rules should reuse the centralized site directory variable",
);
assert(
  makefile.includes("typst compile $(TYPST_HTML_FLAGS) $< $@"),
  "HTML pattern rules should reuse the centralized Typst HTML compile flags",
);
assert(
  shellTest.includes("loadTemplateFixture"),
  "template-shell test should load generated HTML through the shared fixture helper",
);
assert(
  !shellTest.includes("execFileSync"),
  "template-shell test should not inline fixture build commands once a helper exists",
);
assert(
  htmlFixtureHelper.includes('execFileSync("make"'),
  "shared HTML fixture helper should invoke make directly without a shell wrapper",
);
assert(
  htmlFixtureHelper.includes('runMakeTarget("clean")'),
  "shared HTML fixture helper should clear old _site output before rebuilding HTML fixtures",
);
assert(
  htmlFixtureHelper.includes('runMakeTarget("html")'),
  "shared HTML fixture helper should invoke the template Makefile to generate HTML",
);
assert(
  htmlFixtureHelper.includes("missing outputs:"),
  "shared HTML fixture helper should report exactly which generated HTML outputs are missing",
);
assert(
  htmlFixtureHelper.includes('const siteDir = path.join(templateDir, "_site")'),
  "shared HTML fixture helper should centralize the generated site directory",
);
assert(
  htmlFixtureHelper.includes('const enHtmlPath = path.join(siteDir, "en", "index.html")') &&
    htmlFixtureHelper.includes('const zhHtmlPath = path.join(siteDir, "zh", "index.html")'),
  "shared HTML fixture helper should cover the localized English and Chinese home outputs",
);
assert(
  htmlFixtureHelper.includes("const enSeriesHomePath = path.join(") &&
    htmlFixtureHelper.includes('"linux-bringup"'),
  "shared HTML fixture helper should cover the localized series home outputs",
);
assert(
  htmlFixtureHelper.includes("const enReferenceDocPath = path.join(") &&
    htmlFixtureHelper.includes('"bring-up-checklist"'),
  "shared HTML fixture helper should cover the localized reference doc outputs",
);
assert(
  htmlFixtureHelper.includes('const enSearchPath = path.join(siteDir, "en", "search", "index.html")') &&
    htmlFixtureHelper.includes('const zhSearchPath = path.join(siteDir, "zh", "search", "index.html")'),
  "shared HTML fixture helper should cover the localized search page outputs",
);
assert(
  !htmlFixtureHelper.includes('"/bin/zsh"'),
  "template-shell test should not depend on a workstation-specific shell path",
);
assert(
  !htmlFixtureHelper.includes('"/home/0x1b05/.cache"'),
  "template-shell test should not depend on a workstation-specific cache path",
);
assert(
  htmlFixtureHelper.includes('const homeDir = process.env.HOME || repoRoot'),
  "shared HTML fixture helper should derive fallback paths from HOME before falling back to the repo",
);
assert(
  htmlFixtureHelper.includes('path.join(homeDir, ".cache")'),
  "shared HTML fixture helper should derive its fallback cache path from HOME",
);
assert(
  /setup-node|actions\/setup-node@/.test(deployWorkflow),
  "GitHub Pages deploy workflow should set up Node so it can install and run Pagefind during make pages",
);
assert(
  /npm\s+ci|npm\s+install/.test(deployWorkflow),
  "GitHub Pages deploy workflow should install npm dependencies before building the site",
);

console.log("PASS template build rules avoid over-rebuilds and clean-checkout test failures");
