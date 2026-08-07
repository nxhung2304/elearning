class My::CoursesController < ApplicationController
  load_and_authorize_resource

  def index
    @q = current_user.enrollments.active.includes(:course).ransack(params[:q])
    @pagy, @my_courses = pagy(@q.result(distinct: true))
    @courses_for_select = Course.enrolled_by(current_user).pluck(:title, :id)
  end
end
