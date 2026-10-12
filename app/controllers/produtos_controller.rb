class ProdutosController < ApplicationController
  before_action :set_produto, only: [ :show, :edit, :update ]

  def index
    @produtos = Produto.includes(:categoria_produto).ordenados
  end

  def show
    @movimentacoes_estoque = @produto.movimentacao_estoques.includes(:user).recentes
  end

  def new
    @produto = Produto.new(ativo: true, disponivel_venda: true)
  end

  def create
    @produto = Produto.new(produto_params)

    if @produto.save
      redirect_to @produto, notice: "Produto cadastrado com sucesso."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @produto.update(produto_params)
      redirect_to @produto, notice: "Produto atualizado com sucesso."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_produto
    @produto = Produto.find(params[:id])
  end

  def produto_params
    params.require(:produto).permit(
      :nome, :categoria_produto_id, :unidade, :estoque_minimo,
      :ativo, :preco_custo, :preco_venda, :disponivel_venda
    ).tap do |permitted|
      %i[preco_custo preco_venda estoque_minimo].each do |campo|
        permitted[campo] = normalize_decimal(permitted[campo]) if permitted.key?(campo)
      end
    end
  end
end
