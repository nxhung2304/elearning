class Api::V1::Auth::ApplicationService
  private

  def generate_auth_result(
    user,
    access_token_expiration: Warden::JWTAuth.config.expiration_time,
    refresh_token_expiration: RefreshToken::REFRESH_TOKEN_EXPIRATION_DAYS.days
  )
    access_token_payload = Warden::JWTAuth::PayloadUserHelper.payload_for_user(user, :user)
      .merge("aud" => nil, "exp" => Time.now.to_i + access_token_expiration.to_i)
    access_token = Warden::JWTAuth::TokenEncoder.new.call(access_token_payload)
    refresh_token = user.refresh_tokens.new
    raw_token = refresh_token.generate_token(refresh_token_expiration)

    refresh_token.save!

    {
      access_token: access_token,
      refresh_token: raw_token,
      expires_in: access_token_expiration.to_i,
      user: user
    }
  end

  def failure(code, message:, status: Api::ErrorCodes.status_for(code), **extra)
    Api::ErrorCodes.body(code, message, **extra).merge(status: status)
  end

  def validation_failure(record)
    errors = record.errors.full_messages.map do |message|
      { code: Api::ErrorCodes::VALIDATION_FAILED, message: message }
    end

    { errors: errors, status: Api::ErrorCodes.status_for(Api::ErrorCodes::VALIDATION_FAILED) }
  end
end
