# == Schema Information
#
# Table name: refresh_tokens
#
#  id           :bigint           not null, primary key
#  expires_at   :datetime         not null
#  revoked_at   :datetime
#  token_digest :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_refresh_tokens_on_token_digest  (token_digest) UNIQUE
#  index_refresh_tokens_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class RefreshToken < ApplicationRecord
  REFRESH_TOKEN_LENGTH = 64
  REFRESH_TOKEN_EXPIRATION_DAYS = 30

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

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
