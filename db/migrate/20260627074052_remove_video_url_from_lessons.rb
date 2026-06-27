class RemoveVideoUrlFromLessons < ActiveRecord::Migration[8.1]
  def change
    remove_column :lessons, :video_url, :string
  end
end
