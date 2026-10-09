class Api::V1::Auth::ApplicationService
  private

  def generate_auth_result(user)
    access_token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    refresh_token = user.refresh_tokens.new
    raw_token = refresh_token.generate_token

    refresh_token.save!

    {
      access_token: access_token,
      refresh_token: raw_token,
      expires_in: Warden::JWTAuth.config.expiration_time,
      user: user
    }
  end
end
