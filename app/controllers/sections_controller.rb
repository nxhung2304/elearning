class SectionsController < ApplicationController
  load_and_authorize_resource :course
  load_and_authorize_resource :section, through: :course

  include IndexableResource
  include DiscardableResource

  def index; end

  def show; end

  def new; end

  def edit; end

  def create
    if @section.save
      flash[:success] = t("controller.created", text: Section.model_name.human)
      redirect_to course_section_url(@course, @section)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @section.update(section_params)
      flash[:success] = t("controller.updated", text: Section.model_name.human)
      redirect_to course_section_url(@course, @section)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @section.discard
      flash[:success] = t("controller.destroyed", text: Section.model_name.human)
      redirect_to course_sections_url(@course)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def section_params
      params.require(:section).permit(:title)
    end
end
