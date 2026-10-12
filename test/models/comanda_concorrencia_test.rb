require "test_helper"

class ComandaConcorrenciaTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @user_id = users(:admin).id
    @produto_id = produtos(:espeto).id
    @mesa = Mesa.create!(numero: 999, ativo: true)
    @caixa = Caixa.create!(
      user_id: @user_id, saldo_inicial: 0,
      aberto_em: Time.current, status: Caixa::ABERTO
    )
    @comanda = Comanda.create!(
      mesa_id: @mesa.id, caixa_id: @caixa.id, abertura_user_id: @user_id,
      aberta_em: Time.current, status: Comanda::ABERTA
    )
  end

  teardown do
    MovimentacaoFinanceira.where(caixa_id: @caixa.id).delete_all
    ItemComanda.where(comanda_id: @comanda.id).delete_all
    Comanda.where(id: @comanda.id).delete_all
    Caixa.where(id: @caixa.id).delete_all
    Mesa.where(id: @mesa.id).delete_all
  end

  test "concurrent item additions serialize without lost updates" do
    threads = 8.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Comanda.find(@comanda.id).item_comandas.create!(
            produto_id: @produto_id, quantidade: 1
          )
        end
      end
    end
    threads.each(&:join)

    assert_equal 8, ItemComanda.where(comanda_id: @comanda.id).count
    assert_equal BigDecimal("80"), Comanda.find(@comanda.id).valor_total
  end

  test "concurrent payments result in a single financial entry" do
    Comanda.find(@comanda.id).item_comandas.create!(
      produto_id: @produto_id, quantidade: 2
    )

    erros = Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          begin
            Comanda.find(@comanda.id).pagar!(
              forma_pagamento: "pix", usuario: User.find(@user_id)
            )
          rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
            erros << e.class.name
          end
        end
      end
    end
    threads.each(&:join)

    assert_equal 1, erros.size
    assert_equal 1, MovimentacaoFinanceira.where(comanda_id: @comanda.id).count
    assert Comanda.find(@comanda.id).fechada?
    assert Mesa.find(@mesa.id).livre?
  end
end
