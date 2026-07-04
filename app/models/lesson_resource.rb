# == Schema Information
#
# Table name: lesson_resources
#
#  id                  :bigint           not null, primary key
#  discarded_at        :datetime
#  discarded_by_lesson :boolean          default(FALSE), not null
#  file_name           :string           not null
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
class LessonResource < ApplicationRecord
  include Discard::Model

  MAX_FILE_SIZE_MB = 10.freeze

  has_one_attached :file

  # associations
  belongs_to :lesson

  # validations
  validates :file_name, presence: true
  validates :file, attached: true, size: { less_than_or_equal_to: MAX_FILE_SIZE_MB.megabytes }
  validates :discarded_by_lesson, inclusion: { in: [ true, false ] }

  # scopes
  scope :need_restore, -> { discarded.where(discarded_by_lesson: true) }
end
