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
require "test_helper"

class LessonProgressTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:lesson_progress).valid?
  end

  context "associations" do
    should belong_to(:enrollment)
    should belong_to(:lesson)
  end

  context "validations" do
    subject { create(:lesson_progress) }

    should validate_numericality_of(:total_watched_seconds).is_greater_than_or_equal_to(0).allow_nil
    should validate_numericality_of(:current_position_seconds).is_greater_than_or_equal_to(0).allow_nil
    should validate_uniqueness_of(:enrollment_id).scoped_to(:lesson_id)
  end

  test "completed_at is required if completed is true" do
    lesson_progress = build(:lesson_progress, completed: true, completed_at: nil)

    assert_not lesson_progress.valid?
    assert_includes lesson_progress.errors[:completed_at], "can't be blank"
  end
end
