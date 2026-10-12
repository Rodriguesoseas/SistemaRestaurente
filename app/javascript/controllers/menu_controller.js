import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "panel"]

  toggle() {
    this.setOpen(this.buttonTarget.getAttribute("aria-expanded") !== "true")
  }

  close(event) {
    const wasOpen = this.buttonTarget.getAttribute("aria-expanded") === "true"
    this.setOpen(false)
    if (wasOpen && event?.type === "keydown") this.buttonTarget.focus()
  }

  setOpen(open) {
    this.panelTarget.classList.toggle("hidden", !open)
    this.buttonTarget.setAttribute("aria-expanded", String(open))
    this.buttonTarget.setAttribute("aria-label", open ? "Fechar menu" : "Abrir menu")
  }
}
