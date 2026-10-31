class Api::ErrorCodes
  INVALID_PARAMS        = "invalid_params"
  UNAUTHORIZED          = "unauthorized"
  TOKEN_MISSING         = "token_missing"
  TOKEN_INVALID         = "token_invalid"
  REFRESH_TOKEN_INVALID = "refresh_token_invalid"
  INVALID_CREDENTIALS   = "invalid_credentials"
  VALIDATION_FAILED     = "validation_failed"
  OTP_RATE_LIMITED      = "otp_rate_limited"
  OTP_EXPIRED           = "otp_expired"
  OTP_ATTEMPTS_EXCEEDED = "otp_attempts_exceeded"
  INVALID_OTP           = "invalid_otp"
  RESET_TOKEN_INVALID   = "reset_token_invalid"
  RESET_TOKEN_EXPIRED   = "reset_token_expired"
  INTERNAL_ERROR        = "internal_error"

  STATUSES = {
    INVALID_PARAMS => 422,
    UNAUTHORIZED => 401,
    TOKEN_MISSING => 400,
    TOKEN_INVALID => 401,
    REFRESH_TOKEN_INVALID => 401,
    OTP_RATE_LIMITED => 429,
    INTERNAL_ERROR => 500
  }.freeze

  def self.status_for(code) = STATUSES.fetch(code, 422)

  def self.body(code, message, **extra)
    { errors: [ { code: code, message: message, **extra } ] }
  end
end
