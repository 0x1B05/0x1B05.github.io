/* Generic dropdown controller: any [data-dropdown] root with a
 * [data-dropdown-button] toggle and a [data-dropdown-menu] panel. Clicking
 * the button toggles the panel; outside click or Escape closes it. A
 * [data-dropdown-focus] element inside the panel is focused on open. */
(function () {
  function attach(root) {
    const button = root.querySelector("[data-dropdown-button]");
    const menu = root.querySelector("[data-dropdown-menu]");

    if (!button || !menu) {
      return;
    }

    const focusTarget = menu.querySelector("[data-dropdown-focus]");

    function setOpen(isOpen) {
      button.setAttribute("aria-expanded", String(isOpen));
      menu.classList.toggle("is-open", isOpen);

      if (isOpen && focusTarget && typeof focusTarget.focus === "function") {
        focusTarget.focus();
      }
    }

    button.addEventListener("click", function (event) {
      if (event && typeof event.preventDefault === "function") {
        event.preventDefault();
      }

      setOpen(button.getAttribute("aria-expanded") !== "true");
    });

    document.addEventListener("click", function (event) {
      if (!root.contains(event.target)) {
        setOpen(false);
      }
    });

    document.addEventListener("keydown", function (event) {
      if (event && event.key === "Escape") {
        setOpen(false);
      }
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll("[data-dropdown]").forEach(attach);
  });
})();
