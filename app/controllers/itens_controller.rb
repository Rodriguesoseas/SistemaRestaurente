class ItensController < ApplicationController
  before_action :set_comanda

  def create
    unless @comanda.aberta?
      redirect_to @comanda, alert: "Esta comanda já foi encerrada."
      return
    end

    produto = Produto.find(item_params[:produto_id])
    @item = @comanda.item_comandas.build(
      produto: produto,
      quantidade: normalize_decimal(item_params[:quantidade]),
      observacao: item_params[:observacao],
      preco_exibido: normalize_decimal(item_params[:preco_exibido]),
      confirmar_preco: item_params[:confirmar_preco]
    )
    if produto.vendavel? && preco_mudou_sem_confirmacao?(produto)
      @preco_mudou_para = produto.preco_venda
      @produtos = Produto.vendaveis
      @itens = @comanda.item_comandas.includes(:produto).order(:id)
      render "comandas/show", status: :unprocessable_content
      return
    end

    if @item.save
      redirect_to @comanda, notice: "Pedido adicionado."
    else
      @produtos = Produto.vendaveis
      @itens = @comanda.item_comandas.includes(:produto).order(:id)
      render "comandas/show", status: :unprocessable_content
    end
  end

  def update
    @item = @comanda.item_comandas.find(params[:id])
    unless @comanda.aberta?
      redirect_to @comanda, alert: "Esta comanda já foi encerrada."
      return
    end

    attributes = { quantidade: normalize_decimal(item_params[:quantidade]) }
    attributes[:observacao] = item_params[:observacao] if item_params.key?(:observacao)
    if @item.update(attributes)
      redirect_to @comanda, notice: "Quantidade atualizada."
    else
      redirect_to @comanda, alert: @item.errors.full_messages.to_sentence
    end
  end

  def destroy
    @item = @comanda.item_comandas.find(params[:id])
    unless @comanda.aberta?
      redirect_to @comanda, alert: "Esta comanda já foi encerrada."
      return
    end

    if @item.destroy
      redirect_to @comanda, notice: "Item removido."
    else
      redirect_to @comanda, alert: @item.errors.full_messages.to_sentence.presence || "Não foi possível remover o item."
    end
  end

  private

  def set_comanda
    @comanda = Comanda.find(params[:comanda_id])
  end

  def item_params
    params.require(:item_comanda).permit(:produto_id, :quantidade, :observacao, :preco_exibido, :confirmar_preco)
  end

def preco_mudou_sem_confirmacao?(produto)
    exibido = item_params[:preco_exibido]
    return false if exibido.blank?
    return false if item_params[:confirmar_preco] == "1"
    return false if produto.preco_venda.nil?

    BigDecimal(normalize_decimal(exibido)) != produto.preco_venda
  rescue ArgumentError, TypeError
    # Valor adulterado/ilegível no campo oculto: exige confirmação em vez de 500.
    true
  end
end
