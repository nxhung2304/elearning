Devise.setup do |config|
  config.mailer_sender = "no-reply@example.com"
  require "devise/orm/active_record"
end
