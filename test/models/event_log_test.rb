# == Schema Information
#
# Table name: event_logs
#
#  id         :bigint           not null, primary key
#  event_type :string           not null
#  metadata   :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_event_logs_on_event_type                 (event_type)
#  index_event_logs_on_event_type_and_created_at  (event_type,created_at)
#  index_event_logs_on_user_id                    (user_id)
#  index_event_logs_on_user_id_and_event_type     (user_id,event_type)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class EventLogTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:event_log).valid?
  end

  context "validations" do
    should validate_presence_of(:event_type)
    should validate_inclusion_of(:event_type).in_array(EventLog::ALLOWED_EVENT_TYPES)
  end

  context "associations" do
    should belong_to(:user)
  end
end
