# == Schema Information
#
# Table name: course_categories
#
#  id           :bigint           not null, primary key
#  ancestry     :string
#  discarded_at :datetime
#  name         :string           not null
#  position     :integer          default(0), not null
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_course_categories_on_ancestry      (ancestry)
#  index_course_categories_on_discarded_at  (discarded_at)
#  index_course_categories_on_slug          (slug) UNIQUE
#
FactoryBot.define do
  factory :course_category do
    name { Faker::Commerce.department }
    slug { nil }
    position { rand(1..100) }

    trait :with_parent do
      association :parent, factory: :course_category
    end
  end
end
