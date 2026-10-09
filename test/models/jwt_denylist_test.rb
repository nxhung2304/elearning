# == Schema Information
#
# Table name: jwt_denylists
#
#  id         :bigint           not null, primary key
#  exp        :datetime
#  jti        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_jwt_denylists_on_jti  (jti) UNIQUE
#
require "test_helper"

class JwtDenylistTest < ActiveSupport::TestCase
  test "encode and decode returns the same user" do
    user = create(:user)

    token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    decoded_user = Warden::JWTAuth::UserDecoder.new.call(token, :user, nil)

    assert_equal user, decoded_user
  end
end
