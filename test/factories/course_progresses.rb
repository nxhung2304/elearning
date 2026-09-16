# == Schema Information
#
# Table name: course_progresses
#
#  id                      :bigint           not null, primary key
#  completed_at            :datetime
#  completed_lessons_count :integer          default(0), not null
#  progress_percentage     :decimal(5, 2)    default(0.0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  enrollment_id           :bigint           not null
#
# Indexes
#
#  index_course_progresses_on_enrollment_id  (enrollment_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (enrollment_id => enrollments.id)
#
FactoryBot.define do
  factory :course_progress do
    progress_percentage { rand(1.0..99.0).round(2) }
    completed_lessons_count { rand(1..100) }
    completed_at { nil }
    association :enrollment

    trait :with_completed do
      progress_percentage { CourseProgress::COMPLETION_THRESHOLD }
      completed_lessons_count { rand(1..100) }
    end
  end
end
