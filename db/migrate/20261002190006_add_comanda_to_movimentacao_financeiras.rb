class AddComandaToMovimentacaoFinanceiras < ActiveRecord::Migration[8.1]
  def change
    add_reference :movimentacao_financeiras, :comanda, foreign_key: true
    add_index :movimentacao_financeiras, :comanda_id, unique: true, name: "index_movimentacoes_on_comanda_unica"
  end
end
