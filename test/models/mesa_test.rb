require "test_helper"

class MesaTest < ActiveSupport::TestCase
  test "requires a unique positive numero" do
    mesa = Mesa.new(numero: 1)
    assert_not mesa.valid?
    assert mesa.errors[:numero].any?

    assert_not Mesa.new(numero: 0).valid?
    assert_not Mesa.new(numero: -2).valid?
  end

  test "is livre without an open comanda" do
    assert mesas(:mesa_1).livre?
    assert_not mesas(:mesa_1).ocupada?
  end

  test "is ocupada with an open comanda" do
    caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)
    comanda = mesas(:mesa_1).comandas.create!(
      caixa: caixa, abertura_user: users(:admin), aberta_em: Time.current, status: Comanda::ABERTA
    )
    assert mesas(:mesa_1).reload.ocupada?
    assert_equal comanda, mesas(:mesa_1).comanda_aberta
  end
end
