# == Schema Information
#
# Table name: roles
#
#  id         :bigint           not null, primary key
#  code       :string           not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_roles_on_code  (code) UNIQUE
#
FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    code { "student" }

    trait :student do
      name { "Student" }
      code { "student" }
    end

    trait :teacher do
      name { "Teacher" }
      code { "teacher" }
    end

    trait :admin do
      name { "Admin" }
      code { "admin" }
    end
  end
end
