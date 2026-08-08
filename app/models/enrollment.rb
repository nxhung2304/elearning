# == Schema Information
#
# Table name: enrollments
#
#  id                  :bigint           not null, primary key
#  discarded_at        :datetime
#  discarded_by_course :boolean          default(FALSE), not null
#  enrolled_at         :datetime         not null
#  expired_at          :datetime
#  status              :integer          default("active"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  course_id           :bigint           not null
#  user_id             :bigint           not null
#
# Indexes
#
#  index_enrollments_on_course_id              (course_id)
#  index_enrollments_on_discarded_at           (discarded_at)
#  index_enrollments_on_user_id                (user_id)
#  index_enrollments_on_user_id_and_course_id  (user_id,course_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#  fk_rails_...  (user_id => users.id)
#
class Enrollment < ApplicationRecord
  include Discard::Model

  # associations
  belongs_to :user
  belongs_to :course
  has_many :lesson_progresses, dependent: :destroy

  enum :status, { active: 0, completed: 1, expired: 2, revoked: 3 }, default: :active

  validates :user_id, uniqueness: { scope: :course_id }
  validates :status, presence: true
  validates :enrolled_at, presence: true, comparison: { less_than_or_equal_to: -> { Time.current } }
  validates :expired_at, comparison: { greater_than: :enrolled_at }, presence: true, if: -> { expired? }
  validates :discarded_by_course, inclusion: { in: [ true, false ] }

  scope :need_restore, -> { discarded.where(discarded_by_course: true) }
  scope :active, -> { kept.where(status: :active) }

  # callbacks
  before_validation :set_enrolled_at, on: :create

  def activate
    self.status = :active
    self.enrolled_at = Time.current
  end

  private

  def set_enrolled_at
    self.enrolled_at = Time.current if enrolled_at.blank? && active?
  end
end
