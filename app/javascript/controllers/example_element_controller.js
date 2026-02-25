import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {}

  show(event) {
    console.log("Handling show action");
    event.preventDefault();

    // Lookup or create modal instance FRESH each time
    const element = document.getElementById("example-element-list");
    if (!element) {
      console.error("Element not found in DOM!");
      return;
    }

    element.classList.remove("d-none");
  }

  hide(event) {
    console.log("Handling hide action");
    event.preventDefault();

    // Lookup or create modal instance FRESH each time
    const element = document.getElementById("example-element-list");
    if (!element) {
      console.error("Element not found in DOM!");
      return;
    }

    element.classList.add("d-none");
  }
}
