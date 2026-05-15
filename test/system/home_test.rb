require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "root redirects unauthenticated users to sign in" do
    visit root_path

    assert_current_path new_user_session_path
  end
end
