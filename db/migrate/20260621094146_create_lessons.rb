class CreateLessons < ActiveRecord::Migration[8.1]
  def change
    create_table :lessons do |t|
      t.references :section, null: false, foreign_key: true

      t.string :title, null: false
      t.integer :lesson_type, null: false
      t.text :content
      t.string :video_url
      t.integer :duration_seconds
      t.integer :position, null: false
      t.boolean :is_preview, null: false, default: false
      t.boolean :is_published, null: false, default: false
      t.datetime :published_at
      t.datetime :discarded_at

      t.timestamps

      t.index :discarded_at
      t.index [ :section_id, :position ]
    end
  end
end
