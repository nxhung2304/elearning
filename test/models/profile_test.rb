# == Schema Information
#
# Table name: profiles
#
#  id           :bigint           not null, primary key
#  bio          :text
#  discarded_at :datetime
#  full_name    :string           not null
#  phone        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_profiles_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:user)
  end

  context "validations" do
    subject { build(:profile) }

    should validate_presence_of(:full_name)
    should validate_uniqueness_of(:user_id)
  end

  test "valid factory" do
    assert create(:profile).valid?
  end

  test "discarded profile is excluded from kept scope" do
    profile = create(:profile)
    profile.discard

    assert_not profile.kept?
    assert Profile.discarded.include?(profile)
  end
end
