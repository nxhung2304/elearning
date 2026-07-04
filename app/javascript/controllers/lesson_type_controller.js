import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["contentField", "videoField", "durationField"]

  connect() {
    this.#toggle(this.#selectEl.value)
  }

  change(event) {
    this.#toggle(event.target.value)
  }

  #toggle(type) {
    const needsContent = type === "text" || type === "mixed"
    const needsVideo   = type === "video" || type === "mixed"

    this.contentFieldTargets.forEach(el => { el.hidden = !needsContent })
    this.videoFieldTargets.forEach(el => { el.hidden = !needsVideo })
    this.durationFieldTargets.forEach(el => { el.hidden = !needsVideo })
  }

  get #selectEl() {
    return this.element.querySelector("select[name*='lesson_type']")
  }
}
