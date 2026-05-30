import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "preview", "filename" ]

  update() {
    const file = this.inputTarget.files[0]
    
    if (file) {
      const reader = new FileReader()

      reader.onload = (event) => {
        this.previewTarget.src = event.target.result
        this.previewTarget.classList.remove('hidden')
      }

      this.filenameTarget.textContent = file.name

      reader.readAsDataURL(file)
    }
  }
}

