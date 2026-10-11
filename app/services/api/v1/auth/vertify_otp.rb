class Api::V1::Auth::VertifyOtp < Api::V1::Auth::ApplicationService
  MAX_ATTEMPTS = 3
  RESET_TOKEN_EXPIRATION = 10.minutes

  def initialize(email, raw_otp_code)
    @email = email
    @raw_otp_code = raw_otp_code
  end

  def call
    ActiveRecord::Base.transaction do
      user = User.kept.lock.find_by(email: @email)

      return { errors: [ "OTP incorrect" ] } if user.nil?

      unless user.verify_otp?(@raw_otp_code)
        return { errors: [ register_failed_attempt(user) ] }
      end

      user.update!(otp_code: nil, otp_sent_at: nil)
      Rails.cache.delete(attempts_key(user))

      { reset_token: generate_reset_token(user) }
    end
  rescue StandardError => e
    Rails.logger.error "Verify otp failed: #{e.message}"
    { errors: [ "Verify otp failed" ] }
  end

  private

  def register_failed_attempt(user)
    attempts = Rails.cache.increment(attempts_key(user), 1, expires_in: User::OTP_EXPIRATION_TIME)

    if attempts.nil? || attempts >= MAX_ATTEMPTS
      user.update!(otp_code: nil, otp_sent_at: nil)
      Rails.cache.delete(attempts_key(user))

      return "Too many failed attempts, please request a new OTP"
    end

    "OTP incorrect"
  end

  def attempts_key(user)
    "otp_attempts:#{user.id}"
  end

  def generate_reset_token(user)
    payload = {
      user_id: user.id,
      scope: "password_reset",
      exp: RESET_TOKEN_EXPIRATION.from_now.to_i
    }

    JWT.encode(payload, ENV["DEVISE_JWT_SECRET_KEY"], "HS256")
  end
end
