class CourseCategoriesController < ApplicationController
  load_and_authorize_resource
  before_action :set_parent_categories, only: %i[new edit]

  def index
    @q = CourseCategory.kept.ransack(params[:q])
    @pagy, @course_categories = pagy(@q.result(distinct: true))
  end

  def show; end

  def new; end

  def create
    if @course_category.save
      flash[:success] = t("controller.created", text: course_category_name_message)
      redirect_to course_categories_url
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @course_category.update(course_category_params)
      flash[:success] = t("controller.updated", text: course_category_name_message)
      redirect_to course_categories_url
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @course_category.discard
      flash[:success] = t("controller.destroyed", text: course_category_name_message)
      redirect_to course_categories_url
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def course_category_params
      params.require(:course_category).permit(:name, :parent_id)
    end

    def course_category_name_message
      CourseCategory.model_name.human + " " + @course_category.name
    end

    def set_parent_categories
      if @course_category.new_record?
        @parent_categories = CourseCategory.kept.all
      else
        @parent_categories = CourseCategory.kept.where.not(id: @course_category.subtree_ids)
      end
    end
end
