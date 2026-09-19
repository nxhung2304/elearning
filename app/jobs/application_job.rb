class ApplicationJob < ActiveJob::Base
  queue_as :default

  retry_on ActiveRecord::Deadlocked
end
