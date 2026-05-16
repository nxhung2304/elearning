class AddStatusToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :status, :integer, null: false, default: 1
    add_index :users, :status
  end
end
