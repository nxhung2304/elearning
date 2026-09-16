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
require "test_helper"

class CourseProgressTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:course_progress).valid?
  end

  context "associations" do
    should belong_to(:enrollment)
  end

  context "validations" do
    should validate_numericality_of(:progress_percentage).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100)
    should validate_presence_of(:progress_percentage)

    should validate_presence_of(:completed_lessons_count)
    should validate_numericality_of(:completed_lessons_count).is_greater_than_or_equal_to(0)
  end

  context "completed_at" do
    should "be auto-set when progress_percentage is equal THRESHOLD" do
      course_progress = build(:course_progress, :with_completed, completed_at: nil)

      assert course_progress.valid?
      assert course_progress.completed_at.present?
    end

    should "not be present if progress_percentage is not equal THRESHOLD" do
      course_progress = build(:course_progress, progress_percentage: 50, completed_at: Time.current)

      assert_not course_progress.valid?
    end

    should "not be in the future" do
      course_progress = build(:course_progress, completed_at: 1.day.from_now)

      assert_not course_progress.valid?
    end
  end
end
