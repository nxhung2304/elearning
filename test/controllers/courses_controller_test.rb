require "test_helper"

class CoursesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin         = create(:user, :admin)
    @teacher       = create(:user, :teacher)
    @other_teacher = create(:user, :teacher)
    @student       = create(:user, :student)

    @course           = create(:course, teacher: @teacher, discarded_at: nil)
    @published_course = create(:course, :published, teacher: @teacher, discarded_at: nil)
    @other_course     = create(:course, teacher: @other_teacher, discarded_at: nil)
  end

  # ---------------------------------------------------------------------------
  # Admin
  # ---------------------------------------------------------------------------

  test "admin: index returns 200" do
    sign_in @admin
    get courses_path
    assert_response :success
  end

  test "admin: show returns 200" do
    sign_in @admin
    get course_path(@course)
    assert_response :success
  end

  test "admin: new returns 200" do
    sign_in @admin
    get new_course_path
    assert_response :success
  end

  test "admin: create persists course and redirects to show" do
    sign_in @admin
    assert_difference "Course.count", 1 do
      post courses_path, params: { course: valid_course_params }
    end
    assert_redirected_to course_path(Course.last)
  end

  test "admin: create with invalid params renders new" do
    sign_in @admin
    assert_no_difference "Course.count" do
      post courses_path, params: { course: { title: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "admin: edit returns 200" do
    sign_in @admin
    get edit_course_path(@course)
    assert_response :success
  end

  test "admin: update persists change and redirects" do
    sign_in @admin
    patch course_path(@course), params: { course: { title: "Admin Updated Title" } }
    assert_redirected_to course_path(@course)
    assert_equal "Admin Updated Title", @course.reload.title
  end

  test "admin: destroy soft-deletes and redirects to index" do
    sign_in @admin
    assert_difference "Course.kept.count", -1 do
      delete course_path(@course)
    end
    assert_redirected_to courses_path
    assert_not_nil @course.reload.discarded_at
  end

  test "admin: publish changes status to published" do
    sign_in @admin
    patch publish_course_path(@course)
    assert_redirected_to course_path(@course)
    assert_predicate @course.reload, :published?
  end

  test "admin: unpublish changes status to draft" do
    sign_in @admin
    patch unpublish_course_path(@published_course)
    assert_redirected_to course_path(@published_course)
    assert_predicate @published_course.reload, :draft?
  end

  test "admin: archive changes status to archived" do
    sign_in @admin
    patch archive_course_path(@published_course)
    assert_redirected_to course_path(@published_course)
    assert_predicate @published_course.reload, :archived?
  end

  # ---------------------------------------------------------------------------
  # Teacher — own courses
  # ---------------------------------------------------------------------------

  test "teacher: index returns 200" do
    sign_in @teacher
    get courses_path
    assert_response :success
  end

  test "teacher: show own course returns 200" do
    sign_in @teacher
    get course_path(@course)
    assert_response :success
  end

  test "teacher: new returns 200" do
    sign_in @teacher
    get new_course_path
    assert_response :success
  end

  test "teacher: create sets teacher_id to current user" do
    sign_in @teacher
    post courses_path, params: { course: valid_course_params }
    assert_equal @teacher, Course.last.teacher
  end

  test "teacher: create redirects to created course" do
    sign_in @teacher
    assert_difference "Course.count", 1 do
      post courses_path, params: { course: valid_course_params }
    end
    assert_redirected_to course_path(Course.last)
  end

  test "teacher: create with invalid params renders new" do
    sign_in @teacher
    assert_no_difference "Course.count" do
      post courses_path, params: { course: { title: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "teacher: edit own course returns 200" do
    sign_in @teacher
    get edit_course_path(@course)
    assert_response :success
  end

  test "teacher: update own course redirects to show" do
    sign_in @teacher
    patch course_path(@course), params: { course: { title: "Teacher Updated" } }
    assert_redirected_to course_path(@course)
    assert_equal "Teacher Updated", @course.reload.title
  end

  test "teacher: destroy own course soft-deletes it" do
    sign_in @teacher
    delete course_path(@course)
    assert_redirected_to courses_path
    assert_not_nil @course.reload.discarded_at
  end

  test "teacher: publish own course" do
    sign_in @teacher
    patch publish_course_path(@course)
    assert_redirected_to course_path(@course)
    assert_predicate @course.reload, :published?
  end

  test "teacher: archive own course" do
    sign_in @teacher
    patch archive_course_path(@published_course)
    assert_redirected_to course_path(@published_course)
    assert_predicate @published_course.reload, :archived?
  end

  # ---------------------------------------------------------------------------
  # Teacher — another teacher's courses (all should be 403)
  # ---------------------------------------------------------------------------

  test "teacher: show other teacher's course is forbidden" do
    sign_in @teacher
    get course_path(@other_course)
    assert_redirected_to root_path
  end

  test "teacher: edit other teacher's course is forbidden" do
    sign_in @teacher
    get edit_course_path(@other_course)
    assert_redirected_to root_path
  end

  test "teacher: update other teacher's course is forbidden" do
    sign_in @teacher
    patch course_path(@other_course), params: { course: { title: "Hacked" } }
    assert_redirected_to root_path
    assert_not_equal "Hacked", @other_course.reload.title
  end

  test "teacher: destroy other teacher's course is forbidden" do
    sign_in @teacher
    delete course_path(@other_course)
    assert_redirected_to root_path
    assert_nil @other_course.reload.discarded_at
  end

  # ---------------------------------------------------------------------------
  # Student
  # ---------------------------------------------------------------------------

  test "student: index returns 200" do
    sign_in @student
    get courses_path
    assert_response :success
  end

  test "student: show published course returns 200" do
    sign_in @student
    get course_path(@published_course)
    assert_response :success
  end

  test "student: show draft course is forbidden" do
    sign_in @student
    get course_path(@course)
    assert_redirected_to root_path
  end

  test "student: new is forbidden" do
    sign_in @student
    get new_course_path
    assert_redirected_to root_path
  end

  test "student: create is forbidden" do
    sign_in @student
    assert_no_difference "Course.count" do
      post courses_path, params: { course: valid_course_params }
    end
    assert_redirected_to root_path
  end

  test "student: cannot unpublish a published course" do
    sign_in @student
    patch unpublish_course_path(@published_course)
    assert_redirected_to root_path
    assert_predicate @published_course.reload, :published?
  end

  # ---------------------------------------------------------------------------
  # Unauthenticated
  # ---------------------------------------------------------------------------

  test "unauthenticated: index redirects to login" do
    get courses_path
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated: show redirects to login" do
    get course_path(@course)
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated: create redirects to login" do
    assert_no_difference "Course.count" do
      post courses_path, params: { course: valid_course_params }
    end
    assert_redirected_to new_user_session_path
  end

  private

    def valid_course_params
      {
        title: Faker::Lorem.unique.sentence(word_count: 3),
        description: Faker::Lorem.paragraph,
        level: :beginner,
        language: :english,
        price: 29.99,
        total_lessons: 10,
        category_id: create(:course_category).id
      }
    end
end
