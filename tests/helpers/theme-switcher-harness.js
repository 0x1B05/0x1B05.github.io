const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

function createClassList(initialNames = []) {
  const names = new Set(initialNames);

  return {
    add(...tokens) {
      tokens.forEach((token) => names.add(token));
    },
    remove(...tokens) {
      tokens.forEach((token) => names.delete(token));
    },
    contains(token) {
      return names.has(token);
    },
    toggle(token, force) {
      if (force === undefined) {
        if (names.has(token)) {
          names.delete(token);
          return false;
        }

        names.add(token);
        return true;
      }

      if (force) {
        names.add(token);
      } else {
        names.delete(token);
      }

      return force;
    },
  };
}

function createNode(classNames = [], attributes = {}) {
  const listeners = {};
  const values = new Map(Object.entries(attributes));

  return {
    classList: createClassList(classNames),
    addEventListener(type, handler) {
      listeners[type] = handler;
    },
    dispatch(type, event = {}) {
      if (listeners[type]) {
        listeners[type](event);
      }
    },
    click() {
      this.dispatch("click", {
        preventDefault() {},
        target: this,
      });
    },
    contains(node) {
      return node === this;
    },
    getAttribute(name) {
      return values.has(name) ? values.get(name) : null;
    },
    setAttribute(name, value) {
      values.set(name, String(value));
    },
  };
}

function createOption(theme) {
  return createNode([
    "theme-switcher__option",
    "theme-switcher__option--" + theme,
  ]);
}

function createDocument(button, menu, options) {
  const listeners = {};
  const buttonIcons = {
    sun: createNode([
      "theme-switcher__button-icon",
      "theme-switcher__button-icon--sun",
    ]),
    moon: createNode([
      "theme-switcher__button-icon",
      "theme-switcher__button-icon--moon",
    ]),
  };
  const selectorMap = {
    ".theme-switcher__button": button,
    ".theme-switcher__menu": menu,
    ".theme-switcher__button-icon--sun": buttonIcons.sun,
    ".theme-switcher__button-icon--moon": buttonIcons.moon,
  };

  Object.entries(options).forEach(([theme, option]) => {
    selectorMap[".theme-switcher__option--" + theme] = option;
  });

  return {
    documentElement: {
      classList: createClassList(),
    },
    addEventListener(type, handler) {
      listeners[type] = handler;
    },
    dispatch(type, event = {}) {
      if (listeners[type]) {
        listeners[type](event);
      }
    },
    querySelectorAll(selector) {
      if (selector === ".theme-switcher__option") {
        return Object.values(options);
      }

      return [];
    },
    querySelector(selector) {
      return selectorMap[selector] || null;
    },
  };
}

function createMediaQueryList(initialMatches = false) {
  return {
    matches: initialMatches,
    onChange: null,
    addEventListener(type, handler) {
      if (type === "change") {
        this.onChange = handler;
      }
    },
    addListener(handler) {
      this.onChange = handler;
    },
    triggerChange(nextMatches = this.matches) {
      this.matches = nextMatches;
      if (typeof this.onChange === "function") {
        this.onChange();
      }
    },
  };
}

function runThemeSwitcher({ localStorage, matchMedia } = {}) {
  const options = {
    light: createOption("light"),
    dark: createOption("dark"),
    system: createOption("system"),
  };
  const button = createNode(["theme-switcher__button"], {
    "aria-expanded": "false",
  });
  const menu = createNode(["theme-switcher__menu"]);
  const document = createDocument(button, menu, options);
  const context = {
    console,
    document,
    localStorage: localStorage || {
      getItem() {
        return null;
      },
      removeItem() {},
      setItem() {},
    },
    window: {},
  };

  if (typeof matchMedia === "function") {
    context.window.matchMedia = matchMedia;
  }

  context.globalThis = context;
  vm.createContext(context);
  vm.runInContext(
    fs.readFileSync(
      path.join(__dirname, "..", "..", "assets", "theme-switcher.js"),
      "utf8",
    ),
    context,
  );

  document.dispatch("DOMContentLoaded");

  return {
    button,
    menu,
    options,
    root: document.documentElement,
  };
}

module.exports = {
  createClassList,
  createMediaQueryList,
  runThemeSwitcher,
};
