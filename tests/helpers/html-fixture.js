const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const templateDir = path.join(__dirname, "..", "..");
const repoRoot = path.join(templateDir, "..");
const siteDir = path.join(templateDir, "_site");
const htmlPath = path.join(siteDir, "index.html");
const enHtmlPath = path.join(siteDir, "en", "index.html");
const zhHtmlPath = path.join(siteDir, "zh", "index.html");
const enDocsLandingPath = path.join(siteDir, "en", "docs", "index.html");
const zhDocsLandingPath = path.join(siteDir, "zh", "docs", "index.html");
const enSeriesHomePath = path.join(
  siteDir,
  "en",
  "docs",
  "linux-bringup",
  "index.html",
);
const zhSeriesHomePath = path.join(
  siteDir,
  "zh",
  "docs",
  "linux-bringup",
  "index.html",
);
const enQuickStartDocPath = path.join(
  siteDir,
  "en",
  "docs",
  "linux-bringup",
  "01-quick-start",
  "index.html",
);
const zhQuickStartDocPath = path.join(
  siteDir,
  "zh",
  "docs",
  "linux-bringup",
  "01-quick-start",
  "index.html",
);
const enConfigurationDocPath = path.join(
  siteDir,
  "en",
  "docs",
  "linux-bringup",
  "02-configuration",
  "index.html",
);
const zhConfigurationDocPath = path.join(
  siteDir,
  "zh",
  "docs",
  "linux-bringup",
  "02-configuration",
  "index.html",
);
const enDeployDocPath = path.join(
  siteDir,
  "en",
  "docs",
  "linux-bringup",
  "04-deploy",
  "index.html",
);
const zhDeployDocPath = path.join(
  siteDir,
  "zh",
  "docs",
  "linux-bringup",
  "04-deploy",
  "index.html",
);
const enReferenceDocPath = path.join(
  siteDir,
  "en",
  "docs",
  "bring-up-checklist",
  "index.html",
);
const zhReferenceDocPath = path.join(
  siteDir,
  "zh",
  "docs",
  "bring-up-checklist",
  "index.html",
);
const enSearchPath = path.join(siteDir, "en", "search", "index.html");
const zhSearchPath = path.join(siteDir, "zh", "search", "index.html");
const homeDir = process.env.HOME || repoRoot;
const defaultDataDir = path.join(homeDir, ".local", "share");
const defaultCacheDir = path.join(homeDir, ".cache");
const requiredHtmlPaths = [
  htmlPath,
  enHtmlPath,
  zhHtmlPath,
  enDocsLandingPath,
  zhDocsLandingPath,
  enSeriesHomePath,
  zhSeriesHomePath,
  enQuickStartDocPath,
  zhQuickStartDocPath,
  enConfigurationDocPath,
  zhConfigurationDocPath,
  enDeployDocPath,
  zhDeployDocPath,
  enReferenceDocPath,
  zhReferenceDocPath,
];

let fixtureBuilt = false;

function readHtmlIfExists(filePath) {
  return fs.existsSync(filePath) ? fs.readFileSync(filePath, "utf8") : "";
}

function buildEnv() {
  return {
    ...process.env,
    XDG_DATA_HOME: process.env.XDG_DATA_HOME || defaultDataDir,
    XDG_CACHE_HOME: process.env.XDG_CACHE_HOME || defaultCacheDir,
    HOME: process.env.HOME || repoRoot,
  };
}

function stderrFromError(error) {
  return error && error.stderr ? error.stderr.toString().trim() : String(error);
}

function isBenignSpawnError(error) {
  return error && error.status === 0;
}

function runMakeTarget(target) {
  try {
    execFileSync("make", ["-C", templateDir, target], {
      env: buildEnv(),
      stdio: "pipe",
    });

    return null;
  } catch (error) {
    return error;
  }
}

function ensureTemplateFixture() {
  if (fixtureBuilt) {
    return;
  }

  if (!process.env.XDG_DATA_HOME) {
    fs.mkdirSync(defaultDataDir, { recursive: true });
  }
  if (!process.env.XDG_CACHE_HOME) {
    fs.mkdirSync(defaultCacheDir, { recursive: true });
  }

  const cleanError = runMakeTarget("clean");
  if (cleanError && !(isBenignSpawnError(cleanError) && !fs.existsSync(siteDir))) {
    throw new Error(
      `template shell fixture build failed while running make clean: ${stderrFromError(cleanError)}`,
    );
  }

  const buildError = runMakeTarget("html");
  const missingOutputs = requiredHtmlPaths
    .filter((filePath) => !fs.existsSync(filePath))
    .map((filePath) => path.relative(templateDir, filePath));

  if (missingOutputs.length > 0) {
    const stderr = buildError ? `; stderr: ${stderrFromError(buildError)}` : "";
    throw new Error(
      `template shell fixture build failed while running make html; missing outputs: ${missingOutputs.join(", ")}${stderr}`,
    );
  }
  if (buildError && !isBenignSpawnError(buildError)) {
    throw new Error(
      `template shell fixture build failed while running make html: ${stderrFromError(buildError)}`,
    );
  }

  fixtureBuilt = true;
}

function loadTemplateFixture() {
  ensureTemplateFixture();

  return {
    templateDir,
    siteDir,
    html: readHtmlIfExists(htmlPath),
    enHtml: readHtmlIfExists(enHtmlPath),
    zhHtml: readHtmlIfExists(zhHtmlPath),
    enDocsLandingHtml: readHtmlIfExists(enDocsLandingPath),
    zhDocsLandingHtml: readHtmlIfExists(zhDocsLandingPath),
    enSeriesHomeHtml: readHtmlIfExists(enSeriesHomePath),
    zhSeriesHomeHtml: readHtmlIfExists(zhSeriesHomePath),
    enDocHtml: readHtmlIfExists(enQuickStartDocPath),
    zhDocHtml: readHtmlIfExists(zhQuickStartDocPath),
    enConfigurationDocHtml: readHtmlIfExists(enConfigurationDocPath),
    zhConfigurationDocHtml: readHtmlIfExists(zhConfigurationDocPath),
    enDeployDocHtml: readHtmlIfExists(enDeployDocPath),
    zhDeployDocHtml: readHtmlIfExists(zhDeployDocPath),
    enReferenceDocHtml: readHtmlIfExists(enReferenceDocPath),
    zhReferenceDocHtml: readHtmlIfExists(zhReferenceDocPath),
    enSearchHtml: readHtmlIfExists(enSearchPath),
    zhSearchHtml: readHtmlIfExists(zhSearchPath),
    css: fs.readFileSync(path.join(templateDir, "assets", "tufted.css"), "utf8"),
  };
}

module.exports = {
  loadTemplateFixture,
};
