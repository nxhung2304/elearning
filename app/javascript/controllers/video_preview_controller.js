import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  connect() {
    console.log("Connected with VideoPreview")
  }

  show() {
    const file = this.inputTarget.files[0]
    const reader = new FileReader()

    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewTarget.style.display = 'block'
    }

    if (file) {
      reader.readAsDataURL(file)
    }
  }
}
