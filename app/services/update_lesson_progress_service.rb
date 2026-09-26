class UpdateLessonProgressService
  def initialize(lesson_progress, params)
    @lesson_progress = lesson_progress
    @params = params
  end

  def call
    return false unless @lesson_progress.update(@params)

    UpdateCourseProgressJob.perform_later(@lesson_progress.enrollment) if @lesson_progress.saved_change_to_completed?

    true
  end
end
