require "test_helper"

class LessonsControllerTest < ActionDispatch::IntegrationTest
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
  end

  # ---------------------------------------------------------------------------
  # Admin
  # ---------------------------------------------------------------------------

  test "admin: index returns 200" do
    sign_in @admin
    get course_section_lessons_path(@course, @section)
    assert_response :success
  end

  test "admin: show returns 200" do
    sign_in @admin
    get course_section_lesson_path(@course, @section, @lesson)
    assert_response :success
  end

  test "admin: new returns 200" do
    sign_in @admin
    get new_course_section_lesson_path(@course, @section)
    assert_response :success
  end

  test "admin: create persists lesson and redirects to index" do
    sign_in @admin
    assert_difference "Lesson.count", 1 do
      post course_section_lessons_path(@course, @section), params: { lesson: valid_lesson_params }
    end
    assert_redirected_to course_section_lessons_path(@course, @section)
  end

  test "admin: create with invalid params renders new" do
    sign_in @admin
    assert_no_difference "Lesson.count" do
      post course_section_lessons_path(@course, @section), params: { lesson: { title: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "admin: edit returns 200" do
    sign_in @admin
    get edit_course_section_lesson_path(@course, @section, @lesson)
    assert_response :success
  end

  test "admin: update persists change and redirects to index" do
    sign_in @admin
    patch course_section_lesson_path(@course, @section, @lesson), params: { lesson: { title: "Admin Updated Title" } }
    assert_redirected_to course_section_lessons_path(@course, @section)
    assert_equal "Admin Updated Title", @lesson.reload.title
  end

  test "admin: update with invalid params renders edit" do
    sign_in @admin
    patch course_section_lesson_path(@course, @section, @lesson), params: { lesson: { title: "" } }
    assert_response :unprocessable_entity
  end

  test "admin: destroy deletes lesson and redirects to index" do
    sign_in @admin
    assert_difference "Lesson.kept.count", -1 do
      delete course_section_lesson_path(@course, @section, @lesson)
    end
    assert_redirected_to course_section_lessons_path(@course, @section)
  end

  # ---------------------------------------------------------------------------
  # Teacher — own course's lessons
  # ---------------------------------------------------------------------------

  test "teacher: index returns 200 for own course" do
    sign_in @teacher
    get course_section_lessons_path(@course, @section)
    assert_response :success
  end

  test "teacher: show returns 200 for own lesson" do
    sign_in @teacher
    get course_section_lesson_path(@course, @section, @lesson)
    assert_response :success
  end

  test "teacher: new returns 200 for own course" do
    sign_in @teacher
    get new_course_section_lesson_path(@course, @section)
    assert_response :success
  end

  test "teacher: create persists lesson under own course" do
    sign_in @teacher
    assert_difference "Lesson.count", 1 do
      post course_section_lessons_path(@course, @section), params: { lesson: valid_lesson_params }
    end
    assert_redirected_to course_section_lessons_path(@course, @section)
  end

  test "teacher: create with invalid params renders new" do
    sign_in @teacher
    assert_no_difference "Lesson.count" do
      post course_section_lessons_path(@course, @section), params: { lesson: { title: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "teacher: edit returns 200 for own lesson" do
    sign_in @teacher
    get edit_course_section_lesson_path(@course, @section, @lesson)
    assert_response :success
  end

  test "teacher: update own lesson redirects to index" do
    sign_in @teacher
    patch course_section_lesson_path(@course, @section, @lesson), params: { lesson: { title: "Teacher Updated" } }
    assert_redirected_to course_section_lessons_path(@course, @section)
    assert_equal "Teacher Updated", @lesson.reload.title
  end

  test "teacher: destroy own lesson redirects to index" do
    sign_in @teacher
    assert_difference "Lesson.kept.count", -1 do
      delete course_section_lesson_path(@course, @section, @lesson)
    end
    assert_redirected_to course_section_lessons_path(@course, @section)
  end

  # ---------------------------------------------------------------------------
  # Teacher — another teacher's lessons (all should be forbidden)
  # ---------------------------------------------------------------------------

  test "teacher: show other teacher's lesson is forbidden" do
    sign_in @teacher
    get course_section_lesson_path(@other_course, @other_section, @other_lesson)
    assert_redirected_to root_path
  end

  test "teacher: new lesson under other teacher's course is forbidden" do
    sign_in @teacher
    get new_course_section_lesson_path(@other_course, @other_section)
    assert_redirected_to root_path
  end

  test "teacher: create lesson under other teacher's course is forbidden" do
    sign_in @teacher
    assert_no_difference "Lesson.count" do
      post course_section_lessons_path(@other_course, @other_section), params: { lesson: valid_lesson_params }
    end
    assert_redirected_to root_path
  end

  test "teacher: update other teacher's lesson is forbidden" do
    sign_in @teacher
    patch course_section_lesson_path(@other_course, @other_section, @other_lesson), params: { lesson: { title: "Hacked" } }
    assert_redirected_to root_path
    assert_not_equal "Hacked", @other_lesson.reload.title
  end

  test "teacher: destroy other teacher's lesson is forbidden" do
    sign_in @teacher
    assert_no_difference "Lesson.count" do
      delete course_section_lesson_path(@other_course, @other_section, @other_lesson)
    end
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Student
  # ---------------------------------------------------------------------------

  test "student: new is forbidden" do
    sign_in @student
    get new_course_section_lesson_path(@course, @section)
    assert_redirected_to root_path
  end

  test "student: create is forbidden" do
    sign_in @student
    assert_no_difference "Lesson.count" do
      post course_section_lessons_path(@course, @section), params: { lesson: valid_lesson_params }
    end
    assert_redirected_to root_path
  end

  test "student: edit is forbidden" do
    sign_in @student
    get edit_course_section_lesson_path(@course, @section, @lesson)
    assert_redirected_to root_path
  end

  test "student: update is forbidden" do
    sign_in @student
    patch course_section_lesson_path(@course, @section, @lesson), params: { lesson: { title: "Student Hacked" } }
    assert_redirected_to root_path
    assert_not_equal "Student Hacked", @lesson.reload.title
  end

  test "student: destroy is forbidden" do
    sign_in @student
    assert_no_difference "Lesson.count" do
      delete course_section_lesson_path(@course, @section, @lesson)
    end
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Unauthenticated
  # ---------------------------------------------------------------------------

  test "unauthenticated: index redirects to login" do
    get course_section_lessons_path(@course, @section)
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated: new redirects to login" do
    get new_course_section_lesson_path(@course, @section)
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated: create redirects to login" do
    assert_no_difference "Lesson.count" do
      post course_section_lessons_path(@course, @section), params: { lesson: valid_lesson_params }
    end
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated: show redirects to login" do
    get course_section_lesson_path(@course, @section, @lesson)
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated: update redirects to login" do
    patch course_section_lesson_path(@course, @section, @lesson), params: { lesson: { title: "Changed" } }
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated: destroy redirects to login" do
    assert_no_difference "Lesson.count" do
      delete course_section_lesson_path(@course, @section, @lesson)
    end
    assert_redirected_to new_user_session_path
  end

  private

    def valid_lesson_params
      {
        title: Faker::Lorem.unique.sentence(word_count: 3),
        lesson_type: :text,
        content: Faker::Lorem.paragraph,
        is_preview: false,
        is_published: false
      }
    end
end
