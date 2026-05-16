require "test_helper"
require "pry-rails"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)

    sign_in @user
  end

  test "should get index" do
    get users_url
    assert_response :success
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count", 1) do
      post users_url, params: { user: attributes_for(:user) }
    end

    assert_redirected_to users_url
  end

  test "should not create user" do
    assert_no_difference("User.count") do
      post users_url, params: { user: { email: "not-email" } }
    end

    assert_response :unprocessable_entity
  end

  test "should show user" do
    get user_url(@user)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_url(@user)
    assert_response :success
  end

  test "should not update user" do
    patch user_url(@user), params: { user: { email: "test" } }

    assert_response :unprocessable_entity
  end

  test "should destroy user" do
    delete user_url(@user)

    assert_redirected_to users_url
  end
end
