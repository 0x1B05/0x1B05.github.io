const { assert } = require("./helpers/assert");
const { runThemeSwitcher } = require("./helpers/theme-switcher-harness");

function runThemeSwitcherWithoutMatchMedia() {
  const storedValues = new Map();
  const { button, menu, options, root } = runThemeSwitcher({
    localStorage: {
      getItem(key) {
        return storedValues.has(key) ? storedValues.get(key) : null;
      },
      removeItem(key) {
        storedValues.delete(key);
      },
      setItem(key, value) {
        storedValues.set(key, value);
      },
    },
  });
  button.click();
  options.light.click();

  return {
    button,
    menu,
    options,
    root,
    storedValues,
  };
}

const { button, menu, options, root, storedValues } =
  runThemeSwitcherWithoutMatchMedia();

assert(
  root.classList.contains("theme-light"),
  "manual light selection should work when matchMedia is unavailable",
);
assert(
  button.getAttribute("aria-expanded") === "false",
  "theme menu should close after selecting an option",
);
assert(
  button.classList.contains("theme-switcher__button--light"),
  "theme button should track the selected theme",
);
assert(
  button.classList.contains("theme-switcher__button--resolved-light"),
  "theme button should expose the resolved theme for icon styling",
);
assert(
  !menu.classList.contains("is-open"),
  "theme menu should not stay open after a selection",
);
assert(
  options.light.classList.contains("is-active"),
  "light option should become active when matchMedia is unavailable",
);
assert(
  storedValues.get("tufted-theme") === "light",
  "manual theme selection should still persist without matchMedia",
);

console.log("PASS theme switcher stays interactive without matchMedia");
