class MovimentacoesController < ApplicationController
  def index
    @filtros = filtros_params
    @movimentacoes = MovimentacaoFinanceira.all
    @movimentacoes = @movimentacoes.where(tipo: @filtros[:tipo]) if @filtros[:tipo].present?
    if @filtros[:categoria_id].present?
      @movimentacoes = @movimentacoes.where(categoria_financeira_id: @filtros[:categoria_id])
    end
    if @filtros[:forma_pagamento].present?
      @movimentacoes = @movimentacoes.where(forma_pagamento: @filtros[:forma_pagamento])
    end

    totais = @movimentacoes.group(:tipo).sum(:valor)
    @total_entradas = totais[MovimentacaoFinanceira::ENTRADA] || BigDecimal("0")
    @total_saidas = totais[MovimentacaoFinanceira::SAIDA] || BigDecimal("0")
    @resultado = @total_entradas - @total_saidas
    @movimentacoes = @movimentacoes.includes(:categoria_financeira, :user, :caixa).recentes
    @categorias = CategoriaFinanceira.ordenadas
  end

  def show
    @movimentacao = MovimentacaoFinanceira.find(params[:id])
  end

  def new
    @caixa_atual = Caixa.atual
    unless @caixa_atual
      redirect_to caixas_path, alert: "Abra o caixa antes de registrar movimentações."
      return
    end

    @movimentacao = MovimentacaoFinanceira.new(tipo: MovimentacaoFinanceira::ENTRADA, ocorrido_em: Time.current)
    carregar_categorias
  end

  def create
    @caixa_atual = Caixa.atual
    unless @caixa_atual
      redirect_to caixas_path, alert: "Abra o caixa antes de registrar movimentações."
      return
    end

    @movimentacao = MovimentacaoFinanceira.new(movimentacao_params)
    @movimentacao.caixa = @caixa_atual
    @movimentacao.user = current_user
    @movimentacao.ocorrido_em ||= Time.current

    if @movimentacao.save
      redirect_to @movimentacao, notice: "Movimentação registrada com sucesso."
    else
      carregar_categorias
      render :new, status: :unprocessable_content
    end
  end

  private

  def filtros_params
    params.permit(:tipo, :categoria_id, :forma_pagamento).tap do |filtrados|
      filtrados[:tipo] = nil unless MovimentacaoFinanceira::TIPOS.include?(filtrados[:tipo])
      filtrados[:forma_pagamento] = nil unless MovimentacaoFinanceira::FORMAS_PAGAMENTO.include?(filtrados[:forma_pagamento])
    end
  end

  def movimentacao_params
    params.require(:movimentacao_financeira).permit(
      :tipo, :categoria_financeira_id, :descricao, :valor, :forma_pagamento, :ocorrido_em
    ).tap do |permitted|
      permitted[:valor] = normalize_decimal(permitted[:valor])
      permitted[:forma_pagamento] = MovimentacaoFinanceira::NAO_INFORMADA if permitted[:forma_pagamento].blank?
    end
  end

  def carregar_categorias
    @categorias_entrada = CategoriaFinanceira.entradas
    @categorias_saida = CategoriaFinanceira.saidas
  end
end
