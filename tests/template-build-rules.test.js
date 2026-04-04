const fs = require("node:fs");
const path = require("node:path");
const { assert } = require("./helpers/assert");

const readme = fs.readFileSync(
  path.join(__dirname, "..", "README.md"),
  "utf8",
);
const makefile = fs.readFileSync(
  path.join(__dirname, "..", "Makefile"),
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
  /node|npm/i.test(readme),
  "README should document the Node.js and npm requirement introduced by Pagefind",
);
assert(
  /npm\s+(ci|install)/.test(readme),
  "README should tell contributors to install npm dependencies before building the site",
);
assert(
  /custom\.css/.test(readme) && /override|custom/i.test(readme),
  "README should explain that assets/custom.css is the intended override hook",
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
