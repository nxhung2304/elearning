class UpdateCourseProgressJob < ApplicationJob
  def perform(enrollment)
    completed_count = enrollment.lesson_progresses.completed_count
    percentage = calculate_percentage(enrollment, completed_count)

    enrollment.course_progress.update!(progress_percentage: percentage, completed_lessons_count: completed_count)
  end

  private

  def calculate_percentage(enrollment, completed_count)
    total_lessons_count = enrollment.lesson_progresses.count

    return 0 if total_lessons_count.zero?

    completed_count.to_f / total_lessons_count * 100
  end
end
