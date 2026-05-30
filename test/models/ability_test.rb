require "test_helper"

class AbilityTest < ActiveSupport::TestCase
  # Admin abilities
  test "admin can manage all" do
    admin = create(:user, :admin)
    ability = Ability.new(admin)
    assert ability.can?(:manage, :all)
  end

  # Teacher abilities
  test "teacher can read all and dashboard" do
    teacher = create(:user, :teacher)
    ability = Ability.new(teacher)

    assert ability.can?(:read, :all)
    assert ability.can?(:read, :dashboard)
    assert_not ability.can?(:manage, :all)
  end

  # Student abilities
  test "student can read own profile and dashboard" do
    student = create(:user, :student)
    ability = Ability.new(student)

    assert ability.can?(:read, student)
    assert ability.can?(:read, :dashboard)
    assert_not ability.can?(:read, :all)
    assert_not ability.can?(:manage, :all)
  end

  test "student cannot read other user profile" do
    student = create(:user, :student)
    other_user = create(:user)
    ability = Ability.new(student)
    assert_not ability.can?(:read, other_user)
  end

  # Suspended / inactive user
  test "suspended user has no abilities" do
    suspended_user = create(:user, :suspended, :admin)
    ability = Ability.new(suspended_user)

    assert_not ability.can?(:read, :dashboard)
    assert_not ability.can?(:manage, :all)
  end

  test "inactive user has no abilities" do
    inactive_user = create(:user, :inactive, :admin)
    ability = Ability.new(inactive_user)

    assert_not ability.can?(:read, :dashboard)
    assert_not ability.can?(:manage, :all)
    assert_not ability.can?(:read, :all)
    assert_not ability.can?(:read, User, id: inactive_user.id)
  end

  # Unauthenticated user
  test "guest user has no abilities" do
    ability = Ability.new(nil)

    assert_not ability.can?(:read, :dashboard)
  end

  test "student cannot update another user's profile" do
    student = create(:user, :student)
    other_profile = create(:profile)
    ability = Ability.new(student)

    assert_not ability.can?(:update, other_profile)
  end

  test "teacher cannot update another user's profile" do
    teacher = create(:user, :teacher)
    other_profile = create(:profile)
    ability = Ability.new(teacher)

    assert_not ability.can?(:update, other_profile)
  end
end
