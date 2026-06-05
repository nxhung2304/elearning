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

  def self.form_columns
    column_names - RANSACK_DENYLIST - %w[id]
  end

  def self.visible_columns
    form_columns.map do |col|
      if col.end_with?("_id")
        assoc_name = col.delete_suffix("_id").to_sym
        reflect_on_association(assoc_name) ? assoc_name.to_s : col
      else
        col
      end
    end
  end

  def self.index_columns
    visible_columns
  end

  def self.timestamp_columns
    %w[created_at updated_at] & column_names
  end
end
