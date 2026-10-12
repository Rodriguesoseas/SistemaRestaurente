class CreateProdutos < ActiveRecord::Migration[8.1]
  def change
    create_table :produtos do |t|
      t.string :nome, null: false
      t.references :categoria_produto, null: false, foreign_key: true
      t.decimal :quantidade_atual, precision: 10, scale: 3, null: false, default: 0
      t.string :unidade, null: false
      t.decimal :estoque_minimo, precision: 10, scale: 3, null: false, default: 0
      t.boolean :ativo, null: false, default: true
      t.decimal :preco_custo, precision: 10, scale: 2
      t.decimal :preco_venda, precision: 10, scale: 2
      t.boolean :disponivel_venda, null: false, default: true

      t.timestamps
    end

    add_index :produtos, [ :ativo, :disponivel_venda ]
  end
end
