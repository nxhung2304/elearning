import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button"]

  connect() {
    console.log("File upload controller connected")
  }

  toggle() {
    const hasFile = this.inputTarget.files.length > 0
    this.buttonTargets.forEach((button) => button.classList.toggle("hidden", !hasFile))
  }

  clear() {
    this.inputTarget.value = ""
    this.toggle()
  }
}
