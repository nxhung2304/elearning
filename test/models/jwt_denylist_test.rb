require "test_helper"

class JwtDenylistTest < ActiveSupport::TestCase
  test "encode and decode returns the same user" do
    user = create(:user)

    token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    decoded_user = Warden::JWTAuth::UserDecoder.new.call(token, :user, nil)

    assert_equal user, decoded_user
  end
end
