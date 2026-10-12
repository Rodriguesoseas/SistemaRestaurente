class AddRevisaoFase9Constraints < ActiveRecord::Migration[8.1]
  def change
    # Unicidade case-insensitive, acompanhando as validações dos models.
    remove_index :categoria_financeiras, name: "index_categoria_financeiras_on_tipo_and_nome"
    add_index :categoria_financeiras, "tipo, lower(nome)", unique: true,
      name: "index_categoria_financeiras_on_tipo_and_lower_nome"
    remove_index :categoria_produtos, name: "index_categoria_produtos_on_nome"
    add_index :categoria_produtos, "lower(nome)", unique: true,
      name: "index_categoria_produtos_on_lower_nome"

    # Invariantes numéricas também no PostgreSQL, além das validações.
    add_check_constraint :caixas, "saldo_inicial >= 0", name: "caixas_saldo_inicial_nao_negativo"
    add_check_constraint :movimentacao_financeiras, "valor > 0", name: "movimentacoes_valor_positivo"
    add_check_constraint :item_comandas, "quantidade > 0", name: "itens_quantidade_positiva"
    add_check_constraint :item_comandas, "valor_unitario >= 0", name: "itens_valor_unitario_nao_negativo"
    add_check_constraint :item_comandas, "subtotal >= 0", name: "itens_subtotal_nao_negativo"
    add_check_constraint :produtos, "quantidade_atual >= 0", name: "produtos_saldo_nao_negativo"
    add_check_constraint :produtos, "estoque_minimo >= 0", name: "produtos_minimo_nao_negativo"
    add_check_constraint :produtos, "preco_custo IS NULL OR preco_custo >= 0", name: "produtos_custo_nao_negativo"
    add_check_constraint :produtos, "preco_venda IS NULL OR preco_venda >= 0", name: "produtos_venda_nao_negativo"
    add_check_constraint :comandas, "valor_total >= 0", name: "comandas_total_nao_negativo"
    add_check_constraint :mesas, "numero > 0", name: "mesas_numero_positivo"
    add_check_constraint :movimentacao_estoques, "quantidade > 0", name: "movimentacoes_estoque_quantidade_positiva"
  end
end
