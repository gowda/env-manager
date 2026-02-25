import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  deleteWithConfirmation({ params: { url }, ...event }) {
    event.preventDefault();
    this.dispatch("show", { detail: { url: url } });
  }

  delete({ params: { url }, ...event }) {
    fetch(url, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        Accept: "text/vnd.turbo-stream.html",
      },
    })
      .then((response) => {
        if (response.ok) {
          // Turbo will handle stream response to remove row or refresh
          Turbo.renderStreamMessage(response.body);
        } else {
          alert("Something went wrong.");
        }
      })
      .catch((error) => console.error("Error:", error));
  }
}
