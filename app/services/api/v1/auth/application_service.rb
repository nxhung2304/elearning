class Api::V1::Auth::ApplicationService
  private

  def generate_auth_result(user)
    token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)

    {
      token: token,
      user: UserEntity.represent(user)
    }
  end
end
