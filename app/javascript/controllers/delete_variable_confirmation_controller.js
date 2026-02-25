import { Controller } from "@hotwired/stimulus";
import * as bootstrap from "bootstrap";

export default class extends Controller {
  show({ params: { url }, ...event }) {
    event.preventDefault();
    this.hideStaleBackdrop();

    console.log(`Handling show action for delete button: url=${url}`);

    const modal = this.getModal();
    modal.show();
  }

  confirm() {
    console.log("User confirmed action");
    this.dispatch("confirmed");
  }

  hideStaleBackdrop() {
    const backdrop = document.querySelector(".modal-backdrop");
    if (backdrop) {
      backdrop.remove();
    }
  }

  getModal() {
    const elements = this.element.getElementsByClassName("modal");
    if (!elements) {
      console.error("Modal element not found in DOM!");
      return;
    }

    const modalElement = elements[0];
    return bootstrap.Modal.getOrCreateInstance(modalElement);
  }
}
