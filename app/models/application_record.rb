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
    discarded_at
  ].freeze

  def self.ransackable_attributes(auth_object = nil)
    column_names - RANSACK_DENYLIST
  end

  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
end
