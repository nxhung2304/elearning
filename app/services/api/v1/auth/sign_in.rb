class Api::V1::Auth::SignIn < Api::V1::Auth::ApplicationService
  def initialize(params)
    @params = params
  end

  def call
    user = User.kept.find_for_authentication(email: @params[:email])
    authenticated = user&.valid_password?(@params[:password]) && user.active_for_authentication?

    if authenticated
      generate_auth_result(user)
    else
      { errors: [ "Invalid email or password" ] }
    end
  end
end
