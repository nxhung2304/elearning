# == Schema Information
#
# Table name: lesson_progresses
#
#  id                       :bigint           not null, primary key
#  completed                :boolean          default(FALSE), not null
#  completed_at             :datetime
#  current_position_seconds :integer
#  total_watched_seconds    :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  enrollment_id            :bigint           not null
#  lesson_id                :bigint           not null
#
# Indexes
#
#  index_lesson_progresses_on_enrollment_id                (enrollment_id)
#  index_lesson_progresses_on_enrollment_id_and_lesson_id  (enrollment_id,lesson_id) UNIQUE
#  index_lesson_progresses_on_lesson_id                    (lesson_id)
#
# Foreign Keys
#
#  fk_rails_...  (enrollment_id => enrollments.id)
#  fk_rails_...  (lesson_id => lessons.id)
#
FactoryBot.define do
  factory :lesson_progress do
    completed { true }
    completed_at { Time.current }
    total_watched_seconds { rand(1..100) }
    current_position_seconds { rand(1..100) }
    association :enrollment
    association :lesson
  end
end
