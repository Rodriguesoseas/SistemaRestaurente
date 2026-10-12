class CreateCaixas < ActiveRecord::Migration[8.1]
  def change
    create_table :caixas do |t|
      t.references :user, null: false, foreign_key: true
      t.references :fechamento_user, foreign_key: { to_table: :users }
      t.decimal :saldo_inicial, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: "aberto"
      t.datetime :aberto_em, null: false
      t.datetime :fechado_em
      t.decimal :valor_esperado_dinheiro, precision: 10, scale: 2
      t.decimal :valor_contado, precision: 10, scale: 2
      t.decimal :diferenca, precision: 10, scale: 2

      t.timestamps
    end

    add_index :caixas, :status, unique: true, where: "status = 'aberto'", name: "index_caixas_on_status_aberto"
    add_index :caixas, :aberto_em
  end
end
