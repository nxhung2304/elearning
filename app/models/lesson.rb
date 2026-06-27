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

  positioned on: :section

  enum :lesson_type, { video: 0, text: 1, mixed: 2 }, validate: true

  validates :title, presence: true
  validates :is_preview, inclusion: { in: [ true, false ] }
  validates :is_published, inclusion: { in: [ true, false ] }
  validates :video, attached: true, if: -> { video? || mixed? }
  validates :duration_seconds, presence: true, if: -> { video? || mixed? }
  validates :duration_seconds, absence: true, if: :text?
  validates :content, presence: true, if: -> { text? || mixed? }

  before_validation :set_is_preview
  before_validation :set_is_published

  private

  def set_is_preview
    self.is_preview = false if is_preview.nil?
  end

  def set_is_published
    self.is_published = false if is_published.nil?
  end
end
