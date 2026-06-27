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
      flash[:success] = t("controller.created", text: "#{Lesson.model_name.human} #{@lesson.try(:email) || @lesson.try(:name) || @lesson.id}")
      redirect_to course_section_lessons_url(@course, @section)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @lesson.update(lesson_params)
      flash[:success] = t("controller.updated", text: "#{Lesson.model_name.human} #{@lesson.try(:email) || @lesson.try(:name) || @lesson.id}")
      redirect_to lessons_url
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @lesson.destroy
      flash[:success] = t("controller.destroyed", text: "#{Lesson.model_name.human} #{@lesson.try(:email) || @lesson.try(:name) || @lesson.id}")
      redirect_to lessons_url
    else
      flash[:error] = t("controller.destroy_fail", text: "#{Lesson.model_name.human} #{@lesson.try(:email) || @lesson.try(:name) || @lesson.id}")
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def lesson_params
      params.require(:lesson).permit(
        :title, :lesson_type, :position, :content,
        :duration_seconds, :video, :is_preview, :is_published
      )
    end
end
