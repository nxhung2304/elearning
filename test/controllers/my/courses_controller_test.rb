require "test_helper"

class My::CoursesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @student = create(:user, :student)
    @teacher = create(:user, :teacher)
    @enrolled_course = create(:course, :published, teacher: @teacher, title: "Enrolled Course")
    @other_course    = create(:course, :published, teacher: @teacher, title: "Other Course")
  end

  test "index renders for a student with no enrollments" do
    sign_in @student
    get my_courses_url
    assert_response :success
    assert_select "tbody tr", count: 0
  end

  test "index lists the student's active enrollments" do
    sign_in @student
    create(:enrollment, user: @student, course: @enrolled_course)

    get my_courses_url

    assert_response :success
    assert_select "tbody td", text: @enrolled_course.title
  end

  test "index excludes courses the student is not enrolled in" do
    sign_in @student
    create(:enrollment, user: @student, course: @enrolled_course)

    get my_courses_url

    assert_select "tbody td", text: @other_course.title, count: 0
  end

  test "index excludes revoked enrollments" do
    sign_in @student
    create(:enrollment, user: @student, course: @enrolled_course, status: :revoked)

    get my_courses_url

    assert_response :success
    assert_select "tbody tr", count: 0
  end

  test "index scopes enrollments to the current user" do
    other_student = create(:user, :student)
    create(:enrollment, user: other_student, course: @enrolled_course)

    sign_in @student
    get my_courses_url

    assert_response :success
    assert_select "tbody tr", count: 0
  end

  test "index filters by course_id" do
    sign_in @student
    create(:enrollment, user: @student, course: @enrolled_course)
    create(:enrollment, user: @student, course: @other_course)

    get my_courses_url, params: { q: { course_id_eq: @enrolled_course.id } }

    assert_response :success
    assert_select "tbody td", text: @enrolled_course.title
    assert_select "tbody td", text: @other_course.title, count: 0
  end

  test "unauthenticated user is redirected to sign in" do
    get my_courses_url
    assert_redirected_to new_user_session_url
  end
end
