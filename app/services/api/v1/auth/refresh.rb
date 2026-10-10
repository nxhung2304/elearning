class Api::V1::Auth::Refresh < Api::V1::Auth::ApplicationService
  def initialize(raw_refresh_token)
    @raw_refresh_token = raw_refresh_token
  end

  def call
    ActiveRecord::Base.transaction do
      digest = Digest::SHA256.hexdigest(@raw_refresh_token)
      old_refresh_token_record = RefreshToken.active.lock.find_by(token_digest: digest)

      return { errors: [ "Invalid or expired token" ], status: 401 } unless old_refresh_token_record

      user = old_refresh_token_record.user

      return { errors: [ "Invalid or expired token" ], status: 401 } unless user.kept? && user.active_for_authentication?

      old_refresh_token_record.update!(revoked_at: Time.current)

      new_access_token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
      new_refresh_token_record = user.refresh_tokens.new
      new_refresh_token = new_refresh_token_record.generate_token

      new_refresh_token_record.save!

      {
        access_token: new_access_token,
        refresh_token: new_refresh_token,
        expires_in: Warden::JWTAuth.config.expiration_time,
        user: user
      }
    end
  rescue StandardError => e
    Rails.logger.error "Token rotation failed: #{e.message}"
    { errors: [ "Token rotation failed" ] }
  end
end
