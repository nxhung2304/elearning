class CoursesController < ApplicationController
  load_and_authorize_resource

  include IndexableResource

  before_action :set_teacher, only: %i[new create]
  before_action :set_category_collection, only: :index
  before_action :set_teacher_collection, only: :index

  def index; end

  def show; end

  def new; end

  def create
    if @course.save
      flash[:success] = t("controller.created", text: course_title_message)
      redirect_to @course
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @course.update(course_params)
      flash[:success] = t("controller.updated", text: course_title_message)
      redirect_to @course
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @course.discard
      flash[:success] = t("controller.destroyed", text: course_title_message)
      redirect_to courses_url
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def publish
    if @course.publish
      flash[:success] = t("controller.published", text: course_title_message)
      redirect_to @course
    else
      render :show, status: :unprocessable_entity
    end
  end

  def unpublish
    if @course.unpublish
      flash[:success] = t("controller.unpublished", text: course_title_message)
      redirect_to @course
    else
      render :show, status: :unprocessable_entity
    end
  end

  def archive
    if @course.archive
      flash[:success] = t("controller.archived", text: course_title_message)
      redirect_to @course
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

    def course_params
      params.require(:course).permit(:title, :description, :price, :total_lessons, :level, :language, :category_id)
    end

    def course_title_message
      Course.model_name.human + " " + @course.title
    end

    def set_teacher
      return if @course.blank?

      @course.teacher = current_user
    end

    def set_category_collection
      @category_collection = CourseCategory.kept.accessible_by(current_ability).pluck(:name, :id)
    end
    def set_teacher_collection
      @teacher_collection = User.kept.accessible_by(current_ability).teachers.pluck(:name, :id)
    end
end
