require "test_helper"

class ProdutoTest < ActiveSupport::TestCase
  def build_produto(**attributes)
    Produto.new({
      nome: "Espeto de carne",
      categoria_produto: categoria_produtos(:carnes),
      unidade: "unidade",
      preco_venda: 10
    }.merge(attributes))
  end

  test "is valid with required attributes" do
    assert build_produto.valid?
  end

  test "requires preco_venda when disponivel_venda" do
    produto = build_produto(preco_venda: nil)
    assert_not produto.valid?
    assert produto.errors[:preco_venda].any?
  end

  test "allows stock-only products without price" do
    produto = build_produto(preco_venda: nil, disponivel_venda: false)
    assert produto.valid?
    assert_not produto.vendavel?
  end

  test "rejects negative prices and quantities" do
    assert_not build_produto(preco_venda: -1).valid?
    assert_not build_produto(preco_custo: -1).valid?
    assert_not build_produto(quantidade_atual: -1).valid?
    assert_not build_produto(estoque_minimo: -1).valid?
  end

  test "rejects unknown unidade" do
    produto = build_produto(unidade: "fardo")
    assert_not produto.valid?
    assert produto.errors[:unidade].any?
  end

  test "exposes vendaveis scope" do
    nomes = Produto.vendaveis.map(&:nome)
    assert_includes nomes, "Espeto de carne"
    assert_includes nomes, "Cerveja"
    assert_not_includes nomes, "Carvão"
  end

  test "seeds default product categories idempotently" do
    assert_difference "CategoriaProduto.count", 4 do
      CategoriaProduto.seed_padrao!
    end
    assert_no_difference "CategoriaProduto.count" do
      CategoriaProduto.seed_padrao!
    end
    assert_equal 7, CategoriaProduto.count
  end

  test "reports estoque status from balance and minimum" do
    assert_equal :sem_estoque, produtos(:espeto).estoque_status
    assert produtos(:espeto).sem_estoque?
    assert_not produtos(:espeto).estoque_baixo?

    produtos(:cerveja).update!(quantidade_atual: 6)
    assert_equal :baixo, produtos(:cerveja).reload.estoque_status
    assert produtos(:cerveja).estoque_baixo?

    assert_equal :normal, produtos(:carvao_interno).estoque_status
  end

  test "counts active products at or below minimum" do
    assert_equal [ "Espeto de carne" ], Produto.com_estoque_baixo.map(&:nome)
  end
end
