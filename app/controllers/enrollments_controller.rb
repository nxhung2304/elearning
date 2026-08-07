class EnrollmentsController < ApplicationController
  load_and_authorize_resource :course

  def index
    @enrollments = @course.enrollments.active
  end

  def create
    @enrollment = @course.enrollments.find_or_initialize_by(user: current_user)
    @enrollment.activate

    authorize! :create, @enrollment

    if @enrollment.save
      redirect_to @course, notice: t("controller.created", text: Enrollment.model_name.human)
    else
      redirect_to @course, alert: t("controller.create_fail", text: Enrollment.model_name.human)
    end
  end

  def destroy
    @enrollment = @course.active_enrollment_for(current_user)
    if @enrollment.blank?
      redirect_to @course, alert: t("enrollments.flash.not_enrolled") and return
    end

    authorize! :destroy, @enrollment

    @enrollment.revoked!
    redirect_to @course, notice: t("controller.revoked", text: Enrollment.model_name.human)
  end
end
