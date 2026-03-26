const { assert } = require("./helpers/assert");
const {
  createMediaQueryList,
  runThemeSwitcher,
} = require("./helpers/theme-switcher-harness");

function runThemeSwitcherWithBlockedStorage() {
  const darkQuery = createMediaQueryList();
  const { button, menu, options, root } = runThemeSwitcher({
    localStorage: {
      getItem() {
        throw new Error("storage blocked");
      },
      removeItem() {
        throw new Error("storage blocked");
      },
      setItem() {
        throw new Error("storage blocked");
      },
    },
    matchMedia() {
      return darkQuery;
    },
  });

  button.click();
  options.dark.click();
  darkQuery.triggerChange(true);

  return {
    button,
    menu,
    options,
    root,
  };
}

const { button, menu, options, root } = runThemeSwitcherWithBlockedStorage();

assert(
  root.classList.contains("theme-dark"),
  "manual dark selection should persist after a system preference change",
);
assert(
  button.classList.contains("theme-switcher__button--dark"),
  "theme button should preserve the explicitly selected theme",
);
assert(
  button.classList.contains("theme-switcher__button--resolved-dark"),
  "theme button should keep the dark icon active after manual selection",
);
assert(
  !menu.classList.contains("is-open"),
  "theme menu should close after selecting a theme",
);
assert(
  options.dark.classList.contains("is-active"),
  "dark option should remain active after a system preference change",
);
assert(
  !options.system.classList.contains("is-active"),
  "system option should stay inactive after a manual dark selection",
);

console.log("PASS theme-switcher storage fallback keeps session selection");
