class AddOtpToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_code, :string, limit: 6
    add_column :users, :otp_sent_at, :datetime
  end
end
