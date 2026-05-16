# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  status                 :integer          default(1), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_status                (status)
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  context "validations" do
    should define_enum_for(:status).with_values(inactive: 0, active: 1, suspended: 2, deleted: 3).with_prefix(:status)
  end

  test "valid with email and password" do
    assert build(:user).valid?
  end

  test "invalid without email" do
    assert_not build(:user, email: nil).valid?
  end

  test "email must be unique" do
    create(:user, email: "dup@example.com")
    assert_not build(:user, email: "dup@example.com").valid?
  end

  test "all status values are valid" do
    assert build(:user, status: :inactive).valid?
    assert build(:user, status: :active).valid?
    assert build(:user, status: :suspended).valid?
    assert build(:user, status: :deleted).valid?
  end

  test "active_for_authentication? is true when active" do
    assert build(:user, status: :active).active_for_authentication?
  end

  test "active_for_authentication? is false when inactive" do
    assert_not build(:user, status: :inactive).active_for_authentication?
  end

  test "active_for_authentication? is false when suspended" do
    assert_not build(:user, status: :suspended).active_for_authentication?
  end

  test "active_for_authentication? is false when deleted" do
    assert_not build(:user, status: :deleted).active_for_authentication?
  end

  test "inactive_message is :inactive when status is inactive" do
    assert_equal :inactive, build(:user, status: :inactive).inactive_message
  end

  test "inactive_message is :suspended when status is suspended" do
    assert_equal :suspended, build(:user, status: :suspended).inactive_message
  end

  test "inactive_message is :deleted when status is deleted" do
    assert_equal :deleted, build(:user, status: :deleted).inactive_message
  end
end
