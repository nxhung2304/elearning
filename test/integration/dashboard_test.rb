require "test_helper"

class DashboardTest < ActionDispatch::IntegrationTest
  test "redirects guests to sign in" do
    get "/"

    assert_response :redirect
  end
end
