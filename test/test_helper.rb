ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "factory_bot_rails"
require "shoulda/matchers"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
    include FactoryBot::Syntax::Methods
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end
