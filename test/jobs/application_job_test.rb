require "test_helper"

class ApplicationJobTest < ActiveJob::TestCase
  class DeadlockRaisingJob < ApplicationJob
    def perform
      raise ActiveRecord::Deadlocked, "deadlock detected"
    end
  end

  def queue_adapter_for_test
    ActiveJob::QueueAdapters::TestAdapter.new
  end

  test "reschedules itself instead of raising when ActiveRecord::Deadlocked occurs" do
    assert_enqueued_with(job: DeadlockRaisingJob) do
      assert_nothing_raised do
        DeadlockRaisingJob.perform_now
      end
    end
  end
end
