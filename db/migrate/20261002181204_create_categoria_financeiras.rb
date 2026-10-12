class CreateCategoriaFinanceiras < ActiveRecord::Migration[8.1]
  def change
    create_table :categoria_financeiras do |t|
      t.string :nome, null: false
      t.string :tipo, null: false

      t.timestamps
    end

    add_index :categoria_financeiras, [ :tipo, :nome ], unique: true
  end
end
