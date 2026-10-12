require "test_helper"

class MovimentacaoFinanceiraTest < ActiveSupport::TestCase
  setup do
    @caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)
  end

  def build_movimentacao(**attributes)
    MovimentacaoFinanceira.new({
      caixa: @caixa,
      user: users(:admin),
      categoria_financeira: categoria_financeiras(:venda),
      tipo: "entrada",
      descricao: "Venda do balcão",
      valor: 50,
      forma_pagamento: "dinheiro",
      ocorrido_em: Time.current
    }.merge(attributes))
  end

  test "is valid with required attributes" do
    assert build_movimentacao.valid?
  end

  test "requires a positive valor" do
    movimentacao = build_movimentacao(valor: 0)
    assert_not movimentacao.valid?
    assert movimentacao.errors[:valor].any?

    movimentacao.valor = -10
    assert_not movimentacao.valid?
  end

  test "requires an explicit payment method for entradas" do
    movimentacao = build_movimentacao(forma_pagamento: "nao_informada")
    assert_not movimentacao.valid?
    assert movimentacao.errors[:forma_pagamento].any?
  end

  test "allows uninformed payment method for saidas" do
    movimentacao = build_movimentacao(
      tipo: "saida",
      categoria_financeira: categoria_financeiras(:carvao),
      forma_pagamento: "nao_informada"
    )
    assert movimentacao.valid?
  end

  test "rejects a categoria from another tipo" do
    movimentacao = build_movimentacao(categoria_financeira: categoria_financeiras(:carvao))
    assert_not movimentacao.valid?
    assert movimentacao.errors[:categoria_financeira].any?
  end

  test "requires an open caixa" do
    movimentacao = build_movimentacao(caixa: caixas(:fechado))
    assert_not movimentacao.valid?
    assert movimentacao.errors[:caixa].any?
  end

  test "requires descricao and ocorrido_em" do
    movimentacao = build_movimentacao(descricao: "", ocorrido_em: nil)
    assert_not movimentacao.valid?
    assert movimentacao.errors[:descricao].any?
    assert movimentacao.errors[:ocorrido_em].any?
  end

  test "rejects future ocorrido_em" do
    movimentacao = build_movimentacao(ocorrido_em: 1.day.from_now)
    assert_not movimentacao.valid?
    assert movimentacao.errors[:ocorrido_em].any?
  end
end
