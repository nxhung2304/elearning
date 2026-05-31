class CreateCourseCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :course_categories do |t|
      t.string :name, null: false
      t.integer :position, default: 0, null: false
      t.datetime :discarded_at
      t.string :ancestry, collation: "C"
      t.string :slug, null: false

      t.timestamps

      t.index :discarded_at
      t.index :ancestry
      t.index :slug, unique: true
    end
  end
end
