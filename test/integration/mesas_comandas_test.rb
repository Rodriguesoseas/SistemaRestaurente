require "test_helper"

class MesasComandasTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "requires authentication" do
    sign_out :user
    get mesas_path
    assert_redirected_to new_user_session_path
  end

  test "refuses to open a comanda without an open caixa" do
    assert_no_difference "Comanda.count" do
      post comandas_path, params: { mesa_id: mesas(:mesa_1).id }
    end
    assert_redirected_to mesas_path
    assert_equal "Abra o caixa antes de abrir comandas.", flash[:alert]
  end

  test "full flow: open add items change quantity pay and free the mesa" do
    caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)

    get mesas_path
    assert_response :success
    assert_select "h1", text: "Mesas"

    assert_difference "Comanda.count", 1 do
      post comandas_path, params: { mesa_id: mesas(:mesa_1).id }
    end
    comanda = Comanda.order(:id).last
    assert_redirected_to comanda_path(comanda)
    assert_equal caixa, comanda.caixa
    assert_equal users(:admin), comanda.abertura_user

    # Second comanda on the same mesa is refused.
    assert_no_difference "Comanda.count" do
      post comandas_path, params: { mesa_id: mesas(:mesa_1).id }
    end
    assert_redirected_to mesas_path

    # Adds two items with pt-BR quantity.
    assert_difference "ItemComanda.count", 1 do
      post comanda_itens_path(comanda), params: { item_comanda: {
        produto_id: produtos(:espeto).id, quantidade: "2", observacao: "Bem passado",
        preco_exibido: "10,00"
      } }
    end
    assert_difference "ItemComanda.count", 1 do
      post comanda_itens_path(comanda), params: { item_comanda: {
        produto_id: produtos(:cerveja).id, quantidade: "1",
        preco_exibido: "8,00"
      } }
    end
    assert_equal BigDecimal("28"), comanda.reload.valor_total

    # Changes a quantity: unit price snapshot is kept.
    item = comanda.item_comandas.order(:id).first
    patch comanda_item_path(comanda, item), params: { item_comanda: { quantidade: "3" } }
    assert_redirected_to comanda_path(comanda)
    assert_equal BigDecimal("3"), item.reload.quantidade
    assert_equal BigDecimal("10"), item.valor_unitario
    assert_equal BigDecimal("38"), comanda.reload.valor_total

    # Pays via pix: single entry and freed mesa.
    get pagar_comanda_path(comanda)
    assert_response :success
    assert_select "h1", text: "Pagar comanda"

    assert_difference "MovimentacaoFinanceira.count", 1 do
      patch confirmar_pagamento_comanda_path(comanda), params: { comanda: { forma_pagamento: "pix" } }
    end
    assert_redirected_to comanda_path(comanda)
    assert_equal "Pagamento registrado. Mesa 1 liberada.", flash[:notice]
    assert comanda.reload.fechada?
    assert mesas(:mesa_1).reload.livre?

    movimentacao = MovimentacaoFinanceira.order(:id).last
    assert_equal BigDecimal("38"), movimentacao.valor
    assert_equal comanda, movimentacao.comanda
    assert_equal BigDecimal("38"), caixa.reload.entradas

    # Items are frozen after payment.
    assert_no_changes -> { item.reload.quantidade } do
      patch comanda_item_path(comanda, item), params: { item_comanda: { quantidade: "9" } }
    end
    assert_redirected_to comanda_path(comanda)
  end

  test "blocks payment of a zero total comanda" do
    Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)
    post comandas_path, params: { mesa_id: mesas(:mesa_1).id }
    comanda = Comanda.order(:id).last

    assert_no_difference "MovimentacaoFinanceira.count" do
      patch confirmar_pagamento_comanda_path(comanda), params: { comanda: { forma_pagamento: "pix" } }
    end
    assert_redirected_to comanda_path(comanda)
    assert comanda.reload.aberta?
  end

  test "asks for confirmation when the price changed" do
    Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)
    post comandas_path, params: { mesa_id: mesas(:mesa_1).id }
    comanda = Comanda.order(:id).last

    assert_no_difference "ItemComanda.count" do
      post comanda_itens_path(comanda), params: { item_comanda: {
        produto_id: produtos(:espeto).id, quantidade: "1", preco_exibido: "9,00"
      } }
    end
    assert_response :unprocessable_content
    assert_select "[role=alert]", /mudou para R\$ 10,00/

    assert_difference "ItemComanda.count", 1 do
      post comanda_itens_path(comanda), params: { item_comanda: {
        produto_id: produtos(:espeto).id, quantidade: "1", preco_exibido: "9,00", confirmar_preco: "1"
      } }
    end
    assert_equal BigDecimal("10"), comanda.item_comandas.last.valor_unitario
  end

  test "blocks caixa closing with pending comandas and frees after payment" do
    caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)
    post comandas_path, params: { mesa_id: mesas(:mesa_1).id }
    comanda = Comanda.order(:id).last
    post comanda_itens_path(comanda), params: { item_comanda: {
      produto_id: produtos(:espeto).id, quantidade: "1", preco_exibido: "10,00"
    } }

    get fechar_caixa_path(caixa)
    assert_redirected_to caixa_path(caixa)

    patch confirmar_fechamento_caixa_path(caixa), params: { caixa: { valor_contado: "110,00" } }
    assert_redirected_to caixa_path(caixa)
    assert_match /Mesa 1/, flash[:alert]
    assert caixa.reload.aberto?

    patch confirmar_pagamento_comanda_path(comanda), params: { comanda: { forma_pagamento: "dinheiro" } }
    assert comanda.reload.fechada?

    patch confirmar_fechamento_caixa_path(caixa), params: { caixa: { valor_contado: "120,00" } }
    assert_redirected_to caixa_path(caixa)
    assert caixa.reload.fechado?
    assert_equal BigDecimal("110"), caixa.valor_esperado_dinheiro
    assert_equal BigDecimal("10"), caixa.diferenca
  end

  test "lists comandas history and details" do
    get comandas_path
    assert_response :success
    assert_select "h1", text: "Comandas"
    assert_select "td", text: "Mesa 2"

    get comanda_path(comandas(:fechada_mesa2))
    assert_response :success
    assert_select "h3", text: "Espeto de carne"
    assert_select "p", text: "R$ 20,00"
  end
end
