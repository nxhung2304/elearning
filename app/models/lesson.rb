# == Schema Information
#
# Table name: lessons
#
#  id               :bigint           not null, primary key
#  content          :text
#  discarded_at     :datetime
#  duration_seconds :integer
#  is_preview       :boolean          default(FALSE), not null
#  is_published     :boolean          default(FALSE), not null
#  lesson_type      :integer          not null
#  position         :integer          not null
#  published_at     :datetime
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  section_id       :bigint           not null
#
# Indexes
#
#  index_lessons_on_discarded_at  (discarded_at)
#  index_lessons_on_section_id    (section_id)
#
# Foreign Keys
#
#  fk_rails_...  (section_id => sections.id)
#
class Lesson < ApplicationRecord
  include Discard::Model

  has_one_attached :video

  belongs_to :section
  has_many :lesson_resources, dependent: :restrict_with_error
  has_many :lesson_progresses, dependent: :destroy

  positioned on: :section

  enum :lesson_type, { video: 0, text: 1, mixed: 2 }, validate: true

  validates :title, presence: true
  validates :is_preview, inclusion: { in: [ true, false ] }
  validates :is_published, inclusion: { in: [ true, false ] }
  validates :duration_seconds, presence: true, if: -> { video? || mixed? }
  validates :duration_seconds, absence: true, if: :text?
  validates :content, presence: true, if: -> { text? || mixed? }
  validates :video, attached: true, content_type: VideoUploadable::ACCEPTED_VIDEO_TYPES, if: -> { video? || mixed? }, size: { less_than_or_equal_to: VideoUploadable::MAX_VIDEO_SIZE }

  before_validation :set_is_preview
  before_validation :set_is_published
  before_discard :discard_lesson_resources
  before_undiscard :restore_lesson_resources

  private

  def set_is_preview
    self.is_preview = false if is_preview.nil?
  end

  def set_is_published
    self.is_published = false if is_published.nil?
  end

  def discard_lesson_resources
    lesson_resources.kept.each do |lesson_resource|
      lesson_resource.discard!
      lesson_resource.update! discarded_by_lesson: true
    end
  end

  def restore_lesson_resources
    lesson_resources.need_restore.undiscard_all
    lesson_resources.update_all discarded_by_lesson: false
  end
end
