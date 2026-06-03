require "test_helper"

class CourseCategoriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers if defined?(Devise)

  setup do
    @course_category = create(:course_category)
    admin = create(:user, :admin)
    sign_in admin
  end

  context "happy case" do
    should "get index" do
      get course_categories_url
      assert_response :success
    end

    should "get new" do
      get new_course_category_url
      assert_response :success
    end

    should "create course_category" do
      assert_difference("CourseCategory.count") do
        post course_categories_url, params: { course_category: { name: "New Category" } }
      end

      assert_redirected_to course_categories_url
    end

    should "show course_category" do
      get course_category_url(@course_category)
      assert_response :success
    end

    should "get edit" do
      get edit_course_category_url(@course_category)
      assert_response :success
    end

    should "update course_category" do
      patch course_category_url(@course_category), params: { course_category: { name: "Updated Name" } }
      assert_redirected_to course_categories_url

      @course_category.reload

      assert_equal "Updated Name", @course_category.name
    end

    should "discard a course_category" do
      assert_difference("CourseCategory.kept.count", -1) do
        assert_no_difference("CourseCategory.count") do
          delete course_category_url(@course_category)
        end
      end

      assert_redirected_to course_categories_url
      assert @course_category.reload.discarded?
    end
  end
end
