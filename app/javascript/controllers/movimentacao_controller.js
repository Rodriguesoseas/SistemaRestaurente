// Filtra as categorias pela chave data-tipo conforme o tipo de lançamento.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "tipo", "categoria" ]

  connect() {
    this.filtrar()
  }

  filtrar() {
    const tipo = this.tipoTarget.value
    const opcoes = Array.from(this.categoriaTarget.options)
    let primeiraVisivel = null

    opcoes.forEach((opcao) => {
      if (opcao.value === "") return
      const visivel = opcao.dataset.tipo === tipo
      opcao.hidden = !visivel
      if (visivel && primeiraVisivel === null) primeiraVisivel = opcao
    })

    const selecionada = this.categoriaTarget.selectedOptions[0]
    if (!selecionada || selecionada.hidden) {
      this.categoriaTarget.value = primeiraVisivel ? primeiraVisivel.value : ""
    }
  }
}
