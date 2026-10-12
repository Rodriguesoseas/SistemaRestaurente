// Filtra os motivos pela chave data-tipo conforme o tipo de movimentação.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "tipo", "motivo" ]

  connect() {
    this.filtrar()
  }

  filtrar() {
    const tipo = this.tipoTarget.value
    const opcoes = Array.from(this.motivoTarget.options)
    let primeiraVisivel = null

    opcoes.forEach((opcao) => {
      if (opcao.value === "") return
      const visivel = opcao.dataset.tipo === tipo
      opcao.hidden = !visivel
      if (visivel && primeiraVisivel === null) primeiraVisivel = opcao
    })

    const selecionada = this.motivoTarget.selectedOptions[0]
    if (!selecionada || selecionada.hidden) {
      this.motivoTarget.value = primeiraVisivel ? primeiraVisivel.value : ""
    }
  }
}
