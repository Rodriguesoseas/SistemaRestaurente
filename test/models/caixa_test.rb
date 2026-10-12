require "test_helper"

class CaixaTest < ActiveSupport::TestCase
  def build_caixa(**attributes)
    Caixa.new({ user: users(:admin), saldo_inicial: 100, aberto_em: Time.current }.merge(attributes))
  end

  test "requires a non negative opening balance and an opening time" do
    caixa = build_caixa(saldo_inicial: -1)
    assert_not caixa.valid?
    assert caixa.errors.added?(:saldo_inicial, :greater_than_or_equal_to, value: -1, count: 0)

    caixa = build_caixa(saldo_inicial: nil, aberto_em: nil)
    assert_not caixa.valid?
    assert caixa.errors[:saldo_inicial].any?
    assert caixa.errors[:aberto_em].any?
  end

  test "defaults to a non negative balance and stays in the closed fixture history" do
    assert_equal BigDecimal("100.00"), caixas(:fechado).saldo_inicial
    assert caixas(:fechado).fechado?
    assert_equal BigDecimal("-5.00"), caixas(:fechado).diferenca
  end

  test "allows only one open caixa at a time through validations" do
    build_caixa.save!
    segunda = build_caixa
    assert_not segunda.valid?
    assert segunda.errors[:base].any?
  end

  test "database prevents two open caixas even bypassing validations" do
    build_caixa.save!
    assert_raises ActiveRecord::RecordNotUnique do
      build_caixa.save!(validate: false)
    end
  end

  test "allows opening a new caixa after the previous one is closed" do
    build_caixa.save!
    Caixa.aberto.first.update!(status: Caixa::FECHADO, fechado_em: Time.current, valor_contado: 100, valor_esperado_dinheiro: 100)
    assert build_caixa.valid?
  end

  test "requires a non negative counted value to close" do
    caixa = build_caixa(status: Caixa::FECHADO, fechado_em: Time.current)
    assert_not caixa.valid?
    assert caixa.errors[:valor_contado].any?

    caixa.valor_contado = -1
    assert_not caixa.valid?
    assert caixa.errors[:valor_contado].any?
  end

  test "does not modify a closed caixa" do
    caixa = caixas(:fechado)
    caixa.valor_contado = 200
    assert_not caixa.valid?
    assert caixa.errors[:base].any?
  end

  test "computes movement totals and consolidated balance" do
    caixa = build_caixa(saldo_inicial: 100)
    assert_equal BigDecimal("0"), caixa.entradas
    assert_equal BigDecimal("0"), caixa.saidas
    assert_equal BigDecimal("0"), caixa.resultado
    assert_equal BigDecimal("100"), caixa.saldo_consolidado
    assert_equal BigDecimal("100"), caixa.dinheiro_esperado
  end

  test "sums movimentacoes and counts only dinheiro for the expected cash" do
    caixa = build_caixa(saldo_inicial: 100)
    caixa.save!
    venda = CategoriaFinanceira.find_or_create_by!(nome: "Venda", tipo: "entrada")
    carvao = CategoriaFinanceira.find_or_create_by!(nome: "Carvão", tipo: "saida")
    MovimentacaoFinanceira.create!(
      caixa: caixa, user: users(:admin), categoria_financeira: venda,
      tipo: "entrada", descricao: "Venda em dinheiro", valor: 50,
      forma_pagamento: "dinheiro", ocorrido_em: Time.current
    )
    MovimentacaoFinanceira.create!(
      caixa: caixa, user: users(:admin), categoria_financeira: venda,
      tipo: "entrada", descricao: "Venda no pix", valor: 30,
      forma_pagamento: "pix", ocorrido_em: Time.current
    )
    MovimentacaoFinanceira.create!(
      caixa: caixa, user: users(:admin), categoria_financeira: carvao,
      tipo: "saida", descricao: "Compra de carvão", valor: 20,
      forma_pagamento: "dinheiro", ocorrido_em: Time.current
    )

    assert_equal BigDecimal("80"), caixa.entradas
    assert_equal BigDecimal("20"), caixa.saidas
    assert_equal BigDecimal("60"), caixa.resultado
    assert_equal BigDecimal("160"), caixa.saldo_consolidado
    assert_equal BigDecimal("130"), caixa.dinheiro_esperado
    assert_equal({ "dinheiro" => BigDecimal("50"), "pix" => BigDecimal("30") }, caixa.totais_entradas_por_pagamento)
  end

  test "exposes current open caixa scope" do
    assert_nil Caixa.atual
    aberto = build_caixa
    aberto.save!
    assert_equal aberto, Caixa.atual
  end

  test "does not destroy history with movements" do
    assert_not caixas(:fechado).destroy
    assert Caixa.exists?(caixas(:fechado).id)
  end
end
