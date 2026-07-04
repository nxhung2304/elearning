class LessonResourcesController < ApplicationController
  load_and_authorize_resource :course
  load_and_authorize_resource :section, through: :course
  load_and_authorize_resource :lesson, through: :section
  load_and_authorize_resource :lesson_resource, through: :lesson

  def create
    if @lesson_resource.save
      flash[:success] = t("controller.created", text: lesson_resource_message)
      redirect_to course_section_lesson_url(@course, @section, @lesson)
    else
      flash[:error] = t("controller.create_fail", text: lesson_resource_message)
      redirect_to course_section_lesson_url(@course, @section, @lesson), status: :unprocessable_entity
    end
  end

  def destroy
    if @lesson_resource.discard
      flash[:success] = t("controller.destroyed", text: lesson_resource_message)
      redirect_to course_section_lesson_url(@course, @section, @lesson)
    else
      flash[:error] = t("controller.destroy_fail", text: lesson_resource_message)
      redirect_to course_section_lesson_url(@course, @section, @lesson), status: :unprocessable_entity
    end
  end

  private

    def lesson_resource_params
      params.permit(:file_name, :file)
    end

    def lesson_resource_message
      "#{LessonResource.model_name.human} #{@lesson_resource.file_name}"
    end
end
