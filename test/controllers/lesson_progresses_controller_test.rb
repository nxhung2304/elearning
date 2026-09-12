require "test_helper"

class My::LessonProgressesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @student    = create(:user, :student)
    @course     = create(:course, :published)
    @section    = create(:section, course: @course)
    @lesson     = create(:lesson, section: @section, is_published: true, is_preview: false)
    @enrollment = create(:enrollment, user: @student, course: @course)
  end

  # ---------------------------------------------------------------------------
  # update — happy path (upsert)
  # ---------------------------------------------------------------------------

  test "enrolled student creates a progress record on first position update" do
    sign_in @student

    assert_difference("LessonProgress.count", 1) do
      patch my_lesson_progress_url(@lesson),
        params: { lesson_progress: { current_position_seconds: 42 } }
    end

    assert_response :success
    progress = @enrollment.lesson_progresses.find_by(lesson: @lesson)
    assert_equal 42, progress.current_position_seconds
  end

  test "subsequent update reuses the same progress record instead of creating a new one" do
    sign_in @student
    create(:lesson_progress,
      enrollment: @enrollment, lesson: @lesson,
      current_position_seconds: 10, completed: false, completed_at: nil)

    assert_no_difference("LessonProgress.count") do
      patch my_lesson_progress_url(@lesson),
        params: { lesson_progress: { current_position_seconds: 55 } }
    end

    assert_response :success
    assert_equal 55, @lesson.lesson_progresses.find_by(enrollment: @enrollment).current_position_seconds
  end

  # ---------------------------------------------------------------------------
  # update — mark completed
  # ---------------------------------------------------------------------------

  test "student marks a lesson completed and completed_at is set" do
    sign_in @student

    patch my_lesson_progress_url(@lesson),
      params: { lesson_progress: { completed: true } }

    assert_response :success
    assert_equal true, JSON.parse(response.body)["completed"]
    progress = @enrollment.lesson_progresses.find_by(lesson: @lesson)
    assert progress.completed?
    assert_not_nil progress.completed_at
  end

  test "student un-marks a completed lesson and completed_at is cleared" do
    sign_in @student
    create(:lesson_progress, enrollment: @enrollment, lesson: @lesson, completed: true)

    patch my_lesson_progress_url(@lesson),
      params: { lesson_progress: { completed: false } }

    assert_response :success
    assert_equal false, JSON.parse(response.body)["completed"]
    progress = @enrollment.lesson_progresses.find_by(lesson: @lesson)
    assert_not progress.completed?
    assert_nil progress.completed_at
  end

  # ---------------------------------------------------------------------------
  # update — validation
  # ---------------------------------------------------------------------------

  test "negative position is rejected with 422 and saves nothing" do
    sign_in @student

    assert_no_difference("LessonProgress.count") do
      patch my_lesson_progress_url(@lesson),
        params: { lesson_progress: { current_position_seconds: -5 } }
    end

    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------------------
  # update — authorization
  # ---------------------------------------------------------------------------

  test "student not enrolled cannot update progress" do
    outsider = create(:user, :student)
    sign_in outsider

    assert_no_difference("LessonProgress.count") do
      patch my_lesson_progress_url(@lesson),
        params: { lesson_progress: { current_position_seconds: 42 } }
    end

    assert_redirected_to root_url
  end

  test "guest is redirected to sign in" do
    patch my_lesson_progress_url(@lesson),
      params: { lesson_progress: { current_position_seconds: 42 } }

    assert_redirected_to new_user_session_url
  end
end
