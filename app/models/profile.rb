# == Schema Information
#
# Table name: profiles
#
#  id           :bigint           not null, primary key
#  avatar_url   :string
#  bio          :text
#  discarded_at :datetime
#  full_name    :string           not null
#  phone        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_profiles_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Profile < ApplicationRecord
  include Discard::Model

  has_one_attached :avatar

  belongs_to :user

  validates :user_id, presence: true, uniqueness: true
  validates :full_name, presence: true
end
