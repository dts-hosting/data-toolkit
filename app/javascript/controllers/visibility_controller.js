import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["element"];

  hide(event) {
    this.elementTarget.classList.add(["hidden"]);
  }
}
