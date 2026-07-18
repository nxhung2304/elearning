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
class EventLog < ApplicationRecord
  ALLOWED_EVENT_TYPES = [
    CourseEvent, UserEvent
  ].flat_map { |mod| mod.constants.map { |c| mod.const_get(c) } }.freeze

  # associations
  belongs_to :user

  # validations
  validates :event_type, presence: true, inclusion: { in: ALLOWED_EVENT_TYPES }

  # custom validate
  validate :metadata_is_a_hash

  private

  def metadata_is_a_hash
    return if metadata.nil? || metadata.is_a?(Hash)

    errors.add(:metadata, :must_be_json)
  end
end
