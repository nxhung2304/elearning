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

  test "marking completed auto-sets completed_at" do
    lesson_progress = build(:lesson_progress, completed: true, completed_at: nil)

    assert lesson_progress.valid?
    assert_not_nil lesson_progress.completed_at
  end

  test "marking incomplete clears completed_at" do
    lesson_progress = create(:lesson_progress, completed: true)

    lesson_progress.update!(completed: false)

    assert_nil lesson_progress.completed_at
  end

  test "current_position_seconds cannot exceed lesson duration" do
    lesson = create(:lesson, :video, duration_seconds: 60)
    lesson_progress = build(:lesson_progress, lesson: lesson, current_position_seconds: 61)

    assert_not lesson_progress.valid?
    assert_includes lesson_progress.errors[:current_position_seconds], "must be less than or equal to 60"
  end

  test "current_position_seconds equal to lesson duration is valid" do
    lesson = create(:lesson, :video, duration_seconds: 60)
    lesson_progress = build(:lesson_progress, lesson: lesson, current_position_seconds: 60)

    assert lesson_progress.valid?
  end
end
