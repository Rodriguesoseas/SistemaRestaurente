require "test_helper"

class ItemComandaTest < ActiveSupport::TestCase
  setup do
    @caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)
    @comanda = mesas(:mesa_1).comandas.create!(
      caixa: @caixa, abertura_user: users(:admin), aberta_em: Time.current, status: Comanda::ABERTA
    )
  end

  test "snapshots descricao and valor_unitario from the product" do
    item = @comanda.item_comandas.create!(produto: produtos(:espeto), quantidade: 2, descricao: "Texto arbitrário", valor_unitario: 999)
    assert_equal "Espeto de carne", item.descricao
    assert_equal BigDecimal("10"), item.valor_unitario
    assert_equal BigDecimal("20"), item.subtotal
    assert_equal BigDecimal("20"), @comanda.reload.valor_total
  end

  test "supports fractional quantities" do
    item = @comanda.item_comandas.create!(produto: produtos(:espeto), quantidade: "1.5")
    assert_equal BigDecimal("1.5"), item.quantidade
    assert_equal BigDecimal("15"), item.subtotal
  end

  test "requires a positive quantity and a vendavel product" do
    item = @comanda.item_comandas.build(produto: produtos(:espeto), quantidade: 0)
    assert_not item.valid?
    assert item.errors[:quantidade].any?

    item = @comanda.item_comandas.build(produto: produtos(:carvao_interno), quantidade: 1)
    assert_not item.valid?
    assert item.errors[:produto].any?
  end

  test "keeps historical prices when the product price changes" do
    item = @comanda.item_comandas.create!(produto: produtos(:espeto), quantidade: 1)
    produtos(:espeto).update!(preco_venda: 12)
    assert_equal BigDecimal("10"), item.reload.valor_unitario
    assert_equal BigDecimal("10"), item.subtotal
  end

  test "does not change stock" do
    assert_no_changes -> { produtos(:espeto).reload.quantidade_atual } do
      @comanda.item_comandas.create!(produto: produtos(:espeto), quantidade: 2)
    end
  end

  test "freezes items of a closed comanda" do
    item = @comanda.item_comandas.create!(produto: produtos(:espeto), quantidade: 1)
    @comanda.update_columns(status: Comanda::FECHADA)

    item.quantidade = 5
    assert_not item.valid?
    assert item.errors[:comanda].any?
    assert_raises(ActiveRecord::RecordNotDestroyed) { item.destroy! }
  end
end
