# == Schema Information
#
# Table name: roles
#
#  id         :bigint           not null, primary key
#  code       :string           not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_roles_on_code  (code) UNIQUE
#
require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:role).valid?
  end

  context "associations" do
    should have_many(:user_roles).dependent(:destroy)
    should have_many(:users).through(:user_roles)
  end

  context "validations" do
    subject { build(:role) }

    should validate_presence_of(:name)
    should validate_presence_of(:code)
    should validate_uniqueness_of(:code)
    should validate_uniqueness_of(:name)
    should validate_inclusion_of(:code).in_array(Role::CODES)
  end

  test "should not allow duplicate name" do
    create(:role, name: "Admin", code: "admin")
    duplicate_role = build(:role, name: "Admin", code: "admin2")

    assert_not duplicate_role.valid?
    assert_includes duplicate_role.errors[:name], "has already been taken"
  end

  test "should not allow duplicate code" do
    create(:role, name: "Admin", code: "admin")
    duplicate_role = build(:role, name: "Admin2", code: "admin")

    assert_not duplicate_role.valid?
    assert_includes duplicate_role.errors[:code], "has already been taken"
  end
end
