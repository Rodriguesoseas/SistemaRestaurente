require "test_helper"

class ComandaTest < ActiveSupport::TestCase
  setup do
    @caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)
    CategoriaFinanceira.seed_padrao!
  end

  def abrir_comanda(mesa = mesas(:mesa_1))
    mesa.comandas.create!(
      caixa: @caixa, abertura_user: users(:admin), aberta_em: Time.current, status: Comanda::ABERTA
    )
  end

  test "allows only one open comanda per mesa" do
    abrir_comanda
    segunda = mesas(:mesa_1).comandas.build(
      caixa: @caixa, abertura_user: users(:admin), aberta_em: Time.current, status: Comanda::ABERTA
    )
    assert_not segunda.valid?

    assert_raises ActiveRecord::RecordNotUnique do
      segunda.save!(validate: false)
    end
  end

  test "requires an open caixa and an active mesa" do
    comanda = mesas(:mesa_1).comandas.build(
      caixa: caixas(:fechado), abertura_user: users(:admin), aberta_em: Time.current, status: Comanda::ABERTA
    )
    assert_not comanda.valid?
    assert comanda.errors[:caixa].any?

    mesa = Mesa.find(mesas(:mesa_1).id)
    mesa.update!(ativo: false)
    comanda = mesa.comandas.build(
      caixa: @caixa, abertura_user: users(:admin), aberta_em: Time.current, status: Comanda::ABERTA
    )
    assert_not comanda.valid?
    assert comanda.errors[:mesa].any?
  end

  test "pagar creates a single venda entry and frees the mesa" do
    comanda = abrir_comanda
    comanda.item_comandas.create!(produto: produtos(:espeto), quantidade: 2)
    comanda.item_comandas.create!(produto: produtos(:cerveja), quantidade: 1)

    assert_difference "MovimentacaoFinanceira.count", 1 do
      comanda.pagar!(forma_pagamento: "pix", usuario: users(:admin))
    end

    comanda.reload
    assert comanda.fechada?
    assert_equal BigDecimal("28"), comanda.valor_total
    assert_equal "pix", comanda.forma_pagamento
    assert_equal users(:admin), comanda.pagamento_user
    assert_not_nil comanda.fechada_em
    assert mesas(:mesa_1).reload.livre?

    movimentacao = comanda.movimentacao_financeira
    assert_equal BigDecimal("28"), movimentacao.valor
    assert_equal "entrada", movimentacao.tipo
    assert_equal "Venda", movimentacao.categoria_financeira.nome
    assert_equal "pix", movimentacao.forma_pagamento
    assert_equal users(:admin), movimentacao.user
    assert_equal @caixa, movimentacao.caixa
    assert_equal BigDecimal("28"), @caixa.reload.entradas
  end

  test "pagar is blocked without value without caixa or twice" do
    comanda = abrir_comanda
    assert_raises ActiveRecord::RecordInvalid do
      comanda.pagar!(forma_pagamento: "pix", usuario: users(:admin))
    end

    comanda.item_comandas.create!(produto: produtos(:espeto), quantidade: 1)
    @caixa.update_columns(status: Caixa::FECHADO)
    @caixa.reload
    assert_raises ActiveRecord::RecordInvalid do
      comanda.pagar!(forma_pagamento: "pix", usuario: users(:admin))
    end
    @caixa.update_columns(status: Caixa::ABERTO)
    @caixa.reload

    comanda.pagar!(forma_pagamento: "pix", usuario: users(:admin))
    assert_raises ActiveRecord::RecordInvalid do
      comanda.pagar!(forma_pagamento: "pix", usuario: users(:admin))
    end
    assert_equal 1, MovimentacaoFinanceira.where(comanda: comanda).count
  end

  test "pagar rolls back everything when the entry fails" do
    comanda = abrir_comanda
    comanda.item_comandas.create!(produto: produtos(:espeto), quantidade: 1)

    original = MovimentacaoFinanceira.method(:create!)
    MovimentacaoFinanceira.define_singleton_method(:create!) do |*args, **kwargs|
      raise ActiveRecord::RecordInvalid, MovimentacaoFinanceira.new
    end
    begin
      assert_no_difference "MovimentacaoFinanceira.count" do
        assert_raises ActiveRecord::RecordInvalid do
          comanda.pagar!(forma_pagamento: "pix", usuario: users(:admin))
        end
      end
    ensure
      MovimentacaoFinanceira.define_singleton_method(:create!, original)
    end

    comanda.reload
    assert comanda.aberta?
    assert_nil comanda.fechada_em
    assert mesas(:mesa_1).reload.ocupada?
  end
end
