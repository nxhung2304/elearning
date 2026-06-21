# == Schema Information
#
# Table name: course_categories
#
#  id           :bigint           not null, primary key
#  ancestry     :string
#  discarded_at :datetime
#  name         :string           not null
#  position     :integer          default(0), not null
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_course_categories_on_ancestry      (ancestry)
#  index_course_categories_on_discarded_at  (discarded_at)
#  index_course_categories_on_slug          (slug) UNIQUE
#
class CourseCategory < ApplicationRecord
  include Discard::Model
  extend FriendlyId

  friendly_id :name, use: %i[slugged finders]
  has_ancestry
  positioned

  # associations
  has_many :courses, foreign_key: "category_id", dependent: :restrict_with_error

  # validations
  validates :name, presence: true
  validates :slug, presence: true

  validate :parent_must_be_kept, if: -> { parent.present? }

  # callbacks
  before_validation :clean_name, if: -> { name.present? }

  before_discard :ensure_subtree_has_no_active_courses
  after_discard :discard_children

  def self.visible_columns = super - %w[ancestry position slug]
  def self.form_columns    = super
  def self.index_columns   = super

  def to_s = name

  def should_generate_new_friendly_id?
    slug.blank?
  end

  private

  def parent_must_be_kept
    errors.add(:parent_id, :invalid) if parent.discarded?
  end

  def discard_children
    children.kept.find_each(&:discard)
  end

  def clean_name
    self.name = name.strip
  end

  def ensure_subtree_has_no_active_courses
    has_active = courses.kept.exists? || descendants.kept.joins(:courses).merge(Course.kept).exists?
    return unless has_active

    errors.add(:base, :has_active_courses)
    throw(:abort)
  end
end
