class Api::V1::Auth::ResetPassword < Api::V1::Auth::ApplicationService
  def initialize(current_user, params)
    @params = params
    @current_user = current_user
  end

  def call
    original_token = reset_password_params[:reset_password_token]
    enc_token = Devise.token_generator.digest(User, :reset_password_token, original_token)

    user = User.find_by(reset_password_token: enc_token)

    if user.blank?
      return failure(Api::ErrorCodes::RESET_TOKEN_INVALID, message: "Reset token invalid")
    end

    if user.reset_password_period_valid? == false
      return failure(Api::ErrorCodes::RESET_TOKEN_EXPIRED, message: "Reset token expired")
    end

    resource = User.reset_password_by_token(reset_password_params)

    if resource.errors.empty?
      { message: "Password updated successfully." }
    else
      validation_failure(resource)
    end
  end

  private

  def reset_password_params
    @params.slice(:reset_password_token, :password, :password_confirmation)
  end
end
