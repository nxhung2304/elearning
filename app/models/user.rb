# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  discarded_at           :datetime
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  name                   :string
#  otp_code               :string(6)
#  otp_sent_at            :datetime
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  status                 :integer          default("active"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_discarded_at          (discarded_at)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_status                (status)
#
class User < ApplicationRecord
  OTP_EXPIRATION_TIME = 5.minutes

  include Discard::Model

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_one :profile

  enum :status, { inactive: 0, active: 1, suspended: 2, deleted: 3 }, default: :active, prefix: true

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :courses, foreign_key: "teacher_id", dependent: :restrict_with_error
  has_many :enrollments, dependent: :restrict_with_error
  has_many :refresh_tokens, dependent: :destroy

  validates :status, presence: true
  validates :otp_sent_at, comparison: { less_than_or_equal_to: -> { Time.current } }, allow_blank: true
  validates :otp_code, length: { maximum: 6 }

  scope :teachers, -> {
    joins(:roles).where(roles: { code: Role::TEACHER })
  }

  before_validation :normalize_email

  def active_for_authentication?
    super && status_active?
  end

  def inactive_message
    case
    when status_inactive?  then :inactive
    when status_suspended? then :suspended
    when status_deleted?   then :deleted
    else super
    end
  end

  def to_s = name.presence || email

  def has_role?(role_code)
    roles.any? { |role| role.code == role_code.to_s }
  end

  def admin?
    has_role?(:admin)
  end

  def teacher?
    has_role?(:teacher)
  end

  def student?
    has_role?(:student)
  end

  def generate_otp!
    self.otp_code = rand(100000..999999).to_s
    self.otp_sent_at = Time.current

    save!
  end

  def invalidate_otp!
    self.otp_sent_at = nil
    self.otp_code = nil

    save!
  end

  def verify_otp?(input_code)
    return false if otp_code.blank? || otp_sent_at.blank?
    return false if Time.current > otp_sent_at + OTP_EXPIRATION_TIME

    otp_code == input_code
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end
