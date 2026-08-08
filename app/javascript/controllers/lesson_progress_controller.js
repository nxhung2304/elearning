import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    url: String,
    lastPositionSeconds: Number,
    completed: Boolean,
    completeText: String,
    incompleteText: String,
    completeClass: String,
    incompleteClass: String,
  };

  pause() {
    this.sendProgress();
  }

  ended() {
    this.sendProgress();
  }

  seeked() {
    this.sendProgress();
  }

  patch(bodyData) {
    const token = document.querySelector("meta[name='csrf-token']").content;

    return fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
      },
      body: JSON.stringify({
        lesson_progress: bodyData,
      }),
    });
  }

  async sendProgress() {
    try {
      const response = await this.patch({
        current_position_seconds: Math.floor(this.element.currentTime),
      });
      if (!response.ok) {
        console.error("Failed to save lesson progress:", response.status);
      }
    } catch (error) {
      console.error("Error saving lesson progress:", error);
    }
  }

  async toggleCompletion() {
    try {
      let response = await this.patch({ completed: !this.completedValue });
      if (!response.ok) return;

      const lessonProgress = await response.json();
      this.completedValue = lessonProgress.completed;

      this._updateButton();
    } catch (error) {
      console.error("Error toggling completion:", error);
    }
  }

  _updateButton() {
    this.element.textContent = this.completedValue
      ? this.incompleteTextValue
      : this.completeTextValue;

    this.element.className = this.completedValue
      ? this.completeClassValue
      : this.incompleteClassValue;
  }

  restore() {
    this.element.currentTime = this.lastPositionSecondsValue;
  }
}
