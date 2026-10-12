require "test_helper"

class RelatoriosTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "requires authentication" do
    sign_out :user
    get relatorios_path
    assert_redirected_to new_user_session_path
  end

  test "shows summary chart and breakdowns for the month" do
    get relatorios_path, params: { periodo: "mes", ref: "2026-10-15" }
    assert_response :success
    assert_select "h1", text: "Relatórios"
    assert_select "h2", text: "Entradas"
    assert_select "p", text: "R$ 50,00"
    assert_select "h2", text: "Caixas abertos"
    assert_select "h2", text: "Média diária"
    assert_select "p", text: /Resultado ÷ 31 dias corridos/
    assert_select "div[data-controller='chart']", count: 2
    assert_select "dt", text: "Dinheiro"
    assert_select "dt", text: "Carvão"
  end

  test "falls back to hoje with an alert for invalid custom ranges" do
    get relatorios_path, params: { periodo: "personalizado", de: "2026-10-05", ate: "2026-10-01" }
    assert_response :success
    assert_select "p", text: "Hoje"
    assert_select "[role=alert]", text: "Período personalizado inválido. Mostrando hoje."
  end

  test "exports financial movements CSV respecting the period" do
    get movimentacoes_relatorios_path(format: :csv), params: { periodo: "personalizado", de: "2026-10-01", ate: "2026-10-01" }
    assert_response :success
    assert_equal "text/csv", response.media_type
    corpo = response.body
    assert_includes corpo, "Descrição;Tipo;Categoria;Pagamento;Valor;Responsável"
    assert_includes corpo, "Venda do balcão"
    assert_includes corpo, "50,00"

    get movimentacoes_relatorios_path(format: :csv), params: { periodo: "personalizado", de: "2026-09-01", ate: "2026-09-30" }
    assert_response :success
    assert_not_includes response.body, "Venda do balcão"
  end

  test "exports caixas comandas and produtos CSV" do
    get caixas_relatorios_path(format: :csv), params: { periodo: "mes", ref: "2026-10-15" }
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "Saldo inicial;Entradas;Saídas;Resultado"

    get comandas_relatorios_path(format: :csv), params: { periodo: "mes", ref: "2026-10-15" }
    assert_response :success
    assert_includes response.body, "Mesa;Abertura;Fechamento"
    assert_includes response.body, "20,00;Pix;Fechada"

    get produtos_relatorios_path(format: :csv)
    assert_response :success
    assert_includes response.body, "Nome;Categoria;Unidade"
    assert_includes response.body, "Espeto de carne"
  end

  test "redirects html export requests to the report" do
    get movimentacoes_relatorios_path, params: { periodo: "mes", ref: "2026-10-15" }
    assert_redirected_to %r{/relatorios}
  end

  test "neutralizes spreadsheet formulas in CSV text cells" do
    caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)
    MovimentacaoFinanceira.create!(
      caixa: caixa, user: users(:admin), categoria_financeira: categoria_financeiras(:venda),
      tipo: "entrada", descricao: "=1+1", valor: 10,
      forma_pagamento: "dinheiro", ocorrido_em: Time.current
    )

    get movimentacoes_relatorios_path(format: :csv)
    assert_response :success
    assert_includes response.body, "'=1+1"
  end
end
