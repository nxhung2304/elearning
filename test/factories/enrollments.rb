# == Schema Information
#
# Table name: enrollments
#
#  id                  :bigint           not null, primary key
#  discarded_at        :datetime
#  discarded_by_course :boolean          default(FALSE), not null
#  enrolled_at         :datetime         not null
#  expired_at          :datetime
#  status              :integer          default("active"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  course_id           :bigint           not null
#  user_id             :bigint           not null
#
# Indexes
#
#  index_enrollments_on_course_id              (course_id)
#  index_enrollments_on_discarded_at           (discarded_at)
#  index_enrollments_on_user_id                (user_id)
#  index_enrollments_on_user_id_and_course_id  (user_id,course_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :enrollment do
    association :user
    association :course

    status { :active }
    enrolled_at { Time.current }
    expired_at { nil }
    discarded_at { nil }
    discarded_by_course { false }
  end
end
