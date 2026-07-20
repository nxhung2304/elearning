class CreateEnrollments < ActiveRecord::Migration[8.1]
  def change
    create_table :enrollments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true

      t.integer :status, null: false, default: 0
      t.datetime :enrolled_at, null: false
      t.datetime :expired_at
      t.datetime :discarded_at
      t.boolean :discarded_by_course, default: false, null: false

      t.timestamps

      t.index [ :user_id, :course_id ], unique: true
      t.index :discarded_at
    end
  end
end
