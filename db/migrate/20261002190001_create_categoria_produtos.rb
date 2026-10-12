class CreateCategoriaProdutos < ActiveRecord::Migration[8.1]
  def change
    create_table :categoria_produtos do |t|
      t.string :nome, null: false

      t.timestamps
    end

    add_index :categoria_produtos, :nome, unique: true
  end
end
