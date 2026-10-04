(function () {
  const storageKey = "site-theme";
  const root = document.documentElement;
  const themeClassNames = ["theme-light", "theme-dark"];
  const resolvedClassNames = [
    "theme-switcher__button--resolved-light",
    "theme-switcher__button--resolved-dark",
  ];
  const darkQuery =
    typeof window.matchMedia === "function"
      ? window.matchMedia("(prefers-color-scheme: dark)")
      : null;
  const button = document.querySelector(".theme-switcher__button");
  const menu = document.querySelector(".theme-switcher__menu");
  const options = {
    light: document.querySelector(".theme-switcher__option--light"),
    dark: document.querySelector(".theme-switcher__option--dark"),
    system: document.querySelector(".theme-switcher__option--system"),
  };
  const optionNodes = Object.values(options).filter(Boolean);

  function readStoredTheme() {
    try {
      return localStorage.getItem(storageKey) || "system";
    } catch (_) {
      return "system";
    }
  }

  function writeStoredTheme(theme) {
    try {
      if (theme === "system") {
        localStorage.removeItem(storageKey);
      } else {
        localStorage.setItem(storageKey, theme);
      }
    } catch (_) {
      /* Ignore storage failures and fall back to in-memory theme application. */
    }
  }

  function resolvedTheme(theme) {
    if (theme === "system") {
      return darkQuery && darkQuery.matches ? "dark" : "light";
    }

    return theme;
  }

  let selectedTheme = readStoredTheme();

  /* Menu toggling, outside-click and Escape handling come from dropdown.js
   * (the switcher markup carries data-dropdown attributes); here we only close
   * the panel after a theme is picked. */
  function closeMenu() {
    if (menu) {
      menu.classList.remove("is-open");
    }
    if (button) {
      button.setAttribute("aria-expanded", "false");
    }
  }

  function syncRootTheme(activeTheme) {
    root.classList.remove(...themeClassNames);

    if (activeTheme === "light" || activeTheme === "dark") {
      root.classList.add("theme-" + activeTheme);
    }
  }

  function syncButtonState(activeTheme) {
    if (!button) {
      return;
    }

    button.classList.remove(...resolvedClassNames);
    button.classList.add(
      "theme-switcher__button--resolved-" + resolvedTheme(activeTheme),
    );
  }

  function syncActiveOption(activeTheme) {
    optionNodes.forEach((option) => {
      option.classList.remove("is-active");
    });

    const activeOption = options[activeTheme];
    if (activeOption) {
      activeOption.classList.add("is-active");
    }
  }

  function applyTheme(theme) {
    const activeTheme = theme || "system";

    syncRootTheme(activeTheme);
    syncButtonState(activeTheme);
    syncActiveOption(activeTheme);
  }

  function setTheme(theme) {
    selectedTheme = theme;
    writeStoredTheme(theme);
    applyTheme(theme);
    closeMenu();
  }

  applyTheme(selectedTheme);

  document.addEventListener("DOMContentLoaded", function () {
    Object.entries(options).forEach(([theme, node]) => {
      if (!node) {
        return;
      }

      node.addEventListener("click", function (event) {
        if (event && typeof event.preventDefault === "function") {
          event.preventDefault();
        }

        setTheme(theme);
      });
    });

    applyTheme(selectedTheme);
  });

  function syncWithSystemPreference() {
    if (selectedTheme === "system") {
      applyTheme("system");
    }
  }

  if (darkQuery && typeof darkQuery.addEventListener === "function") {
    darkQuery.addEventListener("change", syncWithSystemPreference);
  } else if (darkQuery && typeof darkQuery.addListener === "function") {
    darkQuery.addListener(syncWithSystemPreference);
  }
})();
