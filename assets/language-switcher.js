(function () {
  const storageKey = "tufted-locale";

  function detectLocaleFromPath() {
    const path = window.location && typeof window.location.pathname === "string"
      ? window.location.pathname
      : "";
    const match = path.match(/\/(en|zh)(\/|$)/);

    return match ? match[1] : null;
  }

  const locale = detectLocaleFromPath();

  if (!locale) {
    return;
  }

  try {
    localStorage.setItem(storageKey, locale);
  } catch (_) {
    /* Ignore storage failures and keep navigation fully link-based. */
  }
})();
