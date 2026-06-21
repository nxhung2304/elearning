require "test_helper"

class SectionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user, :admin)
    @course = create(:course)
    @section = create(:section, course: @course)
    sign_in @user
  end

  test "should get index" do
    get course_sections_url(@course)
    assert_response :success
  end

  test "should get new" do
    get new_course_section_url(@course)
    assert_response :success
  end

  test "should create section" do
    assert_difference("Section.count", 1) do
      post course_sections_url(@course), params: { section: { title: "New Section" } }
    end

    assert_redirected_to course_section_url(@course, Section.last)
  end

  test "should not create section with blank title" do
    assert_no_difference("Section.count") do
      post course_sections_url(@course), params: { section: { title: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "should show section" do
    get course_section_url(@course, @section)
    assert_response :success
  end

  test "should get edit" do
    get edit_course_section_url(@course, @section)
    assert_response :success
  end

  test "should update section" do
    patch course_section_url(@course, @section), params: { section: { title: "Updated Title" } }
    assert_redirected_to course_section_url(@course, @section)
  end

  test "should not update section with blank title" do
    patch course_section_url(@course, @section), params: { section: { title: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy section" do
    delete course_section_url(@course, @section)
    assert @section.reload.discarded?
    assert_redirected_to course_sections_url(@course)
  end
end
