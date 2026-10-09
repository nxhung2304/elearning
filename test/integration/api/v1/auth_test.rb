require "test_helper"

class Api::V1::AuthTest < ActionDispatch::IntegrationTest
  setup do
    Role.find_or_create_by!(code: Role::STUDENT) { |r| r.name = "Student" }
  end

  def post_json(path, params)
    post path, params: params.to_json, headers: { "CONTENT_TYPE" => "application/json" }
  end

  def delete_with_token(path, token)
    delete path, headers: { "Authorization" => "Bearer #{token}" }
  end

  def json
    JSON.parse(response.body)
  end

  # --- sign_up ---

  test "sign_up creates a user with student role and returns token" do
    assert_difference("User.count", 1) do
      post_json "/api/v1/sign_up", email: "new_student@example.com", password: "password123",
                                    password_confirmation: "password123", name: "New Student"
    end

    assert_response :created
    assert json["access_token"].present?
    assert_equal "new_student@example.com", json["user"]["email"]
    assert User.last.student?
  end

  test "sign_up does not expose encrypted_password" do
    post_json "/api/v1/sign_up", email: "safe@example.com", password: "password123",
                                  password_confirmation: "password123"

    assert_response :created
    refute json["user"].key?("encrypted_password")
  end

  test "sign_up with duplicate email returns unprocessable entity" do
    create(:user, email: "dup@example.com")

    assert_no_difference("User.count") do
      post_json "/api/v1/sign_up", email: "dup@example.com", password: "password123",
                                    password_confirmation: "password123"
    end

    assert_response :unprocessable_entity
    assert_includes json["errors"], "Email has already been taken"
  end

  test "sign_up with mismatched password confirmation returns unprocessable entity" do
    assert_no_difference("User.count") do
      post_json "/api/v1/sign_up", email: "mismatch@example.com", password: "password123",
                                    password_confirmation: "other"
    end

    assert_response :unprocessable_entity
  end

  test "sign_up with missing required param returns bad request" do
    post_json "/api/v1/sign_up", email: "incomplete@example.com", password: "password123"

    assert_response :unprocessable_entity
  end

  # --- sign_in ---

  test "sign_in with correct credentials returns token" do
    user = create(:user, password: "password123", password_confirmation: "password123")

    post_json "/api/v1/sign_in", email: user.email, password: "password123"

    assert_response :success
    assert json["access_token"].present?
    assert_equal user.email, json["user"]["email"]
  end

  test "sign_in with wrong password returns error without revealing which field is wrong" do
    user = create(:user, password: "password123", password_confirmation: "password123")

    post_json "/api/v1/sign_in", email: user.email, password: "wrong"

    assert_response :unprocessable_entity
    assert_equal [ "Invalid email or password" ], json["errors"]
  end

  test "sign_in with unknown email returns same generic error" do
    post_json "/api/v1/sign_in", email: "nobody@example.com", password: "password123"

    assert_response :unprocessable_entity
    assert_equal [ "Invalid email or password" ], json["errors"]
  end

  test "sign_in as suspended user is rejected" do
    user = create(:user, :suspended, password: "password123", password_confirmation: "password123")

    post_json "/api/v1/sign_in", email: user.email, password: "password123"

    assert_response :unprocessable_entity
  end

  test "sign_in as discarded user is rejected" do
    user = create(:user, password: "password123", password_confirmation: "password123")
    user.discard!

    post_json "/api/v1/sign_in", email: user.email, password: "password123"

    assert_response :unprocessable_entity
  end

  # --- sign_out ---

  test "sign_out with valid token revokes it" do
    user = create(:user)
    token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)

    assert_difference("JwtDenylist.count", 1) do
      delete_with_token "/api/v1/sign_out", token
    end

    assert_response :success
    assert_equal "Signed out successfully", json["message"]
  end

  test "sign_out without a token returns bad request" do
    delete "/api/v1/sign_out"

    assert_response :bad_request
  end

  test "sign_out with a malformed token returns unauthorized" do
    delete_with_token "/api/v1/sign_out", "not-a-real-jwt"

    assert_response :unauthorized
  end
end
