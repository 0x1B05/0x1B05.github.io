(function () {
  const QUICK_RESULT_LIMIT = 5;
  const FULL_RESULT_LIMIT = 20;
  let pagefindPromise = null;

  function normalizeQuery(value) {
    return typeof value === "string" ? value.trim() : "";
  }

  function localeFromRoot(root) {
    return (root && root.dataset && root.dataset.searchLocale) || document.documentElement.lang || "en";
  }

  function localeLabelForUrl(url) {
    return /^\/zh(\/|$)/.test(url) ? "中" : "EN";
  }

  function sectionKeyForUrl(url) {
    const match = /^\/(en|zh)(?:\/([^/?#]+))?/.exec(url);
    if (!match) {
      return "home";
    }

    return match[2] || "home";
  }

  function labelsFromRoot(root) {
    const dataset = (root && root.dataset) || {};

    return {
      results: dataset.searchResultsLabel || "Search Results",
      hint: dataset.searchHintLabel || "Enter keywords to search across the whole site.",
      loading: dataset.searchLoadingLabel || "Searching...",
      empty: dataset.searchEmptyLabel || "No results found.",
      error: dataset.searchErrorLabel || "Search is temporarily unavailable.",
      sections: {
        home: dataset.searchSectionHome || "Home",
        docs: dataset.searchSectionDocs || "Docs",
        blog: dataset.searchSectionBlog || "Blog",
        cv: dataset.searchSectionCv || "CV",
      },
    };
  }

  function buildSearchPageUrl(root, query) {
    const locale = localeFromRoot(root);
    const basePath = "/" + locale + "/search/";
    const term = normalizeQuery(query);

    if (!term) {
      return basePath;
    }

    return basePath + "?q=" + encodeURIComponent(term);
  }

  async function loadPagefind() {
    if (!pagefindPromise) {
      pagefindPromise = (async function () {
        const pagefind = await import("/pagefind/pagefind.js");
        if (typeof pagefind.options === "function") {
          await pagefind.options({ baseUrl: "/" });
        }
        if (typeof pagefind.init === "function") {
          await pagefind.init();
        }
        return pagefind;
      })();
    }

    return pagefindPromise;
  }

  function clearNode(node) {
    while (node && node.firstChild) {
      node.removeChild(node.firstChild);
    }
  }

  function setDropdownOpen(dropdown, isOpen) {
    if (!dropdown) {
      return;
    }

    if (isOpen) {
      dropdown.removeAttribute("hidden");
    } else {
      dropdown.setAttribute("hidden", "hidden");
    }
  }

  function setStatus(node, message) {
    if (node) {
      node.textContent = message;
    }
  }

  function sectionLabelForUrl(url, labels) {
    const sectionKey = sectionKeyForUrl(url);
    return labels.sections[sectionKey] || labels.sections.home;
  }

  function titleForResult(result) {
    if (result && result.meta && result.meta.title) {
      return result.meta.title;
    }

    return result && result.url ? result.url : "";
  }

  function renderResults(target, template, results, labels) {
    clearNode(target);

    results.forEach(function (result) {
      const fragment = template.content.cloneNode(true);
      const link = fragment.querySelector(".site-search-result");
      const title = fragment.querySelector(".site-search-result__title");
      const section = fragment.querySelector(".site-search-result__section");
      const locale = fragment.querySelector(".site-search-result__locale");
      const excerpt = fragment.querySelector(".site-search-result__excerpt");

      link.href = result.url;
      title.textContent = titleForResult(result);
      section.textContent = sectionLabelForUrl(result.url, labels);
      locale.textContent = localeLabelForUrl(result.url);
      excerpt.innerHTML = result.excerpt || "";

      target.appendChild(fragment);
    });
  }

  async function fetchResults(query, limit, useDebouncedSearch) {
    const pagefind = await loadPagefind();
    const searchFn = useDebouncedSearch && typeof pagefind.debouncedSearch === "function"
      ? pagefind.debouncedSearch.bind(pagefind)
      : pagefind.search.bind(pagefind);
    const search = await searchFn(query);

    if (search === null) {
      return null;
    }

    const matches = search && Array.isArray(search.results) ? search.results : [];
    return Promise.all(matches.slice(0, limit).map(function (entry) {
      return entry.data();
    }));
  }

  function attachTopBarSearch(root) {
    const form = root.querySelector(".site-search__form");
    const input = root.querySelector(".site-search__input");
    const dropdown = root.querySelector(".site-search__dropdown");
    const status = root.querySelector(".site-search__status");
    const results = root.querySelector(".site-search__results");
    const template = root.querySelector("#site-search-result-template");
    const labels = labelsFromRoot(root);
    let requestId = 0;

    if (!form || !input || !dropdown || !status || !results || !template) {
      return;
    }

    async function runQuery() {
      const query = normalizeQuery(input.value);

      if (!query) {
        clearNode(results);
        setStatus(status, "");
        setDropdownOpen(dropdown, false);
        return;
      }

      const currentRequestId = ++requestId;
      setDropdownOpen(dropdown, true);
      clearNode(results);
      setStatus(status, labels.loading);

      try {
        const fetched = await fetchResults(query, QUICK_RESULT_LIMIT, true);

        if (currentRequestId !== requestId || fetched === null) {
          return;
        }

        if (fetched.length === 0) {
          setStatus(status, labels.empty);
          return;
        }

        setStatus(status, labels.results);
        renderResults(results, template, fetched, labels);
      } catch (_) {
        if (currentRequestId !== requestId) {
          return;
        }

        setStatus(status, labels.error);
      }
    }

    form.addEventListener("submit", function (event) {
      const query = normalizeQuery(input.value);

      event.preventDefault();

      if (!query) {
        setDropdownOpen(dropdown, false);
        return;
      }

      window.location.assign(buildSearchPageUrl(root, query));
    });

    input.addEventListener("focus", function () {
      loadPagefind().catch(function () {
        /* Runtime error is surfaced through explicit search attempts. */
      });

      if (normalizeQuery(input.value)) {
        runQuery();
      }
    });

    input.addEventListener("input", function () {
      runQuery();
    });

    document.addEventListener("click", function (event) {
      if (!root.contains(event.target)) {
        setDropdownOpen(dropdown, false);
      }
    });
  }

  function attachSearchPage(root) {
    const results = document.getElementById("search-results");
    const template = root ? root.querySelector("#site-search-result-template") : null;
    const input = root ? root.querySelector(".site-search__input") : null;
    const labels = labelsFromRoot(root);
    const params = new URLSearchParams(window.location.search || "");
    const query = normalizeQuery(params.get("q"));

    if (!results || !template) {
      return;
    }

    if (input) {
      input.value = query;
    }

    if (!query) {
      results.innerHTML = '<p class="search-page__status"></p>';
      results.firstChild.textContent = labels.hint;
      return;
    }

    results.innerHTML = '<p class="search-page__status"></p>';
    results.firstChild.textContent = labels.loading;

    fetchResults(query, FULL_RESULT_LIMIT, false)
      .then(function (fetched) {
        if (!fetched || fetched.length === 0) {
          results.innerHTML = '<p class="search-page__status"></p>';
          results.firstChild.textContent = labels.empty;
          return;
        }

        clearNode(results);
        renderResults(results, template, fetched, labels);
      })
      .catch(function () {
        results.innerHTML = '<p class="search-page__status"></p>';
        results.firstChild.textContent = labels.error;
      });
  }

  document.addEventListener("DOMContentLoaded", function () {
    const root = document.querySelector(".site-search");

    if (root) {
      attachTopBarSearch(root);
      attachSearchPage(root);
    }
  });
})();
