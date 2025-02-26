import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    delay: Number,
  };

  connect() {
    setTimeout(() => {
      this.element.classList.add(["d-none"]);
    }, this.delayValue || 5000);
  }
}
