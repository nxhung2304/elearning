import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "player", "label"]
  static values = { url: String }

  connect() {
    if (this.urlValue) this.#display(this.urlValue)
  }

  show() {
    const file = this.inputTarget.files[0]
    if (!file) return

    if (this.hasLabelTarget) this.labelTarget.textContent = file.name
    this.#display(URL.createObjectURL(file))
  }

  #display(src) {
    this.playerTarget.src = src
    this.playerTarget.load()
    this.playerTarget.style.display = "block"
  }
}
