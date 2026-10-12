// Preenche o preço exibido conforme o produto selecionado.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "produto", "preco", "precoExibido", "confirmarPreco" ]

  connect() {
    this.atualizar()
  }

  atualizar() {
    const opcao = this.produtoTarget.selectedOptions[0]
    const preco = opcao ? opcao.dataset.preco : ""
    this.precoTarget.textContent = preco === "" ? "—" : `Preço atual: R$ ${preco}`
    if (this.hasPrecoExibidoTarget) {
      this.precoExibidoTarget.value = preco
    }
    if (this.hasConfirmarPrecoTarget) {
      this.confirmarPrecoTarget.value = ""
    }
  }
}
