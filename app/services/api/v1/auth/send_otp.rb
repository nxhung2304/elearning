class Api::V1::Auth::SendOtp < Api::V1::Auth::ApplicationService
  COOLDOWN = 60.seconds
  MAX_PER_HOUR = 5

  def initialize(raw_email)
    @raw_email = raw_email
  end

  def call
    ActiveRecord::Base.transaction do
      user = User.kept.lock.find_by(email: @raw_email)

      return if user.nil? || rate_limited?(user)

      user.generate_otp!
      OtparyMailer.send_otp(user).deliver_later
      nil
    rescue StandardError => e
      Rails.logger.error "Send otp failed: #{e.message}"
      { errors: [ "Send otp failed" ] }
    end
  end

  private

  def rate_limited?(user)
    cooldown_not_finished = user.otp_sent_at.present? && user.otp_sent_at > COOLDOWN.ago
    return true if cooldown_not_finished

    send_count = Rails.cache.increment(
      "otp_send_count:#{user.id}",
      1,
      expires_in: 1.hour
    )

    send_count.nil? || send_count > MAX_PER_HOUR
  end
end
