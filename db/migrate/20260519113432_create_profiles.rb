class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      t.string :full_name, null: false
      t.string :avatar_url
      t.text :bio
      t.string :phone
      t.datetime :discarded_at

      t.timestamps
    end
  end
end
