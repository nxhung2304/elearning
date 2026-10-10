require "test_helper"

class Api::V1::AuthTest < ActionDispatch::IntegrationTest
  setup do
    Role.find_or_create_by!(code: Role::STUDENT) { |r| r.name = "Student" }
  end

  def post_json(path, params)
    post path, params: params.to_json, headers: { "CONTENT_TYPE" => "application/json" }
  end

  def sign_out_request(access_token: nil, refresh_token: nil)
    headers = { "CONTENT_TYPE" => "application/json" }
    headers["Authorization"] = "Bearer #{access_token}" if access_token
    params = refresh_token ? { refresh_token: refresh_token } : {}

    delete "/api/v1/auth/sign_out", params: params.to_json, headers: headers
  end

  def issue_access_token(user)
    access_token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    access_token
  end

  def issue_refresh_token(user, expires_at: nil)
    refresh_token_record = user.refresh_tokens.new
    raw_refresh_token = refresh_token_record.generate_token
    refresh_token_record.expires_at = expires_at if expires_at
    refresh_token_record.save!
    raw_refresh_token
  end

  def find_refresh_token_record(raw_refresh_token)
    RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(raw_refresh_token))
  end

  def json
    JSON.parse(response.body)
  end

  # --- sign_up ---

  test "sign_up creates a user with student role and returns token" do
    assert_difference("User.count", 1) do
      post_json "/api/v1/auth/sign_up", email: "new_student@example.com", password: "password123",
                                    password_confirmation: "password123", name: "New Student"
    end

    assert_response :created
    assert json["access_token"].present?
    assert_equal "new_student@example.com", json["user"]["email"]
    assert User.last.student?
  end

  test "sign_up does not expose encrypted_password" do
    post_json "/api/v1/auth/sign_up", email: "safe@example.com", password: "password123",
                                  password_confirmation: "password123"

    assert_response :created
    refute json["user"].key?("encrypted_password")
  end

  test "sign_up with duplicate email returns unprocessable entity" do
    create(:user, email: "dup@example.com")

    assert_no_difference("User.count") do
      post_json "/api/v1/auth/sign_up", email: "dup@example.com", password: "password123",
                                    password_confirmation: "password123"
    end

    assert_response :unprocessable_entity
    assert_includes json["errors"], "Email has already been taken"
  end

  test "sign_up with mismatched password confirmation returns unprocessable entity" do
    assert_no_difference("User.count") do
      post_json "/api/v1/auth/sign_up", email: "mismatch@example.com", password: "password123",
                                    password_confirmation: "other"
    end

    assert_response :unprocessable_entity
  end

  test "sign_up with missing required param returns bad request" do
    post_json "/api/v1/auth/sign_up", email: "incomplete@example.com", password: "password123"

    assert_response :unprocessable_entity
  end

  # --- sign_in ---

  test "sign_in with correct credentials returns token" do
    user = create(:user, password: "password123", password_confirmation: "password123")

    post_json "/api/v1/auth/sign_in", email: user.email, password: "password123"

    assert_response :success
    assert json["access_token"].present?
    assert_equal user.email, json["user"]["email"]
  end

  test "sign_in with wrong password returns error without revealing which field is wrong" do
    user = create(:user, password: "password123", password_confirmation: "password123")

    post_json "/api/v1/auth/sign_in", email: user.email, password: "wrong"

    assert_response :unprocessable_entity
    assert_equal [ "Invalid email or password" ], json["errors"]
  end

  test "sign_in with unknown email returns same generic error" do
    post_json "/api/v1/auth/sign_in", email: "nobody@example.com", password: "password123"

    assert_response :unprocessable_entity
    assert_equal [ "Invalid email or password" ], json["errors"]
  end

  test "sign_in as suspended user is rejected" do
    user = create(:user, :suspended, password: "password123", password_confirmation: "password123")

    post_json "/api/v1/auth/sign_in", email: user.email, password: "password123"

    assert_response :unprocessable_entity
  end

  test "sign_in as discarded user is rejected" do
    user = create(:user, password: "password123", password_confirmation: "password123")
    user.discard!

    post_json "/api/v1/auth/sign_in", email: user.email, password: "password123"

    assert_response :unprocessable_entity
  end

  # --- sign_out ---

  test "sign_out with valid token revokes it" do
    user = create(:user)
    raw_refresh_token = issue_refresh_token(user)

    assert_difference("JwtDenylist.count", 1) do
      sign_out_request(access_token: issue_access_token(user), refresh_token: raw_refresh_token)
    end

    assert_response :success
    assert_equal "Signed out successfully", json["message"]
    assert find_refresh_token_record(raw_refresh_token).revoked?
  end

  test "sign_out does not revoke other refresh tokens of the user" do
    user = create(:user)
    other_device_refresh_token = issue_refresh_token(user)

    sign_out_request(access_token: issue_access_token(user), refresh_token: issue_refresh_token(user))

    assert_response :success
    assert find_refresh_token_record(other_device_refresh_token).active?
  end

  test "sign_out does not revoke a refresh token of another user" do
    user = create(:user)
    other_user_refresh_token = issue_refresh_token(create(:user))

    sign_out_request(access_token: issue_access_token(user), refresh_token: other_user_refresh_token)

    assert_response :success
    assert find_refresh_token_record(other_user_refresh_token).active?
  end

  test "sign_out with an unknown refresh token still revokes the access token" do
    user = create(:user)

    assert_difference("JwtDenylist.count", 1) do
      sign_out_request(access_token: issue_access_token(user), refresh_token: "unknown-refresh-token")
    end

    assert_response :success
  end

  test "sign_out without an access token returns unauthorized" do
    sign_out_request(refresh_token: "any-refresh-token")

    assert_response :unauthorized
  end

  test "sign_out with a malformed access token returns unauthorized" do
    sign_out_request(access_token: "not-a-real-jwt", refresh_token: "any-refresh-token")

    assert_response :unauthorized
  end

  test "sign_out with an expired access token returns unauthorized" do
    user = create(:user)
    access_token = issue_access_token(user)

    travel_to(Warden::JWTAuth.config.expiration_time.seconds.from_now + 1.minute) do
      sign_out_request(access_token: access_token, refresh_token: issue_refresh_token(user))
    end

    assert_response :unauthorized
  end

  test "sign_out with an already revoked access token returns unauthorized" do
    user = create(:user)
    access_token = issue_access_token(user)
    sign_out_request(access_token: access_token, refresh_token: issue_refresh_token(user))

    sign_out_request(access_token: access_token, refresh_token: issue_refresh_token(user))

    assert_response :unauthorized
  end

  test "sign_out without refresh_token param returns unprocessable entity" do
    user = create(:user)

    sign_out_request(access_token: issue_access_token(user))

    assert_response :unprocessable_entity
  end

  # --- refresh ---

  test "refresh with valid token returns new tokens and revokes the old one" do
    user = create(:user)
    raw_refresh_token = issue_refresh_token(user)

    post_json "/api/v1/auth/refresh", refresh_token: raw_refresh_token

    assert_response :success
    assert json["access_token"].present?
    assert json["refresh_token"].present?
    assert_not_equal raw_refresh_token, json["refresh_token"]
    assert find_refresh_token_record(raw_refresh_token).revoked?
    assert find_refresh_token_record(json["refresh_token"]).active?
  end

  test "refresh works without an access token" do
    user = create(:user)

    post_json "/api/v1/auth/refresh", refresh_token: issue_refresh_token(user)

    assert_response :success
  end

  test "refresh with a reused old token returns unauthorized" do
    user = create(:user)
    raw_refresh_token = issue_refresh_token(user)
    post_json "/api/v1/auth/refresh", refresh_token: raw_refresh_token

    post_json "/api/v1/auth/refresh", refresh_token: raw_refresh_token

    assert_response :unauthorized
  end

  test "refresh with an expired token returns unauthorized" do
    user = create(:user)

    post_json "/api/v1/auth/refresh", refresh_token: issue_refresh_token(user, expires_at: 1.minute.ago)

    assert_response :unauthorized
  end

  test "refresh with an unknown token returns unauthorized" do
    post_json "/api/v1/auth/refresh", refresh_token: "unknown-refresh-token"

    assert_response :unauthorized
  end

  test "refresh with a token revoked by sign_out returns unauthorized" do
    user = create(:user)
    raw_refresh_token = issue_refresh_token(user)
    sign_out_request(access_token: issue_access_token(user), refresh_token: raw_refresh_token)

    post_json "/api/v1/auth/refresh", refresh_token: raw_refresh_token

    assert_response :unauthorized
  end

  test "refresh as discarded user returns unauthorized" do
    user = create(:user)
    raw_refresh_token = issue_refresh_token(user)
    user.discard!

    post_json "/api/v1/auth/refresh", refresh_token: raw_refresh_token

    assert_response :unauthorized
  end

  test "refresh as suspended user returns unauthorized" do
    user = create(:user, :suspended)

    post_json "/api/v1/auth/refresh", refresh_token: issue_refresh_token(user)

    assert_response :unauthorized
  end

  test "refresh without refresh_token param returns unprocessable entity" do
    post_json "/api/v1/auth/refresh", {}

    assert_response :unprocessable_entity
  end
end
