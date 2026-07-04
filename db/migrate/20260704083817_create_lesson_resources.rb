class CreateLessonResources < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_resources do |t|
      t.references :lesson, null: false, foreign_key: true

      t.string :file_name, null: false
      t.datetime :discarded_at
      t.boolean :discarded_by_lesson, default: false, null: false

      t.timestamps

      t.index :discarded_at
    end
  end
end
