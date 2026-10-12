require "test_helper"

class CategoriaFinanceiraTest < ActiveSupport::TestCase
  test "requires nome and tipo" do
    categoria = CategoriaFinanceira.new
    assert_not categoria.valid?
    assert categoria.errors[:nome].any?
    assert categoria.errors[:tipo].any?
  end

  test "allows the same nome for different tipos" do
    assert_difference "CategoriaFinanceira.count", 1 do
      CategoriaFinanceira.create!(nome: "Outros", tipo: "saida")
    end
  end

  test "rejects duplicated nome within the same tipo" do
    duplicada = CategoriaFinanceira.new(nome: "venda", tipo: "entrada")
    assert_not duplicada.valid?
    assert duplicada.errors[:nome].any?
  end

  test "database blocks case-insensitive duplicates bypassing validations" do
    duplicada = CategoriaFinanceira.new(nome: "VENDA", tipo: "entrada")
    assert_raises ActiveRecord::RecordNotUnique do
      duplicada.save!(validate: false)
    end
  end

  test "database blocks negative valores bypassing validations" do
    movimentacao = MovimentacaoFinanceira.new(
      caixa: caixas(:fechado), user: users(:admin),
      categoria_financeira: categoria_financeiras(:venda),
      tipo: "entrada", descricao: "X", valor: -1,
      forma_pagamento: "dinheiro", ocorrido_em: Time.current
    )
    assert_raises ActiveRecord::RecordNotSaved do
      movimentacao.save!(validate: false)
    end
  end

  test "exposes entrada and saida scopes" do
    assert_equal %w[Outros Venda], CategoriaFinanceira.entradas.map(&:nome)
    assert_includes CategoriaFinanceira.saidas.map(&:nome), "Carnes"
  end

  test "seeds the default categories idempotently" do
    assert_difference "CategoriaFinanceira.count", 8 do
      CategoriaFinanceira.seed_padrao!
    end
    assert_no_difference "CategoriaFinanceira.count" do
      CategoriaFinanceira.seed_padrao!
    end
    assert_equal %w[Outros Venda], CategoriaFinanceira.entradas.map(&:nome)
    assert_equal 10, CategoriaFinanceira.saidas.count
  end
end
