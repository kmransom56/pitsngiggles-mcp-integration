(function () {
  function initAIDrawer() {
    var drawer = document.getElementById("png-ai-drawer");
    var backdrop = document.getElementById("png-ai-drawer-backdrop");
    var iframe = document.getElementById("png-ai-drawer-iframe");
    var chatBtn = document.getElementById("strategy-center-btn");
    var voiceBtn = document.getElementById("voice-strategy-center-btn");
    var closeBtn = document.getElementById("png-ai-drawer-close");
    var tabs = document.querySelectorAll(".png-ai-drawer-tab");
    var footerLink = document.getElementById("png-ai-drawer-footer-link");
    var lastFocus = null;
    if (!drawer || !backdrop || !iframe) {
      return;
    }

    function setTabActive(tab) {
      tabs.forEach(function (t) {
        var on = t.getAttribute("data-tab") === tab;
        t.classList.toggle("active", on);
        t.setAttribute("aria-selected", on ? "true" : "false");
      });
    }

    function setFooterForTab(tab) {
      if (!footerLink) {
        return;
      }
      if (tab === "voice") {
        footerLink.setAttribute("href", "/voice-strategy-center");
        footerLink.textContent = "Open full voice layout with telemetry pane";
      } else {
        footerLink.setAttribute("href", "/strategy-center");
        footerLink.textContent = "Open full layout with telemetry pane";
      }
    }

    function loadTab(tab) {
      var src =
        tab === "voice"
          ? "/voice-strategy-center?embed=chat"
          : "/strategy-center?embed=chat";
      iframe.setAttribute("data-active-tab", tab);
      if (tab === "voice") {
        iframe.setAttribute("allow", "microphone; autoplay");
        iframe.setAttribute("title", "AI Race Engineer — Voice");
      } else {
        iframe.removeAttribute("allow");
        iframe.setAttribute("title", "AI Race Engineer — Chat");
      }
      iframe.src = src;
      setTabActive(tab);
      setFooterForTab(tab);
    }

    function openDrawer(tab) {
      lastFocus = document.activeElement;
      loadTab(tab || "chat");
      drawer.classList.add("open");
      backdrop.classList.add("open");
      drawer.setAttribute("aria-hidden", "false");
      backdrop.setAttribute("aria-hidden", "false");
      document.body.classList.add("png-ai-drawer-open");
      requestAnimationFrame(function () {
        if (closeBtn) {
          closeBtn.focus();
        }
      });
    }

    function closeDrawer() {
      drawer.classList.remove("open");
      backdrop.classList.remove("open");
      drawer.setAttribute("aria-hidden", "true");
      backdrop.setAttribute("aria-hidden", "true");
      document.body.classList.remove("png-ai-drawer-open");
      if (lastFocus && typeof lastFocus.focus === "function") {
        try {
          lastFocus.focus();
        } catch (e) {}
      }
      lastFocus = null;
    }

    if (chatBtn) {
      chatBtn.addEventListener("click", function () {
        openDrawer("chat");
      });
    }
    if (voiceBtn) {
      voiceBtn.addEventListener("click", function () {
        openDrawer("voice");
      });
    }
    if (closeBtn) {
      closeBtn.addEventListener("click", closeDrawer);
    }
    backdrop.addEventListener("click", closeDrawer);

    tabs.forEach(function (tabEl) {
      tabEl.addEventListener("click", function () {
        var tab = tabEl.getAttribute("data-tab");
        if (tab) {
          loadTab(tab);
        }
      });
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && drawer.classList.contains("open")) {
        closeDrawer();
      }
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initAIDrawer);
  } else {
    initAIDrawer();
  }
})();
