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
require "test_helper"

class CourseTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:course).valid?
  end

  context :associations do
    should belong_to(:category).class_name("CourseCategory").with_foreign_key("category_id")
    should belong_to(:teacher).class_name("User").with_foreign_key("teacher_id")
  end

  context "validations" do
    subject { build(:course) }

    should validate_presence_of(:title)
    should validate_presence_of(:description)
    should validate_presence_of(:level)
    should validate_presence_of(:language)
    should validate_presence_of(:price)
    should validate_numericality_of(:price).is_greater_than_or_equal_to(0)
    should validate_presence_of(:total_lessons)
    should validate_numericality_of(:total_lessons).only_integer.is_greater_than_or_equal_to(0)
    should validate_presence_of(:status)
  end

  test "published_at is set when status transitions to published" do
    course = create(:course)
    course.update! status: :published
    course.reload

    assert course.published_at
  end

  test "published_at is cleared when status transitions away from published" do
    course = create(:course, :published)
    course.update! status: :draft
    course.reload

    assert_not course.published_at
  end
end
