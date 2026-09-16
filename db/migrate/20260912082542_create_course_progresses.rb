class CreateCourseProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :course_progresses do |t|
      t.references :enrollment, null: false, foreign_key: true, index: { unique: true }
      t.decimal :progress_percentage, null: false, default: 0, precision: 5, scale: 2
      t.integer :completed_lessons_count, null: false, default: 0
      t.datetime :completed_at

      t.timestamps
    end
  end
end
