# == Schema Information
#
# Table name: lesson_resources
#
#  id                  :bigint           not null, primary key
#  discarded_at        :datetime
#  discarded_by_lesson :boolean          default(FALSE), not null
#  file_name           :string
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
    should validate_inclusion_of(:discarded_by_lesson).in_array([ true, false ])
  end

  context "associations" do
    should belong_to(:lesson)
  end

  context "set file_name" do
    should "set file_name base on file blob when file_name is blank" do
      lesson_resource = create(:lesson_resource, file_name: nil)
      expected_filename = lesson_resource.file.blob.filename
      actual_filename = lesson_resource.file_name

      assert actual_filename
      assert_equal expected_filename, actual_filename
    end

    should "not set file_name base on file blob when file_name is present" do
      lesson_resource = create(:lesson_resource, file_name: "foo.pdf")
      actual_filename = lesson_resource.file_name

      assert_equal actual_filename, "foo.pdf"
      assert_not_equal lesson_resource.file.blob.filename, actual_filename
    end
  end
end
