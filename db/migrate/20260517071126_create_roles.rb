class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :code, null: false

      t.timestamps
    end

    add_index :roles, :code, unique: true
  end
end
