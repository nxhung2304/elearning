# == Schema Information
#
# Table name: user_roles
#
#  id      :bigint           not null, primary key
#  role_id :bigint           not null
#  user_id :bigint           not null
#
# Indexes
#
#  index_user_roles_on_user_id_and_role_id  (user_id,role_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (role_id => roles.id)
#  fk_rails_...  (user_id => users.id)
#
class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role

  validates :user_id, uniqueness: { scope: :role_id }
  validates :user, presence: true
  validates :role, presence: true
end
