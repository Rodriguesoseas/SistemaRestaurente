class CreateComandas < ActiveRecord::Migration[8.1]
  def change
    create_table :comandas do |t|
      t.references :mesa, null: false, foreign_key: true
      t.references :abertura_user, null: false, foreign_key: { to_table: :users }
      t.references :pagamento_user, foreign_key: { to_table: :users }
      t.references :caixa, null: false, foreign_key: true
      t.string :status, null: false, default: "aberta"
      t.datetime :aberta_em, null: false
      t.datetime :fechada_em
      t.decimal :valor_total, precision: 10, scale: 2, null: false, default: 0
      t.string :forma_pagamento

      t.timestamps
    end

    add_index :comandas, :mesa_id, unique: true, where: "status = 'aberta'", name: "index_comandas_on_mesa_aberta"
    add_index :comandas, :status
    add_index :comandas, :aberta_em
  end
end
