(function () {
  const storageKey = "tufted-theme";
  const root = document.documentElement;
  const themeClassNames = ["theme-light", "theme-dark"];

  function readStoredTheme() {
    try {
      return localStorage.getItem(storageKey) || "system";
    } catch (_) {
      return "system";
    }
  }

  function applyTheme(theme) {
    root.classList.remove(...themeClassNames);

    if (theme === "light" || theme === "dark") {
      root.classList.add("theme-" + theme);
    }
  }

  applyTheme(readStoredTheme());
})();
