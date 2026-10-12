require "test_helper"

class ProdutosTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "requires authentication" do
    sign_out :user
    get produtos_path
    assert_redirected_to new_user_session_path
  end

  test "lists products with sale status" do
    get produtos_path
    assert_response :success
    assert_select "h1", text: "Produtos"
    assert_select "td", text: "Espeto de carne"
    assert_select "td", text: /R\$ 10,00/
  end

  test "registers a product with pt-BR prices" do
    assert_difference "Produto.count", 1 do
      post produtos_path, params: { produto: {
        nome: "Espeto de frango", categoria_produto_id: categoria_produtos(:carnes).id,
        unidade: "unidade", preco_venda: "9,00", preco_custo: "3,50",
        estoque_minimo: "5", disponivel_venda: "1", ativo: "1"
      } }
    end
    produto = Produto.order(:id).last
    assert_redirected_to produto_path(produto)
    assert_equal BigDecimal("9.00"), produto.preco_venda
    assert_equal BigDecimal("3.50"), produto.preco_custo
    assert_equal BigDecimal("0"), produto.quantidade_atual
  end

  test "rejects a product for sale without price" do
    assert_no_difference "Produto.count" do
      post produtos_path, params: { produto: {
        nome: "Sem preço", categoria_produto_id: categoria_produtos(:carnes).id,
        unidade: "unidade", preco_venda: "", disponivel_venda: "1", ativo: "1"
      } }
    end
    assert_response :unprocessable_content
  end

  test "inactivates instead of destroying" do
    delete_routes = Rails.application.routes.routes.select do |route|
      route.verb == "DELETE" && route.path.spec.to_s.start_with?("/produtos")
    end
    assert_empty delete_routes
    assert Produto.exists?(produtos(:espeto).id)

    patch produto_path(produtos(:espeto)), params: { produto: { ativo: "0" } }
    assert_redirected_to produto_path(produtos(:espeto))
    assert_not produtos(:espeto).reload.ativo?
  end

  test "shows product details" do
    get produto_path(produtos(:espeto))
    assert_response :success
    assert_select "h1", text: "Espeto de carne"
  end
end
