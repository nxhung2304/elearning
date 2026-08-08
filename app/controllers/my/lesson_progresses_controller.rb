class My::LessonProgressesController < ApplicationController
  before_action :set_lesson_progress, only: :update

  MAX_UPDATE_ATTEMPTS = 3

  def update
    @update_attempts ||= 0

    if @lesson_progress.update(lesson_progress_params)
      render json: { completed: @lesson_progress.completed }
    else
      render json: { errors: @lesson_progress.errors.full_messages },
        status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    raise if (@update_attempts += 1) >= MAX_UPDATE_ATTEMPTS

    @lesson_progress = @lesson_progress.class.find_by!(enrollment: @enrollment, lesson_id: @lesson_progress.lesson_id)
    retry
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
end
