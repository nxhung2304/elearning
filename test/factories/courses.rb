# == Schema Information
#
# Table name: courses
#
#  id            :bigint           not null, primary key
#  description   :text             not null
#  discarded_at  :datetime
#  language      :integer          not null
#  level         :integer          not null
#  price         :decimal(10, 2)   default(0.0), not null
#  published_at  :datetime
#  slug          :string           not null
#  status        :integer          default("draft"), not null
#  title         :string           not null
#  total_lessons :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  category_id   :bigint           not null
#  teacher_id    :bigint           not null
#
# Indexes
#
#  index_courses_on_category_id   (category_id)
#  index_courses_on_discarded_at  (discarded_at)
#  index_courses_on_slug          (slug) UNIQUE
#  index_courses_on_teacher_id    (teacher_id)
#  index_courses_on_title         (title) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (category_id => course_categories.id)
#  fk_rails_...  (teacher_id => users.id)
#
FactoryBot.define do
  factory :course do
    association :category, factory: :course_category
    association :teacher, factory: :user
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    level       { :beginner }
    language    { :english }
    price { rand(1.0..100.0).round(2) }
    total_lessons { rand(1..100) }
    status { :draft }
    discarded_at { nil }

    trait :discarded do
      discarded_at { Time.current }
    end

    trait :published do
      status { :published }
    end

    trait :archived do
      status { :archived }
    end
  end
end
