import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button"]

  connect() {
    console.log("File upload controller connected")
  }

  toggle() {
    this.buttonTarget.classList.toggle("hidden", !this.inputTarget.files.length)
  }
}
