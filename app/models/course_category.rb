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

  # validations
  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :slug, presence: true

  validate :parent_must_be_kept, if: -> { parent.present? }

  # callbacks
  before_validation :clean_name, if: -> { name.present? }
  after_discard :discard_children

  def self.visible_columns
    super - %w[ancestry position slug]
  end

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
end
