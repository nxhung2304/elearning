# frozen_string_literal: true

if Rails.env.development?
  Rails.application.configure do
    config.action_mailer.delivery_method = :letter_opener_web
  end
end
