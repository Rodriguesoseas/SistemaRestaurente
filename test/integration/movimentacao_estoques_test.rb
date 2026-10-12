require "test_helper"

class MovimentacaoEstoquesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "requires authentication" do
    sign_out :user
    get movimentacao_estoques_path
    assert_redirected_to new_user_session_path
  end

  test "lists balances and movements with filters" do
    get movimentacao_estoques_path
    assert_response :success
    assert_select "h1", text: "Estoque"
    assert_select "td", text: "Espeto de carne"
    assert_select "td", text: /Sem estoque/
    assert_select "td", text: /Compra/

    get movimentacao_estoques_path, params: { tipo: "saida" }
    assert_response :success
    assert_select "td", text: /Consumo interno/
    assert_select "td", text: /Compra/, count: 0

    get movimentacao_estoques_path, params: { produto_id: produtos(:carvao_interno).id }
    assert_response :success
    assert_select "td", text: /Consumo interno/
    assert_select "td", text: /Compra/, count: 0
  end

  test "registers an entrada with pt-BR quantity and session user" do
    get new_movimentacao_estoque_path
    assert_response :success
    assert_select "form"

    assert_difference "MovimentacaoEstoque.count", 1 do
      post movimentacao_estoques_path, params: { movimentacao_estoque: {
        produto_id: produtos(:espeto).id, tipo: "entrada",
        quantidade: "1,5", motivo: "compra", observacao: "Nota 1",
        ocorrido_em: "2026-10-02T10:00"
      } }
    end
    assert_redirected_to movimentacao_estoques_path

    movimentacao = MovimentacaoEstoque.order(:id).last
    assert_equal BigDecimal("1.5"), movimentacao.quantidade
    assert_equal users(:admin), movimentacao.user
    assert_equal BigDecimal("1.5"), produtos(:espeto).reload.quantidade_atual
  end

  test "blocks a saida greater than the balance" do
    assert_no_difference "MovimentacaoEstoque.count" do
      post movimentacao_estoques_path, params: { movimentacao_estoque: {
        produto_id: produtos(:espeto).id, tipo: "saida",
        quantidade: "2", motivo: "perda"
      } }
    end
    assert_response :unprocessable_content
    assert_select "[role=alert]"
    assert_equal BigDecimal("0"), produtos(:espeto).reload.quantidade_atual
  end

  test "rejects a motivo from another tipo" do
    assert_no_difference "MovimentacaoEstoque.count" do
      post movimentacao_estoques_path, params: { movimentacao_estoque: {
        produto_id: produtos(:cerveja).id, tipo: "entrada",
        quantidade: "1", motivo: "perda"
      } }
    end
    assert_response :unprocessable_content
  end

  test "shows movement details and product history" do
    movimentacao = movimentacao_estoques(:entrada_cerveja)
    get movimentacao_estoque_path(movimentacao)
    assert_response :success
    assert_select "h1", text: "Detalhes da movimentação"
    assert_select "dd", text: "Compra"

    get produto_path(produtos(:cerveja))
    assert_response :success
    assert_select "h2", text: "Histórico de estoque"
    assert_select "td", text: /Compra/
  end

  test "dashboard counts products at or below minimum" do
    get dashboard_path
    assert_response :success
    assert_select "h2", text: "Estoque baixo"
    assert_select "p", text: "1"
  end

  test "does not expose edit or destroy routes" do
    id = movimentacao_estoques(:entrada_cerveja).id
    delete "/estoque/#{id}"
    assert_response :not_found
    assert MovimentacaoEstoque.exists?(id)
  end
end
