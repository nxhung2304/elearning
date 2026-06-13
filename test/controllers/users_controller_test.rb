require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user, :admin)
    @other = create(:user)
    sign_in @user
  end

  # --- Happy path: access ---

  test "can access index" do
    get users_url
    assert_response :success
  end

  test "can access new" do
    get new_user_url
    assert_response :success
  end

  test "can access show for another user" do
    get user_url(@other)
    assert_response :success
  end

  test "can access edit" do
    get edit_user_url(@other)
    assert_response :success
  end

  test "me redirects to current user show" do
    get me_url
    assert_redirected_to user_url(@user)
  end

  # --- Happy path: mutations ---

  test "can create a user" do
    assert_difference("User.count", 1) do
      post users_url, params: { user: attributes_for(:user) }
    end
    assert_redirected_to user_url(User.last)
  end

  test "can update a user" do
    patch user_url(@other), params: { user: { name: "New Name" } }
    assert_redirected_to user_url(@other)
    assert_equal "New Name", @other.reload.name
  end

  test "destroy sets user status to deleted" do
    delete user_url(@other)
    assert @other.reload.status_deleted?
    assert_redirected_to users_url
  end

  test "cannot delete self" do
    delete user_url(@user)
    assert_redirected_to users_url
    refute @user.reload.status_deleted?
  end

  # --- Edge: unauthenticated ---

  test "index redirects when not signed in" do
    sign_out @user
    get users_url
    assert_redirected_to new_user_session_path
  end

  test "show redirects when not signed in" do
    sign_out @user
    get user_url(@other)
    assert_redirected_to new_user_session_path
  end

  test "new redirects when not signed in" do
    sign_out @user
    get new_user_url
    assert_redirected_to new_user_session_path
  end

  test "edit redirects when not signed in" do
    sign_out @user
    get edit_user_url(@other)
    assert_redirected_to new_user_session_path
  end

  test "create redirects when not signed in" do
    sign_out @user
    post users_url, params: { user: attributes_for(:user) }
    assert_redirected_to new_user_session_path
  end

  test "update redirects when not signed in" do
    sign_out @user
    patch user_url(@other), params: { user: { name: "X" } }
    assert_redirected_to new_user_session_path
  end

  test "destroy redirects when not signed in" do
    sign_out @user
    delete user_url(@other)
    assert_redirected_to new_user_session_path
  end

  # --- Edge: missing params ---

  test "create with missing email returns unprocessable entity" do
    assert_no_difference("User.count") do
      post users_url, params: { user: { name: "X" } }
    end
    assert_response :unprocessable_entity
  end

  test "update with blank email returns unprocessable entity" do
    patch user_url(@other), params: { user: { email: "" } }
    assert_response :unprocessable_entity
  end

  # --- Edge: record not found ---

  test "show with unknown id redirects" do
    get user_url(id: 0)
    assert_redirected_to root_url
  end

  test "update with unknown id redirects" do
    patch user_url(id: 0), params: { user: { name: "X" } }
    assert_redirected_to root_url
  end

  test "destroy with unknown id redirects" do
    delete user_url(id: 0)
    assert_redirected_to root_url
  end

  # --- Edge: duplicate email ---

  test "create with duplicate email returns unprocessable entity" do
    assert_no_difference("User.count") do
      post users_url, params: { user: attributes_for(:user).merge(email: @other.email) }
    end
    assert_response :unprocessable_entity
  end

  test "update with duplicate email returns unprocessable entity" do
    patch user_url(@user), params: { user: { email: @other.email } }
    assert_response :unprocessable_entity
  end
end
