require "test_helper"

class MovimentacaoEstoqueTest < ActiveSupport::TestCase
  def registrar(**attributes)
    MovimentacaoEstoque.registrar!(**{
      produto: produtos(:espeto),
      user: users(:admin),
      tipo: "entrada",
      quantidade: 10,
      motivo: "compra",
      ocorrido_em: Time.current
    }.merge(attributes))
  end

  test "entrada increases the balance" do
    assert_difference "MovimentacaoEstoque.count", 1 do
      movimentacao = registrar()
      assert movimentacao.entrada?
      assert_equal "Compra", movimentacao.motivo_rotulo
    end
    assert_equal BigDecimal("10"), produtos(:espeto).reload.quantidade_atual
  end

  test "saida decreases the balance" do
    registrar(quantidade: 10)
    registrar(tipo: "saida", motivo: "consumo_interno", quantidade: "2.5")
    assert_equal BigDecimal("7.5"), produtos(:espeto).reload.quantidade_atual
  end

  test "never allows a negative balance" do
    assert_no_difference "MovimentacaoEstoque.count" do
      assert_raises ActiveRecord::RecordInvalid do
        registrar(tipo: "saida", motivo: "perda", quantidade: 1)
      end
    end
    assert_equal BigDecimal("0"), produtos(:espeto).reload.quantidade_atual
  end

  test "rejects future ocorrido_em" do
    assert_raises ActiveRecord::RecordInvalid do
      registrar(ocorrido_em: 1.day.from_now)
    end
  end

  test "requires a positive quantity and a compatible motivo" do
    assert_raises ActiveRecord::RecordInvalid do
      registrar(quantidade: 0)
    end
    assert_raises ActiveRecord::RecordInvalid do
      registrar(motivo: "perda")
    end
    assert_raises ActiveRecord::RecordInvalid do
      registrar(tipo: "saida", motivo: "compra", quantidade: 1)
    end
  end

  test "exposes recent movements per product" do
    registrar(quantidade: 5)
    historico = MovimentacaoEstoque.where(produto: produtos(:espeto)).recentes
    assert_equal 1, historico.count
    assert_equal users(:admin), historico.first.user
  end
end

class MovimentacaoEstoqueConcorrenciaTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @produto = Produto.create!(
      nome: "Produto concorrência",
      categoria_produto: categoria_produtos(:carnes),
      unidade: "unidade",
      disponivel_venda: false
    )
    MovimentacaoEstoque.registrar!(
      produto: @produto,
      user: users(:admin),
      tipo: "entrada",
      quantidade: 100,
      motivo: "compra",
      ocorrido_em: Time.current
    )
  end

  teardown do
    MovimentacaoEstoque.where(produto_id: @produto.id).delete_all
    @produto.delete
  end

  test "keeps the balance correct under concurrent saidas" do
    threads = 10.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          MovimentacaoEstoque.registrar!(
            produto: Produto.find(@produto.id),
            user: User.find(users(:admin).id),
            tipo: "saida",
            quantidade: 3,
            motivo: "consumo_interno",
            ocorrido_em: Time.current
          )
        end
      end
    end
    threads.each(&:join)
    assert_equal BigDecimal("70"), @produto.reload.quantidade_atual
    assert_equal 11, MovimentacaoEstoque.where(produto_id: @produto.id).count
  end
end
