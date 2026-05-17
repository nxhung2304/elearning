# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  status                 :integer          default("active"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_status                (status)
#
FactoryBot.define do
  factory :user do
    email                 { Faker::Internet.unique.email }
    name                  { Faker::Name.name }
    password              { "password123" }
    password_confirmation { "password123" }
    status               { :active }
  end

  trait :inactive do
    status { :inactive }
  end

  trait :suspended do
    status { :suspended }
  end

  trait :deleted do
    status { :deleted }
  end

  trait :admin do
    after(:create) do |user|
      role = Role.find_or_create_by!(code: "admin") { |r| r.name = "Admin" }
      user.roles << role
    end
  end

  trait :teacher do
    after(:create) do |user|
      role = Role.find_or_create_by!(code: "teacher") { |r| r.name = "Teacher" }
      user.roles << role
    end
  end

  trait :student do
    after(:create) do |user|
      role = Role.find_or_create_by!(code: "student") { |r| r.name = "Student" }
      user.roles << role
    end
  end
end
