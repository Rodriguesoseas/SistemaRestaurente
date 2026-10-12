require "test_helper"

class MovimentacoesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "requires authentication" do
    sign_out :user
    get movimentacao_financeiras_path
    assert_redirected_to new_user_session_path
  end

  test "lists movimentacoes with filtered totals" do
    get movimentacao_financeiras_path
    assert_response :success
    assert_select "h1", text: "Movimentações"
    assert_select "td", text: /Venda do balcão/
    assert_select "td", text: /Compra de carvão/
    assert_select "dd", text: "R$ 50,00"
    assert_select "dd", text: "R$ 30,00"
    assert_select "dd", text: "R$ 20,00"

    get movimentacao_financeiras_path, params: { tipo: "entrada" }
    assert_response :success
    assert_select "td", text: /Venda do balcão/
    assert_select "td", text: /Compra de carvão/, count: 0

    get movimentacao_financeiras_path, params: { forma_pagamento: "dinheiro" }
    assert_response :success
    assert_select "td", text: /Venda do balcão/
    assert_select "td", text: /Compra de carvão/, count: 0
  end

  test "redirects to caixa when there is no open caixa" do
    get new_movimentacao_financeira_path
    assert_redirected_to caixas_path
    assert_equal "Abra o caixa antes de registrar movimentações.", flash[:alert]

    assert_no_difference "MovimentacaoFinanceira.count" do
      post movimentacao_financeiras_path, params: { movimentacao_financeira: {
        tipo: "entrada", categoria_financeira_id: categoria_financeiras(:venda).id,
        descricao: "Venda", valor: "10,00", forma_pagamento: "dinheiro"
      } }
    end
    assert_redirected_to caixas_path
  end

  test "registers an entrada with pt-BR valor and session user" do
    caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)

    get new_movimentacao_financeira_path
    assert_response :success
    assert_select "form"

    assert_difference "MovimentacaoFinanceira.count", 1 do
      post movimentacao_financeiras_path, params: { movimentacao_financeira: {
        tipo: "entrada", categoria_financeira_id: categoria_financeiras(:venda).id,
        descricao: "Venda do balcão", valor: "1.250,00", forma_pagamento: "pix",
        ocorrido_em: "2026-10-02T10:00"
      } }
    end

    movimentacao = MovimentacaoFinanceira.order(:id).last
    assert_redirected_to movimentacao_financeira_path(movimentacao)
    assert_equal BigDecimal("1250.00"), movimentacao.valor
    assert_equal users(:admin), movimentacao.user
    assert_equal caixa, movimentacao.caixa
    assert_equal "pix", movimentacao.forma_pagamento
    assert_equal BigDecimal("1250"), caixa.reload.entradas
  end

  test "rejects a categoria from another tipo" do
    Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)

    assert_no_difference "MovimentacaoFinanceira.count" do
      post movimentacao_financeiras_path, params: { movimentacao_financeira: {
        tipo: "entrada", categoria_financeira_id: categoria_financeiras(:carvao).id,
        descricao: "Venda", valor: "10,00", forma_pagamento: "dinheiro"
      } }
    end
    assert_response :unprocessable_content
    assert_select "[role=alert]"
  end

  test "rejects an entrada without payment method and a zero valor" do
    Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)

    assert_no_difference "MovimentacaoFinanceira.count" do
      post movimentacao_financeiras_path, params: { movimentacao_financeira: {
        tipo: "entrada", categoria_financeira_id: categoria_financeiras(:venda).id,
        descricao: "Venda", valor: "0", forma_pagamento: ""
      } }
    end
    assert_response :unprocessable_content
  end

  test "registers a saida without payment method" do
    Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)

    assert_difference "MovimentacaoFinanceira.count", 1 do
      post movimentacao_financeiras_path, params: { movimentacao_financeira: {
        tipo: "saida", categoria_financeira_id: categoria_financeiras(:carvao).id,
        descricao: "Compra de carvão", valor: "30,00", forma_pagamento: ""
      } }
    end
    assert_equal "nao_informada", MovimentacaoFinanceira.order(:id).last.forma_pagamento
  end

  test "shows movimentacao details" do
    movimentacao = movimentacao_financeiras(:venda_dinheiro)
    get movimentacao_financeira_path(movimentacao)
    assert_response :success
    assert_select "h1", text: "Detalhes da movimentação"
    assert_select "dd", text: "R$ 50,00"
    assert_select "dd", text: "Dinheiro"
  end

  test "does not expose edit or destroy routes" do
    id = movimentacao_financeiras(:venda_dinheiro).id
    delete "/movimentacoes/#{id}"
    assert_response :not_found
    assert MovimentacaoFinanceira.exists?(id)
  end
end
