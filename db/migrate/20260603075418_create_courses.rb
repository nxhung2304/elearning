class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.references :category, null: false, foreign_key: { to_table: :course_categories }
      t.references :teacher, null: false, foreign_key: { to_table: :users }

      t.string :title, null: false
      t.string :slug, null: false
      t.text :description, null: false
      t.integer :level, null: false
      t.integer :language, null: false
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.integer :total_lessons, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :published_at
      t.datetime :discarded_at

      t.timestamps

      t.index :slug, unique: true
      t.index :title, unique: true
      t.index :discarded_at
    end
  end
end
