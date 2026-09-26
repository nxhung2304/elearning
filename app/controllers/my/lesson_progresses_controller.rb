class My::LessonProgressesController < ApplicationController
  before_action :set_lesson_progress, only: :update

  MAX_UPDATE_ATTEMPTS = 3
  FIRST_ATTEMPT = 1

  def update
    if call_update_service_with_retry
      render json: { completed: @lesson_progress.completed }
    else
      render json: { errors: @lesson_progress.errors.full_messages },
        status: :unprocessable_entity
    end
  end

  private

  def lesson_progress_params
    params.require(:lesson_progress).permit(:current_position_seconds, :completed)
  end

  def set_lesson_progress
    lesson = Lesson.find(params[:lesson_id])
    @enrollment = lesson.section.course.enrollment_for(current_user)
    @lesson_progress = lesson.lesson_progresses.find_or_initialize_by(enrollment: @enrollment)

    authorize! :update, @lesson_progress
  end

  def call_update_service_with_retry(attempt = FIRST_ATTEMPT)
    UpdateLessonProgressService.new(@lesson_progress, lesson_progress_params).call

  rescue ActiveRecord::RecordNotUnique
    raise if attempt >= MAX_UPDATE_ATTEMPTS

    @lesson_progress = @lesson_progress.class.find_by!(enrollment: @enrollment, lesson_id: @lesson_progress.lesson_id)
    call_update_service_with_retry(attempt + 1)
  end
end
