class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  RANSACK_DENYLIST = %w[
    encrypted_password
    reset_password_token
    reset_password_sent_at
    remember_created_at
    confirmation_token
    unconfirmed_email
    created_at
    updated_at
  ].freeze

  def self.ransackable_attributes(auth_object = nil)
    column_names - RANSACK_DENYLIST
  end

  def self.displayable_columns
    column_names - RANSACK_DENYLIST - %w[id]
  end

  def self.timestamp_columns
    %w[created_at updated_at] & column_names
  end
end
