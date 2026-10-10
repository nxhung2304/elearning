Devise.setup do |config|
  config.mailer_sender = "no-reply@example.com"
  require "devise/orm/active_record"

  config.jwt do |jwt|
    jwt.secret = ENV["DEVISE_JWT_SECRET_KEY"]
    jwt.dispatch_requests = [ [ "POST", %r{^/api/v1/auth/sign_in$} ] ]
    jwt.expiration_time = 1.day.to_i
  end
end
