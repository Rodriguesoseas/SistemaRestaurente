require "test_helper"

class SegurancaNegocioTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @caixa = Caixa.create!(user: @user, saldo_inicial: 100, aberto_em: Time.current)
    @comanda = Comanda.create!(mesa: mesas(:mesa_1), caixa: @caixa, abertura_user: @user, aberta_em: Time.current)
  end

  def adicionar(**attributes)
    @comanda.item_comandas.create!({ produto: produtos(:espeto), quantidade: 1 }.merge(attributes))
  end

  test "stale item cannot change or disappear after payment" do
    item = adicionar
    @comanda.pagar!(forma_pagamento: "pix", usuario: @user)
    item.reload
    assert_not item.update(quantidade: 2)
    assert_not item.destroy
    assert_equal 1.to_d, item.reload.quantidade
    assert_equal 10.to_d, @comanda.reload.valor_total
  end

  test "new item built before payment cannot be added afterwards" do
    item = adicionar
    @comanda.pagar!(forma_pagamento: "pix", usuario: @user)
    assert_no_difference "ItemComanda.count" do
      assert_not item.save
    end
  end

  test "stale caixa cannot accept movements or new comandas" do
    antigo = Caixa.find(@caixa.id)
    # Simula estado externo já fechado para testar associações antigas.
    @caixa.update_columns(status: Caixa::FECHADO)
    mov = MovimentacaoFinanceira.new(caixa: antigo, user: @user,
      categoria_financeira: categoria_financeiras(:venda), tipo: "entrada",
      descricao: "Concorrência", valor: 10, forma_pagamento: "pix", ocorrido_em: Time.current)
    assert_not mov.save
    comanda = Comanda.new(caixa: antigo, mesa: mesas(:mesa_2), abertura_user: @user, aberta_em: Time.current)
    assert_not comanda.save
  end

  test "closing at model level refuses pending comandas" do
    assert_not @caixa.update(status: Caixa::FECHADO, valor_contado: 100, fechado_em: Time.current)
    assert @caixa.reload.aberto?
  end

  test "items require the linked caixa to remain open" do
    item = adicionar
    @caixa.update_columns(status: Caixa::FECHADO)
    assert_not item.update(quantidade: 2)
    assert_not item.destroy
    assert_not @comanda.item_comandas.build(produto: produtos(:espeto), quantidade: 1).save
  end

  test "total is the sum of rounded subtotals" do
    produtos(:espeto).update!(preco_venda: "0.01")
    2.times { adicionar(quantidade: "0.5") }
    assert_equal @comanda.item_comandas.sum(:subtotal), @comanda.reload.valor_total
  end

  test "snapshots cannot be changed directly after creation" do
    item = adicionar
    assert_not item.update(valor_unitario: 1, descricao: "Troca", produto: produtos(:cerveja))
    assert_equal 10.to_d, item.reload.valor_unitario
  end

  test "payment rollback after entry creation preserves occupied table" do
    adicionar
    @comanda.define_singleton_method(:update!) { |**_| raise "Falha após entrada" }
    assert_no_difference "MovimentacaoFinanceira.count" do
      assert_raises(RuntimeError) { @comanda.pagar!(forma_pagamento: "pix", usuario: @user) }
    end
    assert @comanda.reload.aberta?
    assert mesas(:mesa_1).reload.ocupada?
  end

  test "paid comanda and financial history reject regular edits and deletion" do
    adicionar
    mov = @comanda.pagar!(forma_pagamento: "pix", usuario: @user)
    assert_not mov.update(valor: 1)
    assert_not mov.destroy
    assert_not @comanda.update(status: Comanda::ABERTA)
    assert_not @comanda.destroy
  end

  test "invalid stock quantity cannot be coerced into a valid one" do
    mov = MovimentacaoEstoque.new(produto: produtos(:espeto), user: @user,
      tipo: "entrada", quantidade: "2lixo", motivo: "compra", ocorrido_em: Time.current)
    assert_not mov.valid?
    assert_no_difference "MovimentacaoEstoque.count" do
      assert_raises(ActiveRecord::RecordInvalid) do
        MovimentacaoEstoque.registrar!(produto: produtos(:espeto), user: @user,
          tipo: "entrada", quantidade: "0.0004", motivo: "compra")
      end
    end
  end

  test "creating stock movement directly updates balance and freezes history" do
    produto = produtos(:espeto)
    mov = MovimentacaoEstoque.create!(produto: produto, user: @user, tipo: "entrada",
      quantidade: "1.5", motivo: "compra", ocorrido_em: Time.current)
    assert_equal 1.5.to_d, produto.reload.quantidade_atual
    assert_not mov.update(quantidade: 10)
    assert_not mov.destroy
  end
end
