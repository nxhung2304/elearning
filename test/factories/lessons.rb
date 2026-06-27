# == Schema Information
#
# Table name: lessons
#
#  id               :bigint           not null, primary key
#  content          :text
#  discarded_at     :datetime
#  duration_seconds :integer
#  is_preview       :boolean          default(FALSE), not null
#  is_published     :boolean          default(FALSE), not null
#  lesson_type      :integer          not null
#  position         :integer          not null
#  published_at     :datetime
#  title            :string           not null
#  video_url        :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  section_id       :bigint           not null
#
# Indexes
#
#  index_lessons_on_discarded_at  (discarded_at)
#  index_lessons_on_section_id    (section_id)
#
# Foreign Keys
#
#  fk_rails_...  (section_id => sections.id)
#
FactoryBot.define do
  factory :lesson do
    title { Faker::Lorem.sentence(word_count: 3) }
    lesson_type { 0 }
    content { Faker::Lorem.paragraph }
    video_url { Faker::Internet.url }
    duration_seconds { rand(1..100) }
    is_preview { true }
    is_published { true }
    published_at { nil }
    discarded_at { nil }
    association :section

    trait :text do
      lesson_type { :text }
      video_url { nil }
      duration_seconds { nil }
    end

    trait :video do
      lesson_type { :video }
    end

    trait :mixed do
      lesson_type { :mixed }
      content { Faker::Lorem.paragraph }
      video_url { Faker::Internet.url }
      duration_seconds { rand(1..100) }
    end
  end
end
