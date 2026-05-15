require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Elearning
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])
    config.active_job.queue_adapter = :sidekiq

    config.generators do |g|
      g.orm :active_record, migration: true
      g.test_framework :test_unit, fixture: false
      g.fixture_replacement :factory_bot, dir: "test/factories"
    end
  end
end
