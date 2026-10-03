require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "returns ok" do
    get "/api/v1/health"

    assert_response :success
    assert_equal({ "status" => "ok" }, JSON.parse(response.body))
  end
end
