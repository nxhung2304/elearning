class ProfilesController < ApplicationController
  before_action :set_profile, only: %i[edit update]

  authorize_resource

  def edit; end

  def update
    if @profile.update(profile_params)
      flash[:success] = t("controller.updated", text: Profile.model_name.human)
      redirect_to edit_profile_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def set_profile
      @profile = current_user.profile || current_user.build_profile
    end

    def profile_params
      params.require(:profile).permit(
        :full_name,
        :phone,
        :bio,
        :avatar
      )
    end
end
