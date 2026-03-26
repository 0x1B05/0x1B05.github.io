const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const { assert } = require("./helpers/assert");
const { createClassList } = require("./helpers/theme-switcher-harness");

function runThemeBootstrap(storedTheme) {
  const root = {
    classList: createClassList(),
  };
  const context = {
    console,
    document: {
      documentElement: root,
    },
    localStorage: {
      getItem() {
        if (storedTheme instanceof Error) {
          throw storedTheme;
        }

        return storedTheme;
      },
    },
  };

  context.globalThis = context;
  vm.createContext(context);
  vm.runInContext(
    fs.readFileSync(
      path.join(__dirname, "..", "assets", "theme-bootstrap.js"),
      "utf8",
    ),
    context,
  );

  return root;
}

const darkRoot = runThemeBootstrap("dark");
assert(
  darkRoot.classList.contains("theme-dark"),
  "bootstrap should restore a stored dark theme before stylesheets load",
);

const lightRoot = runThemeBootstrap("light");
assert(
  lightRoot.classList.contains("theme-light"),
  "bootstrap should restore a stored light theme before stylesheets load",
);

const systemRoot = runThemeBootstrap("system");
assert(
  !systemRoot.classList.contains("theme-light") &&
    !systemRoot.classList.contains("theme-dark"),
  "bootstrap should leave system theme pages unforced",
);

const blockedStorageRoot = runThemeBootstrap(new Error("storage blocked"));
assert(
  !blockedStorageRoot.classList.contains("theme-light") &&
    !blockedStorageRoot.classList.contains("theme-dark"),
  "bootstrap should tolerate storage failures and fall back to system theme",
);

console.log("PASS theme bootstrap restores stored classes before paint");
