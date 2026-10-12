// Renderiza gráficos via Chartkick + Chart.js (UMD global) após o carregamento.
import { Controller } from "@hotwired/stimulus"
import Chartkick from "chartkick"
import "chart.js"

Chartkick.use(window.Chart)

export default class extends Controller {
  static values = { tipo: String, dados: Array, opcoes: Object }

  connect() {
    const classe = Chartkick[`${this.tipoValue}Chart`]
    if (classe) {
      new classe(this.element, this.dadosValue, this.opcoesValue)
    } else {
      this.element.innerHTML = '<p class="py-10 text-center text-sm text-stone-500">Gráfico indisponível no momento. Os valores estão nas tabelas abaixo.</p>'
    }
  }
}
