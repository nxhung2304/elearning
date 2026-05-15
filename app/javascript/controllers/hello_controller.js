import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.setAttribute("data-controller-ready", "true")
  }
}
