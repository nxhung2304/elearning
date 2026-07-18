# == Schema Information
#
# Table name: lesson_resources
#
#  id                  :bigint           not null, primary key
#  discarded_at        :datetime
#  discarded_by_lesson :boolean          default(FALSE), not null
#  file_name           :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  lesson_id           :bigint           not null
#
# Indexes
#
#  index_lesson_resources_on_discarded_at  (discarded_at)
#  index_lesson_resources_on_lesson_id     (lesson_id)
#
# Foreign Keys
#
#  fk_rails_...  (lesson_id => lessons.id)
#
FactoryBot.define do
  factory :lesson_resource do
    file_name { Faker::Name.name }
    discarded_at { nil }
    association :lesson

    after(:build) do |r|
      r.file.attach(io: StringIO.new("x"), filename: "test.pdf", content_type: "application/pdf")
    end

    trait :discarded do
      discarded_at { Time.current }
    end
  end
end
