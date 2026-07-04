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
require "test_helper"

class LessonTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:section)
  end

  test "valid factory" do
    assert build(:lesson).valid?
  end

  context "validations" do
    should validate_presence_of(:title)
    should validate_inclusion_of(:is_preview).in_array([ true, false ])
    should validate_inclusion_of(:is_published).in_array([ true, false ])
  end

  context "duration_seconds" do
    should "can be nil when lesson_type is text" do
      lesson_text = create(:lesson, :text)
      lesson_text.duration_seconds = nil

      assert lesson_text.save
      assert lesson_text.valid?
      assert_nil lesson_text.duration_seconds
    end

    should "cannot nil when lesson_type is video" do
      lesson_video = create(:lesson, :video)

      assert lesson_video.duration_seconds
    end

    should "cannot nil when lesson_type is mixed" do
      lesson_mixed = create(:lesson, :mixed)

      assert lesson_mixed.duration_seconds
    end
  end

  context "content" do
    should "cannot nil when lesson_type is text" do
      lesson_text = create(:lesson, :text)

      assert_not_empty lesson_text.content
    end

    should "can be nil when lesson_type is video" do
      lesson_video = create(:lesson, :video)
      lesson_video.content = nil

      assert lesson_video.save
      assert_nil lesson_video.content
      assert lesson_video
    end

    should "cannot nil when lesson_type is mixed" do
      lesson_mixed = create(:lesson, :mixed)

      assert_not_empty lesson_mixed.content
    end
  end
end
