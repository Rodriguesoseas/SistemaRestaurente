class CreateMovimentacaoFinanceiras < ActiveRecord::Migration[8.1]
  def change
    create_table :movimentacao_financeiras do |t|
      t.references :caixa, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :categoria_financeira, null: false, foreign_key: true
      t.string :tipo, null: false
      t.string :descricao, null: false
      t.decimal :valor, precision: 10, scale: 2, null: false
      t.string :forma_pagamento, null: false, default: "nao_informada"
      t.datetime :ocorrido_em, null: false

      t.timestamps
    end

    add_index :movimentacao_financeiras, :tipo
    add_index :movimentacao_financeiras, :forma_pagamento
    add_index :movimentacao_financeiras, :ocorrido_em
  end
end
