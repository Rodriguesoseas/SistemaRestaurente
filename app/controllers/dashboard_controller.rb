class DashboardController < ApplicationController
  ULTIMAS_MOVIMENTACOES = 10

  def index
    @filtro = FiltroPeriodo.de_params(params)
    flash.now[:alert] = @filtro.aviso if @filtro.aviso

    movimentacoes = MovimentacaoFinanceira.where(ocorrido_em: @filtro.intervalo)
    totais = movimentacoes.group(:tipo).sum(:valor)
    @total_entradas = totais[MovimentacaoFinanceira::ENTRADA] || BigDecimal("0")
    @total_saidas = totais[MovimentacaoFinanceira::SAIDA] || BigDecimal("0")
    @resultado = @total_entradas - @total_saidas
    @ultimas_movimentacoes = movimentacoes.recentes.limit(ULTIMAS_MOVIMENTACOES)

    @caixa_atual = Caixa.atual
    @mesas_ocupadas = Comanda.abertas.count
    @estoque_baixo_count = Produto.com_estoque_baixo.count
  end
end
