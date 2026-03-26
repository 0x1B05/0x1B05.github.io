(function () {
  const storageKey = "tufted-locale";

  function storedLocale() {
    try {
      const locale = localStorage.getItem(storageKey);
      return locale === "en" || locale === "zh" ? locale : null;
    } catch (_) {
      return null;
    }
  }

  function browserLocale() {
    const sources = Array.isArray(navigator.languages) && navigator.languages.length > 0
      ? navigator.languages
      : [navigator.language || "en"];
    const prefersChinese = sources.some((entry) =>
      typeof entry === "string" && entry.toLowerCase().startsWith("zh"),
    );

    return prefersChinese ? "zh" : "en";
  }

  const targetLocale = storedLocale() || browserLocale();
  const pathname = window.location && typeof window.location.pathname === "string"
    ? window.location.pathname
    : "/";
  const normalizedBase = pathname.endsWith("/") ? pathname : pathname + "/";
  const targetPath = normalizedBase + targetLocale + "/";
  const search = window.location && typeof window.location.search === "string"
    ? window.location.search
    : "";
  const hash = window.location && typeof window.location.hash === "string"
    ? window.location.hash
    : "";

  window.location.replace(targetPath + search + hash);
})();
