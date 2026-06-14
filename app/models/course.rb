# == Schema Information
#
# Table name: courses
#
#  id            :bigint           not null, primary key
#  description   :text             not null
#  discarded_at  :datetime
#  language      :integer          not null
#  level         :integer          not null
#  price         :decimal(10, 2)   default(0.0), not null
#  published_at  :datetime
#  slug          :string           not null
#  status        :integer          default("draft"), not null
#  title         :string           not null
#  total_lessons :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  category_id   :bigint           not null
#  teacher_id    :bigint           not null
#
# Indexes
#
#  index_courses_on_category_id   (category_id)
#  index_courses_on_discarded_at  (discarded_at)
#  index_courses_on_slug          (slug) UNIQUE
#  index_courses_on_teacher_id    (teacher_id)
#  index_courses_on_title         (title) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (category_id => course_categories.id)
#  fk_rails_...  (teacher_id => users.id)
#
class Course < ApplicationRecord
  include Discard::Model
  extend FriendlyId

  friendly_id :title, use: %i[slugged finders]

  belongs_to :category, class_name: "CourseCategory", foreign_key: "category_id"
  belongs_to :teacher, class_name: "User", foreign_key: "teacher_id"
  has_many :sections, dependent: :restrict_with_error

  enum :level, { beginner: 0, intermediate: 1, advanced: 2 }, validate: true
  enum :language, { english: 0, vietnamese: 1 }, validate: true
  enum :status, { draft: 0, published: 1, archived: 2 }, validate: true

  validates :title, presence: true
  validates :description, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_lessons, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validates :level, presence: true
  validates :language, presence: true

  validate :published_at_requires_published_status

  before_validation :set_published_at
  before_discard :discard_all_sections
  before_undiscard :restore_sections

  def should_generate_new_friendly_id?
    slug.blank?
  end

  def self.visible_columns = super - %w[slug published_at]

  def self.form_columns = super - %w[slug published_at teacher_id]

  def self.index_columns = %w[title category teacher status price]

  def publish
    update status: :published
  end

  def unpublish
    update status: :draft, published_at: nil
  end

  def archive
    update status: :archived
  end

  private

    def set_published_at
      return unless will_save_change_to_status?

      self.published_at = published? ? Time.current : nil
    end

    def published_at_requires_published_status
      errors.add(:published_at, :status_must_published) if !published? && published_at.present?
    end

    def discard_all_sections
      sections.kept.each do |section|
        section.discard
        section.update! discarded_by_course: true
      end
    end

    def restore_sections
      sections.need_restore.undiscard_all
      sections.update_all discarded_by_course: false
    end
end
