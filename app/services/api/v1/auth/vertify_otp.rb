class Api::V1::Auth::VertifyOtp < Api::V1::Auth::ApplicationService
  MAX_ATTEMPTS = 3

  def initialize(email, otp_code)
    @email = email
    @otp_code = otp_code
  end

  def call
    ActiveRecord::Base.transaction do
      user = User.kept.lock.find_by(email: @email)

      next failure(Api::ErrorCodes::OTP_EXPIRED, message: "OTP is expired or not requested") unless otp_active?(user)

      if otp_matches?(user)
        consume_otp!(user)

        raw_token = user.send(:set_reset_password_token)

        { reset_password_token: raw_token }
      else
        register_failed_attempt!(user)
      end
    end
  rescue StandardError => e
    Rails.logger.error("Verify OTP failed: #{e.message}")
    failure(Api::ErrorCodes::INTERNAL_ERROR, message: "Verify OTP failed")
  end

  private

  attr_reader :email, :otp_code

  def otp_active?(user)
    user.present? &&
      user.otp_code.present? &&
      user.otp_sent_at.present? &&
      user.otp_sent_at > User::OTP_EXPIRATION_TIME.ago
  end

  def otp_matches?(user)
    ActiveSupport::SecurityUtils.secure_compare(user.otp_code, otp_code)
  end

  def increment_attempts(user)
    attempts = Rails.cache.read(attempts_key(user)).to_i + 1
    Rails.cache.write(attempts_key(user), attempts, expires_in: User::OTP_EXPIRATION_TIME)
    attempts
  end

  def consume_otp!(user)
    Rails.cache.delete(attempts_key(user))
    user.invalidate_otp!
  end

  def register_failed_attempt!(user)
    attempts = increment_attempts(user)

    if attempts >= MAX_ATTEMPTS
      consume_otp!(user)
      failure(Api::ErrorCodes::OTP_ATTEMPTS_EXCEEDED, message: "Too many invalid attempts, please request a new OTP")
    else
      failure(Api::ErrorCodes::INVALID_OTP, message: "Invalid OTP", remaining_attempts: MAX_ATTEMPTS - attempts)
    end
  end

  def attempts_key(user)
    # otp_sent_at in key: a new OTP starts a fresh attempt count
    "otp_attempts:#{user.id}:#{user.otp_sent_at.to_i}"
  end
end
