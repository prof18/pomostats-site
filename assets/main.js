/* PomoStats landing page — two jobs only: the sticky-header hairline and the
   scroll reveal. The theme is not scripted: prefers-color-scheme decides it in
   CSS, so there is nothing to toggle, store or restore. */

(function () {
  "use strict";

  /* ---------- sticky header hairline ---------- */
  var masthead = document.getElementById("masthead");
  if (masthead && "IntersectionObserver" in window) {
    var sentinel = document.createElement("div");
    sentinel.setAttribute("aria-hidden", "true");
    sentinel.style.cssText = "position:absolute;top:0;height:1px;width:1px;";
    document.body.prepend(sentinel);

    new IntersectionObserver(function (entries) {
      masthead.dataset.stuck = String(!entries[0].isIntersecting);
    }).observe(sentinel);
  }

  /* ---------- scroll reveal ----------
     One motion idea, applied consistently: each .reveal rises once as it enters.
     Skipped entirely when the visitor asked for reduced motion, and when
     IntersectionObserver is missing everything is simply shown. */
  var reveals = document.querySelectorAll(".reveal");
  var wantsMotion = !window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if (!wantsMotion || !("IntersectionObserver" in window)) {
    Array.prototype.forEach.call(reveals, function (el) { el.classList.add("is-in"); });
    return;
  }

  /* Trigger generously. The feature rows are as tall as a phone screenshot, so a
     strict threshold would hold a whole row at opacity 0 while it is already on
     screen — which reads as a blank page rather than as an animation. The 240px
     bottom margin starts the reveal just before the row arrives. */
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) return;
      entry.target.classList.add("is-in");
      observer.unobserve(entry.target);
    });
  }, { rootMargin: "0px 0px 240px 0px", threshold: 0 });

  Array.prototype.forEach.call(reveals, function (el, i) {
    /* Stagger only within a burst, so a long page never accumulates a long wait. */
    el.style.setProperty("--d", (i % 4) * 90 + "ms");
    observer.observe(el);
  });
})();
