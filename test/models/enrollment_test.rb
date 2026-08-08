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
require "test_helper"

class EnrollmentTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:enrollment).valid?
  end

  context "associations" do
    should belong_to(:user)
    should belong_to(:course)
    should have_many(:lesson_progresses).dependent(:destroy)
  end

  context "validations" do
    subject { create(:enrollment) }

    should validate_uniqueness_of(:user_id).scoped_to(:course_id)
    should validate_presence_of(:status)
    should validate_presence_of(:enrolled_at)
    should validate_inclusion_of(:discarded_by_course).in_array([ true, false ])

    should "validate enrolled_at is not in the future" do
      enrollment = build(:enrollment, enrolled_at: 1.day.from_now)

      assert_not enrollment.valid?
      assert_not_empty enrollment.errors[:enrolled_at]
    end
  end

  context "when status is expired" do
    should "validate presence of expired_at" do
      enrollment = build(:enrollment, status: :expired, expired_at: nil)

      assert_not enrollment.valid?
      assert_includes enrollment.errors[:expired_at], "can't be blank"
    end

    should "validate expired_at is greater than enrolled_at" do
      enrollment = build(:enrollment, status: :expired, enrolled_at: Time.current, expired_at: Time.current - 1.day)

      assert_not enrollment.valid?
    end
  end
end
