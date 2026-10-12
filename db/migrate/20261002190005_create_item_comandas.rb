class CreateItemComandas < ActiveRecord::Migration[8.1]
  def change
    create_table :item_comandas do |t|
      t.references :comanda, null: false, foreign_key: true
      t.references :produto, null: false, foreign_key: true
      t.string :descricao, null: false
      t.decimal :quantidade, precision: 10, scale: 3, null: false
      t.decimal :valor_unitario, precision: 10, scale: 2, null: false
      t.decimal :subtotal, precision: 10, scale: 2, null: false
      t.string :observacao

      t.timestamps
    end
  end
end
