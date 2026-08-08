class CreateLessonProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_progresses do |t|
      t.references :enrollment, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true

      t.boolean :completed, null: false, default: false
      t.datetime :completed_at
      t.integer :total_watched_seconds
      t.integer :current_position_seconds

      t.timestamps

      t.index [ :enrollment_id, :lesson_id ], unique: true
    end
  end
end
