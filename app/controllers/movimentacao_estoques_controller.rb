class MovimentacaoEstoquesController < ApplicationController
  def index
    @filtros = filtros_params
    @produtos = Produto.includes(:categoria_produto).ordenados
    @movimentacoes = MovimentacaoEstoque.includes(:produto, :user).recentes
    @movimentacoes = @movimentacoes.where(produto_id: @filtros[:produto_id]) if @filtros[:produto_id].present?
    @movimentacoes = @movimentacoes.where(tipo: @filtros[:tipo]) if @filtros[:tipo].present?
    @produtos_filtro = @produtos
  end

  def show
    @movimentacao = MovimentacaoEstoque.find(params[:id])
  end

  def new
    @movimentacao = MovimentacaoEstoque.new(tipo: MovimentacaoEstoque::ENTRADA, ocorrido_em: Time.current)
    @produtos = Produto.ativos
  end

  def create
    @produtos = Produto.ativos
    @movimentacao = MovimentacaoEstoque.new(movimentacao_params.except(:produto_id))
    @movimentacao.produto = @produtos.find_by(id: movimentacao_params[:produto_id])
    @movimentacao.user = current_user
    @movimentacao.ocorrido_em ||= Time.current

    if @movimentacao.produto.nil?
      @movimentacao.errors.add(:produto, "não pode ficar em branco")
      render :new, status: :unprocessable_content
      return
    end

    begin
      MovimentacaoEstoque.registrar!(
        produto: @movimentacao.produto,
        user: @movimentacao.user,
        tipo: @movimentacao.tipo,
        quantidade: @movimentacao.quantidade_before_type_cast,
        motivo: @movimentacao.motivo,
        observacao: @movimentacao.observacao,
        ocorrido_em: @movimentacao.ocorrido_em
      )
      redirect_to movimentacao_estoques_path, notice: "Movimentação de estoque registrada com sucesso."
    rescue ActiveRecord::RecordInvalid => e
      e.record.errors.each do |erro|
        @movimentacao.errors.add(erro.attribute, erro.message) unless @movimentacao.errors.added?(erro.attribute, erro.message)
      end
      render :new, status: :unprocessable_content
    end
  end

  private

  def filtros_params
    params.permit(:tipo, :produto_id).tap do |filtrados|
      filtrados[:tipo] = nil unless MovimentacaoEstoque::TIPOS.include?(filtrados[:tipo])
    end
  end

  def movimentacao_params
    params.require(:movimentacao_estoque).permit(
      :produto_id, :tipo, :quantidade, :motivo, :observacao, :ocorrido_em
    ).tap do |permitted|
      permitted[:quantidade] = normalize_decimal(permitted[:quantidade]) if permitted.key?(:quantidade)
    end
  end
end
