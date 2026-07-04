class LessonsController < ApplicationController
  load_and_authorize_resource :course
  load_and_authorize_resource :section, through: :course
  load_and_authorize_resource :lesson, through: :section

  include IndexableResource
  include DiscardableResource

  def index; end

  def show; end

  def new; end

  def create
    if @lesson.save
      flash[:success] = t("controller.created", text: lesson_message)
      redirect_to course_section_lessons_url(@course, @section)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @lesson.update(lesson_params)
      flash[:success] = t("controller.updated", text: lesson_message)
      redirect_to course_section_lessons_url
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @lesson.destroy
      flash[:success] = t("controller.destroyed", text: lesson_message)
      redirect_to course_section_lessons_url
    else
      flash[:error] = t("controller.destroy_fail", text: lesson_message)
      render :edit, status: :unprocessable_entity
    end
  end

  def includes_associations
    [ { course: :section} ]
  end

  private

    def lesson_params
      params.require(:lesson).permit(
        :title, :lesson_type, :position, :content,
        :duration_seconds, :video, :is_preview, :is_published
      )
    end

    def lesson_message
      "#{Lesson.model_name.human} #{@lesson.title}"
    end
end
