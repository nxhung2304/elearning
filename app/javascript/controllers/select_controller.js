import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {
    this.element.classList.remove("select", "select-bordered", "select-error")
    this.tomSelect = new TomSelect(this.element, {
      allowEmptyOption: true,
      create: false,
    })
  }

  disconnect() {
    this.tomSelect?.destroy()
  }
}
