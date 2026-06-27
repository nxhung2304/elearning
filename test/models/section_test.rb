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
require "test_helper"

class SectionTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:section).valid?
  end

  context "validations" do
    should validate_presence_of(:title)
  end

  context "associations" do
    should belong_to(:course)
  end

  context "before_discard" do
    should "discard sections.kept" do
      section = create(:section)
      lesson = create(:lesson, section: section)

      section.discard

      assert section.reload.discarded?
      assert lesson.reload.discarded?
    end
  end
end
