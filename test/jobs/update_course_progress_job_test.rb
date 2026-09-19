require "test_helper"

class UpdateCourseProgressJobTest < ActiveJob::TestCase
  setup do
    @course  = create(:course)
    @section = create(:section, course: @course)
  end

  def queue_adapter_for_test
    ActiveJob::QueueAdapters::TestAdapter.new
  end

  # ---------------------------------------------------------------------------
  # calculation
  # ---------------------------------------------------------------------------

  test "computes percentage and count from completed lesson progresses" do
    lessons = create_list(:lesson, 5, section: @section)
    enrollment = create(:enrollment, course: @course)
    lessons.first(2).each { |lesson| create(:lesson_progress, enrollment: enrollment, lesson: lesson, completed: true) }
    lessons.last(3).each { |lesson| create(:lesson_progress, enrollment: enrollment, lesson: lesson, completed: false) }

    UpdateCourseProgressJob.perform_now(enrollment)

    course_progress = enrollment.course_progress.reload
    assert_equal 2, course_progress.completed_lessons_count
    assert_equal 40.0, course_progress.progress_percentage.to_f
  end

  test "reaching 100% sets completed_at on course_progress" do
    lessons = create_list(:lesson, 2, section: @section)
    enrollment = create(:enrollment, course: @course)
    lessons.each { |lesson| create(:lesson_progress, enrollment: enrollment, lesson: lesson, completed: true) }

    UpdateCourseProgressJob.perform_now(enrollment)

    course_progress = enrollment.course_progress.reload
    assert_equal 100.0, course_progress.progress_percentage.to_f
    assert_not_nil course_progress.completed_at
  end

  test "un-completing a lesson after reaching 100% clears completed_at" do
    lessons = create_list(:lesson, 2, section: @section)
    enrollment = create(:enrollment, course: @course)
    progresses = lessons.map { |lesson| create(:lesson_progress, enrollment: enrollment, lesson: lesson, completed: true) }
    UpdateCourseProgressJob.perform_now(enrollment)

    progresses.first.update!(completed: false)
    UpdateCourseProgressJob.perform_now(enrollment)

    course_progress = enrollment.course_progress.reload
    assert_equal 50.0, course_progress.progress_percentage.to_f
    assert_nil course_progress.completed_at
  end

  # ---------------------------------------------------------------------------
  # edge cases
  # ---------------------------------------------------------------------------

  test "course with no lessons results in zero percentage without raising" do
    enrollment = create(:enrollment, course: @course)

    UpdateCourseProgressJob.perform_now(enrollment)

    course_progress = enrollment.course_progress.reload
    assert_equal 0, course_progress.completed_lessons_count
    assert_equal 0.0, course_progress.progress_percentage.to_f
  end

  test "no lesson progress recorded yet results in zero percentage" do
    create_list(:lesson, 3, section: @section)
    enrollment = create(:enrollment, course: @course)

    UpdateCourseProgressJob.perform_now(enrollment)

    course_progress = enrollment.course_progress.reload
    assert_equal 0, course_progress.completed_lessons_count
    assert_equal 0.0, course_progress.progress_percentage.to_f
  end

  test "denominator is lesson progresses recorded, not total lessons of the course" do
    lessons = create_list(:lesson, 5, section: @section)
    enrollment = create(:enrollment, course: @course)
    lessons.first(2).each { |lesson| create(:lesson_progress, enrollment: enrollment, lesson: lesson, completed: true) }

    UpdateCourseProgressJob.perform_now(enrollment)

    course_progress = enrollment.course_progress.reload
    assert_equal 100.0, course_progress.progress_percentage.to_f
  end

  test "recalculates from scratch instead of accumulating on top of stale values" do
    lesson = create(:lesson, section: @section)
    enrollment = create(:enrollment, course: @course)
    enrollment.course_progress.update!(progress_percentage: 90, completed_lessons_count: 9)
    create(:lesson_progress, enrollment: enrollment, lesson: lesson, completed: true)

    UpdateCourseProgressJob.perform_now(enrollment)

    course_progress = enrollment.course_progress.reload
    assert_equal 1, course_progress.completed_lessons_count
    assert_equal 100.0, course_progress.progress_percentage.to_f
  end

  # ---------------------------------------------------------------------------
  # isolation
  # ---------------------------------------------------------------------------

  test "updating one enrollment's progress does not affect another enrollment on the same course" do
    lessons = create_list(:lesson, 2, section: @section)
    enrollment_a = create(:enrollment, course: @course)
    enrollment_b = create(:enrollment, course: @course)
    lessons.each { |lesson| create(:lesson_progress, enrollment: enrollment_a, lesson: lesson, completed: true) }

    UpdateCourseProgressJob.perform_now(enrollment_a)

    assert_equal 100.0, enrollment_a.course_progress.reload.progress_percentage.to_f
    assert_equal 0.0, enrollment_b.course_progress.reload.progress_percentage.to_f
  end

  # ---------------------------------------------------------------------------
  # resilience
  # ---------------------------------------------------------------------------

  test "reschedules instead of raising when a deadlock occurs while updating course_progress" do
    lesson = create(:lesson, section: @section)
    enrollment = create(:enrollment, course: @course)
    create(:lesson_progress, enrollment: enrollment, lesson: lesson, completed: true)

    course_progress = enrollment.course_progress
    def course_progress.update!(*)
      raise ActiveRecord::Deadlocked
    end

    assert_enqueued_with(job: UpdateCourseProgressJob, args: [ enrollment ]) do
      assert_nothing_raised { UpdateCourseProgressJob.perform_now(enrollment) }
    end
  end
end
