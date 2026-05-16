import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label", "link", "chevron", "logo", "header"]

  connect() {
    this.collapsed = localStorage.getItem("sidebar-collapsed") === "true"
    this.apply()
  }

  toggle() {
    this.collapsed = !this.collapsed
    localStorage.setItem("sidebar-collapsed", this.collapsed)
    this.apply()
  }

  apply() {
    if (this.collapsed) {
      this.element.classList.replace("w-60", "w-16")
      this.labelTargets.forEach(el => el.classList.add("hidden"))
      this.linkTargets.forEach(el => el.classList.replace("gap-3", "justify-center"))
      this.chevronTarget.classList.add("rotate-180")
      this.logoTarget.classList.add("hidden")
      this.headerTarget.classList.replace("justify-between", "justify-center")
    } else {
      this.element.classList.replace("w-16", "w-60")
      this.labelTargets.forEach(el => el.classList.remove("hidden"))
      this.linkTargets.forEach(el => el.classList.replace("justify-center", "gap-3"))
      this.chevronTarget.classList.remove("rotate-180")
      this.logoTarget.classList.remove("hidden")
      this.headerTarget.classList.replace("justify-center", "justify-between")
    }
  }
}
