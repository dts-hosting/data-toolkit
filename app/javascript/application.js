// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

import LocalTime from "local-time";

LocalTime.start();
document.addEventListener("turbo:morph", () => {
  LocalTime.run();
});

document.addEventListener("turbo:load", () => {
  const collapses = document.querySelectorAll('[data-bs-toggle="collapse"]');
  collapses.forEach((el) => {
    const target = document.querySelector(el.getAttribute("href"));
    if (target && !bootstrap.Collapse.getInstance(target)) {
      new bootstrap.Collapse(target, { toggle: false });
    }
  });
});
