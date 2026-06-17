const { assert } = require("./helpers/assert");
const { loadTemplateFixture } = require("./helpers/html-fixture");

const { css, zhArchPreloadingHtml } = loadTemplateFixture();

assert(
  zhArchPreloadingHtml.includes("<math"),
  "Typst math should be emitted as native MathML in generated HTML",
);
assert(
  !zhArchPreloadingHtml.includes('role="math"'),
  "generated HTML should not use the old SVG math wrapper",
);
assert(
  !css.includes('[role="math"]'),
  "site CSS should not keep old SVG math wrapper rules",
);

console.log("PASS template emits Typst math as native MathML");
