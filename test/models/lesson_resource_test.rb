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
require "test_helper"

class LessonResourceTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:lesson_resource).valid?
  end

  context "validations" do
    should validate_presence_of(:file_name)
    should validate_inclusion_of(:discarded_by_lesson).in_array([ true, false ])
  end

  context "associations" do
    should belong_to(:lesson)
  end
end
