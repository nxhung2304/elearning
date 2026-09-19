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
class CourseProgress < ApplicationRecord
  COMPLETION_THRESHOLD = 100

  belongs_to :enrollment

  validates :progress_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: COMPLETION_THRESHOLD }
  validates :completed_lessons_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :completed_at, presence: true, if: -> { progress_percentage == COMPLETION_THRESHOLD }

  validate :completed_at_cannot_be_in_the_future, if: -> { completed_at.present? }

  before_validation :sync_completed_at

  private

  def sync_completed_at
    if progress_percentage.to_i >= COMPLETION_THRESHOLD
      self.completed_at ||= Time.current
    else
      self.completed_at = nil
    end
  end

  def completed_at_cannot_be_in_the_future
    return unless completed_at.future?

    errors.add(:completed_at, :must_equal_to_time_current, time: Time.current)
  end
end
