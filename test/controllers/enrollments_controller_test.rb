require "test_helper"

class EnrollmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @student = create(:user, :student)
    @teacher = create(:user, :teacher)
    @published_course = create(:course, :published, teacher: @teacher)
    @draft_course     = create(:course, teacher: @teacher)
  end

  # ---------------------------------------------------------------------------
  # create
  # ---------------------------------------------------------------------------

  test "student enrolls in a published course" do
    sign_in @student

    assert_difference("Enrollment.count", 1) do
      post course_enrollments_url(@published_course)
    end

    enrollment = @student.enrollments.active.find_by(course: @published_course)
    assert enrollment.present?
    assert enrollment.active?
    assert_redirected_to course_url(@published_course)
  end

  test "re-enrolling while already enrolled does not create a duplicate" do
    sign_in @student
    create(:enrollment, user: @student, course: @published_course)

    assert_no_difference("Enrollment.count") do
      post course_enrollments_url(@published_course)
    end

    assert_redirected_to course_url(@published_course)
  end

  test "student cannot enroll in an unpublished course" do
    sign_in @student

    assert_no_difference("Enrollment.count") do
      post course_enrollments_url(@draft_course)
    end

    assert_redirected_to root_url
  end

  test "teacher cannot enroll" do
    sign_in @teacher

    assert_no_difference("Enrollment.count") do
      post course_enrollments_url(@published_course)
    end

    assert_redirected_to root_url
  end

  test "unauthenticated user is redirected to sign in on create" do
    post course_enrollments_url(@published_course)
    assert_redirected_to new_user_session_url
  end

  # ---------------------------------------------------------------------------
  # destroy
  # ---------------------------------------------------------------------------

  test "student cancels an active enrollment" do
    sign_in @student
    enrollment = create(:enrollment, user: @student, course: @published_course)

    delete course_enrollment_url(@published_course, enrollment)

    assert enrollment.reload.revoked?
    assert_redirected_to course_url(@published_course)
  end

  test "cancelling removes the enrollment from the active scope" do
    sign_in @student
    enrollment = create(:enrollment, user: @student, course: @published_course)

    delete course_enrollment_url(@published_course, enrollment)

    assert_nil @student.enrollments.active.find_by(course: @published_course)
  end

  test "unauthenticated user is redirected to sign in on destroy" do
    enrollment = create(:enrollment, user: @student, course: @published_course)

    delete course_enrollment_url(@published_course, enrollment)
    assert_redirected_to new_user_session_url
  end
end
