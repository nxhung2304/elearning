class CreateSections < ActiveRecord::Migration[8.1]
  def change
    create_table :sections do |t|
      t.references :course, null: false, foreign_key: true

      t.string :title, null: false
      t.integer :position, null: false, default: 0
      t.boolean :discarded_by_course, null: false, default: false
      t.datetime :discarded_at

      t.timestamps

      t.index :discarded_at
      t.index [ :course_id, :position ]
    end
  end
end
