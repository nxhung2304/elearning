# == Schema Information
#
# Table name: sections
#
#  id                  :bigint           not null, primary key
#  discarded_at        :datetime
#  discarded_by_course :boolean          default(FALSE), not null
#  position            :integer          default(0), not null
#  title               :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  course_id           :bigint           not null
#
# Indexes
#
#  index_sections_on_course_id               (course_id)
#  index_sections_on_course_id_and_position  (course_id,position)
#  index_sections_on_discarded_at            (discarded_at)
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#
class Section < ApplicationRecord
  include Discard::Model

  positioned on: :course

  # associations
  belongs_to :course

  # validations
  validates :title, presence: true

  # scopes
  scope :need_restore, -> { discarded.where(discarded_by_course: true) }

  def self.visible_columns = super - %w[discarded_by_course]
  def self.form_columns    = super - %w[discarded_by_course position]
  def self.index_columns   = %w[title position]
end
