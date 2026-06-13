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
require "test_helper"

class CourseCategoryTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:course_category).valid?
  end

  context :associations do
    should have_many(:courses).dependent(:restrict_with_error)
  end

  context "validations" do
    subject { build(:course_category) }

    should validate_presence_of(:name)
  end

  context "slug" do
    should "be generated from name" do
      category = create(:course_category, name: "Programming")
      assert_equal "programming", category.slug
    end

    should "append unique suffix when name is taken" do
      first = create(:course_category, name: "Programming")
      second = create(:course_category, name: "Programming")
      assert_match(/\Aprogramming-/, second.slug)
      assert_not_equal first.slug, second.slug
    end
  end

  context "discard" do
    should "discard children: after discard parent" do
      child = create(:course_category, :with_parent)
      parent = child.parent
      parent.discard

      assert parent.discarded?
      assert child.reload.discarded?
    end
  end
end
