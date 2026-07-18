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
FactoryBot.define do
  factory :event_log do
    event_type { UserEvent::LOGIN }
    association :user

    trait :login_event do
      event_type { UserEvent::LOGIN }
      metadata { { ip_address: "192.168.1.0" } }
    end
  end
end
