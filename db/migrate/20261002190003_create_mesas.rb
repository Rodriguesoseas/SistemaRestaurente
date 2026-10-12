class CreateMesas < ActiveRecord::Migration[8.1]
  def change
    create_table :mesas do |t|
      t.integer :numero, null: false
      t.string :nome
      t.boolean :ativo, null: false, default: true

      t.timestamps
    end

    add_index :mesas, :numero, unique: true
  end
end
