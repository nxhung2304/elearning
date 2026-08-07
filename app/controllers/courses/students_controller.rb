class Courses::StudentsController < ApplicationController
  load_resource :course

  def index
    authorize! :manage, @course
    @pagy, @enrollments = pagy(@course.enrollments.active.includes(:user))
  end
end
