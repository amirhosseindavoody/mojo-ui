(() => {
  const root = document.documentElement;
  const systemTheme = window.matchMedia("(prefers-color-scheme: dark)");
  const storageKey = "mojo-ui-color-theme";
  let theme;

  try {
    theme = localStorage.getItem(storageKey);
    if (theme === "light" || theme === "dark") {
      root.dataset.theme = theme;
    }
  } catch {
    // The system preference still works when storage is unavailable.
  }

  document.addEventListener("DOMContentLoaded", () => {
    const button = document.getElementById("theme-toggle");
    const choice = document.getElementById("theme-choice");
    const isDark = () => (root.dataset.theme || (systemTheme.matches ? "dark" : "light")) === "dark";
    const update = () => {
      const next = isDark() ? "Light" : "Dark";
      choice.textContent = next;
      button.setAttribute("aria-label", `Use ${next.toLowerCase()} theme`);
    };

    button.addEventListener("click", () => {
      root.dataset.theme = isDark() ? "light" : "dark";
      try {
        localStorage.setItem(storageKey, root.dataset.theme);
      } catch {
        // The current page can still change theme.
      }
      update();
    });

    systemTheme.addEventListener("change", update);
    update();
    button.hidden = false;
  });
})();
