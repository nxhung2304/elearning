# == Schema Information
#
# Table name: user_roles
#
#  id      :bigint           not null, primary key
#  role_id :bigint           not null
#  user_id :bigint           not null
#
# Indexes
#
#  index_user_roles_on_user_id_and_role_id  (user_id,role_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (role_id => roles.id)
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class UserRoleTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:user_role).valid?
  end

  context "associations" do
    should belong_to(:user)
    should belong_to(:role)
  end

  context "validations" do
    subject { build(:user_role) }

    should validate_presence_of(:user)
    should validate_presence_of(:role)
    should validate_uniqueness_of(:user_id).scoped_to(:role_id)
  end

  test "invalid when duplicate user_role" do
    user = create(:user)
    role = create(:role)
    create(:user_role, user: user, role: role)

    duplicate_user_role = build(:user_role, user: user, role: role)

    assert_not duplicate_user_role.valid?
    assert_includes duplicate_user_role.errors[:user_id], "has already been taken"
  end
end
