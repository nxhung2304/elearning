# == Schema Information
#
# Table name: sections
#
#  id                  :bigint           not null, primary key
#  discarded_at        :datetime
#  discarded_by_course :boolean          default(FALSE), not null
#  position            :integer          default(0), not null
#  title               :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  course_id           :bigint           not null
#
# Indexes
#
#  index_sections_on_course_id               (course_id)
#  index_sections_on_course_id_and_position  (course_id,position)
#  index_sections_on_discarded_at            (discarded_at)
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#
FactoryBot.define do
  factory :section do
    title { Faker::Lorem.sentence(word_count: 3) }
    position { rand(1..100) }
    association :course

    trait :discarded do
      discarded_at { Time.current }
    end
  end
end
