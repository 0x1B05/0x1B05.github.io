const fs = require("node:fs");
const path = require("node:path");
const { assert } = require("./helpers/assert");

const config = fs.readFileSync(
  path.join(__dirname, "..", "config.typ"),
  "utf8",
);

assert(
  config.includes("#let template(body, title: site-name, header-links: auto, ..options)"),
  "template should accept legacy customization options through named argument passthrough",
);
assert(
  config.includes("..options,"),
  "template should forward unconsumed named arguments to site-web",
);
assert(
  config.includes('let kind = if entry.len() > 2 { entry.at(2) } else { "default" }'),
  "make-header should accept both 2-item and 3-item navigation entries",
);
assert(
  config.includes("let nav-links = if header-links == auto {"),
  "template should only build the branded default nav when custom header-links are not provided",
);

console.log("PASS template API keeps legacy customization compatibility");
