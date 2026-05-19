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
FactoryBot.define do
  factory :profile do
    full_name { Faker::Name.name }
    avatar_url { Faker::Internet.url }
    bio { Faker::Lorem.paragraph }
    phone { Faker::PhoneNumber.phone_number }
    association :user
  end
end
