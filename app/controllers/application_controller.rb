class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :devise_controller?

  include Pagy::Backend

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path, alert: t("errors.not_found")
  end

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html { redirect_to root_path, alert: exception.message }
      format.json { render json: { error: exception.message }, status: :forbidden }
    end
  end
end
