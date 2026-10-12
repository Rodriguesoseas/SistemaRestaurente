class CreateMovimentacaoEstoques < ActiveRecord::Migration[8.1]
  def change
    create_table :movimentacao_estoques do |t|
      t.references :produto, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :tipo, null: false
      t.decimal :quantidade, precision: 10, scale: 3, null: false
      t.string :motivo, null: false
      t.string :observacao
      t.datetime :ocorrido_em, null: false

      t.timestamps
    end

    add_index :movimentacao_estoques, :tipo
    add_index :movimentacao_estoques, :ocorrido_em
  end
end
