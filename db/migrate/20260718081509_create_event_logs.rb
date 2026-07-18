class CreateEventLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :event_logs do |t|
      t.references :user, null: false, foreign_key: true

      t.string :event_type, null: false
      t.jsonb :metadata

      t.timestamps

      t.index :event_type
      t.index [ :event_type, :created_at ]
      t.index [ :user_id, :event_type ]
    end
  end
end
