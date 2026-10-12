class ComandasController < ApplicationController
  before_action :set_comanda, only: [ :show, :pagar, :confirmar_pagamento ]

  def index
    @filtro_status = params[:status] if Comanda::STATUSES.include?(params[:status])
    @comandas = Comanda.includes(:mesa, :abertura_user).recentes
    @comandas = @comandas.where(status: @filtro_status) if @filtro_status
  end

  def show
    @item = @comanda.item_comandas.build
    @produtos = Produto.vendaveis
    @itens = @comanda.item_comandas.includes(:produto).order(:id)
  end

  def create
    mesa = Mesa.find(params[:mesa_id])
    caixa_atual = Caixa.atual
    unless caixa_atual
      redirect_to mesas_path, alert: "Abra o caixa antes de abrir comandas."
      return
    end

    comanda = mesa.comandas.build(
      caixa: caixa_atual,
      abertura_user: current_user,
      aberta_em: Time.current,
      status: Comanda::ABERTA
    )
    begin
      if comanda.save
        redirect_to comanda, notice: "Comanda aberta para a Mesa #{mesa.numero}."
      else
        redirect_to mesas_path, alert: comanda.errors.full_messages.to_sentence
      end
    rescue ActiveRecord::RecordNotUnique
      redirect_to mesas_path, alert: "A Mesa #{mesa.numero} já possui comanda aberta."
    end
  end

  def pagar
    unless @comanda.aberta?
      redirect_to @comanda, alert: "Esta comanda já foi encerrada."
      return
    end
    # Somente recalcula em memória para exibição; a persistência
    # acontece dentro da transação de confirmar_pagamento.
    @comanda.assign_attributes(valor_total: @comanda.total_calculado.round(2))
  end

  def confirmar_pagamento
    unless @comanda.aberta?
      redirect_to @comanda, alert: "Esta comanda já foi encerrada."
      return
    end

    forma = params.require(:comanda).permit(:forma_pagamento)[:forma_pagamento]
    unless MovimentacaoFinanceira::FORMAS_EXPLICITAS.include?(forma)
      redirect_to pagar_comanda_path(@comanda), alert: "Escolha a forma de pagamento."
      return
    end

    begin
      @comanda.pagar!(forma_pagamento: forma, usuario: current_user)
      redirect_to @comanda, notice: "Pagamento registrado. Mesa #{@comanda.mesa.numero} liberada."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to @comanda, alert: e.record.errors.full_messages.to_sentence
    rescue ActiveRecord::RecordNotUnique
      redirect_to @comanda, notice: "Pagamento já registrado para esta comanda."
    end
  end

  private

  def set_comanda
    @comanda = Comanda.includes(:mesa, :abertura_user, :pagamento_user).find(params[:id])
  end
end
