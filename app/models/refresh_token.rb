class RefreshToken < ApplicationRecord
  REFRESH_TOKEN_LENGTH = 64
  REFRESH_TOKEN_EXPIRATION_DAYS = 30

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def expired?
    expires_at <= Time.current
  end

  def generate_token
    token = SecureRandom.urlsafe_base64(REFRESH_TOKEN_LENGTH)

    self.token_digest = Digest::SHA256.hexdigest(token)
    self.expires_at = REFRESH_TOKEN_EXPIRATION_DAYS.days.from_now

    token
  end

  def revoked?
    revoked_at.present?
  end

  def active?
    !expired? && !revoked?
  end
end
