require "test_helper"

class LessonResourcesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin         = create(:user, :admin)
    @teacher       = create(:user, :teacher)
    @other_teacher = create(:user, :teacher)
    @student       = create(:user, :student)

    @course        = create(:course, teacher: @teacher)
    @other_course  = create(:course, teacher: @other_teacher)

    @section       = create(:section, course: @course)
    @other_section = create(:section, course: @other_course)

    @lesson        = create(:lesson, :text, section: @section)
    @other_lesson  = create(:lesson, :text, section: @other_section)

    @resource      = create(:lesson_resource, lesson: @lesson)
    @other_resource = create(:lesson_resource, lesson: @other_lesson)
  end

  # ---------------------------------------------------------------------------
  # Admin
  # ---------------------------------------------------------------------------

  test "admin: create persists resource and redirects to lesson" do
    sign_in @admin
    assert_difference "LessonResource.count", 1 do
      post course_section_lesson_lesson_resources_path(@course, @section, @lesson),
           params: valid_upload_params
    end
    assert_redirected_to course_section_lesson_path(@course, @section, @lesson)
  end

  test "admin: destroy soft-deletes resource and redirects to lesson" do
    sign_in @admin
    assert_difference "LessonResource.kept.count", -1 do
      delete course_section_lesson_lesson_resource_path(@course, @section, @lesson, @resource)
    end
    assert_redirected_to course_section_lesson_path(@course, @section, @lesson)
    assert_not_nil @resource.reload.discarded_at
  end

  # ---------------------------------------------------------------------------
  # Teacher — own course
  # ---------------------------------------------------------------------------

  test "teacher: create persists resource under own lesson" do
    sign_in @teacher
    assert_difference "LessonResource.count", 1 do
      post course_section_lesson_lesson_resources_path(@course, @section, @lesson),
           params: valid_upload_params
    end
    assert_redirected_to course_section_lesson_path(@course, @section, @lesson)
  end

  test "teacher: destroy soft-deletes own resource and redirects to lesson" do
    sign_in @teacher
    assert_difference "LessonResource.kept.count", -1 do
      delete course_section_lesson_lesson_resource_path(@course, @section, @lesson, @resource)
    end
    assert_redirected_to course_section_lesson_path(@course, @section, @lesson)
    assert_not_nil @resource.reload.discarded_at
  end

  # ---------------------------------------------------------------------------
  # Teacher — another teacher's lesson (forbidden)
  # ---------------------------------------------------------------------------

  test "teacher: create under another teacher's lesson is forbidden" do
    sign_in @teacher
    assert_no_difference "LessonResource.count" do
      post course_section_lesson_lesson_resources_path(@other_course, @other_section, @other_lesson),
           params: valid_upload_params
    end
    assert_redirected_to root_path
  end

  test "teacher: destroy another teacher's resource is forbidden" do
    sign_in @teacher
    assert_no_difference "LessonResource.kept.count" do
      delete course_section_lesson_lesson_resource_path(@other_course, @other_section, @other_lesson, @other_resource)
    end
    assert_redirected_to root_path
    assert_nil @other_resource.reload.discarded_at
  end

  # ---------------------------------------------------------------------------
  # Student
  # ---------------------------------------------------------------------------

  test "student: create is forbidden" do
    sign_in @student
    assert_no_difference "LessonResource.count" do
      post course_section_lesson_lesson_resources_path(@course, @section, @lesson),
           params: valid_upload_params
    end
    assert_redirected_to root_path
  end

  test "student: destroy is forbidden" do
    sign_in @student
    assert_no_difference "LessonResource.kept.count" do
      delete course_section_lesson_lesson_resource_path(@course, @section, @lesson, @resource)
    end
    assert_redirected_to root_path
    assert_nil @resource.reload.discarded_at
  end

  # ---------------------------------------------------------------------------
  # Unauthenticated
  # ---------------------------------------------------------------------------

  test "unauthenticated: create redirects to login" do
    assert_no_difference "LessonResource.count" do
      post course_section_lesson_lesson_resources_path(@course, @section, @lesson),
           params: valid_upload_params
    end
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated: destroy redirects to login" do
    assert_no_difference "LessonResource.kept.count" do
      delete course_section_lesson_lesson_resource_path(@course, @section, @lesson, @resource)
    end
    assert_redirected_to new_user_session_path
    assert_nil @resource.reload.discarded_at
  end

  private

    def valid_upload_params
      {
        file_name: "Lecture slides",
        file: fixture_file_upload(
          Rails.root.join("test/fixtures/files/sample.pdf"),
          "application/pdf"
        )
      }
    end
end
