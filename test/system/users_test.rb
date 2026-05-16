require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
    @user_two = create(:user)

    sign_in @user
  end

  test "visiting the index" do
    visit users_url
    assert_selector "h1", text: I18n.t("activerecord.models.user.other", default: "Users")
  end

  test "should create user" do
    visit users_url
    click_on I18n.t("helpers.links.new", model: User.model_name.human)

    new_user = build(:user)

    fill_in "user_email", with: new_user.email
    fill_in "user_password", with: new_user.password
    fill_in "user_password_confirmation", with: new_user.password
    select new_user.status, from: "user_status"

    click_on I18n.t("helpers.submit.create", model: User.model_name.human)

    assert_text I18n.t("controller.created", text: "#{User.model_name.human} #{new_user.email}")
  end

  test "should update user" do
    visit users_url
    find("#edit_user_#{@user.id}").click

    click_on I18n.t("helpers.submit.update", model: User.model_name.human)

    assert_text I18n.t("controller.updated", text: "#{User.model_name.human} #{@user.email}")
  end

  test "should destroy another user" do
    visit edit_user_url(@user_two)

    accept_confirm do
      click_on I18n.t("helpers.links.delete")
    end

    assert_text I18n.t("controller.destroyed", text: "#{User.model_name.human} #{@user_two.email}")
  end

  test "visiting the show page displays user details" do
    visit user_url(@user_two)

    assert_text @user_two.email
  end

  test "navigating from index to show via Show link" do
    visit users_url

    within("tr", text: @user_two.email) do
      click_on I18n.t("helpers.links.show", default: "Show")
    end

    assert_current_path user_path(@user_two)
    assert_text @user_two.email
  end

  test "searching by email filters results" do
    visit users_url

    fill_in "q[email_cont]", with: @user_two.email
    click_on I18n.t("helpers.search.submit", default: "Search")

    within("table tbody") do
      assert_text @user_two.email
      assert_no_text @user.email
    end
  end

  test "searching by name filters results" do
    visit users_url

    fill_in "q[name_cont]", with: @user_two.name
    click_on I18n.t("helpers.search.submit", default: "Search")

    within("table tbody") do
      assert_text @user_two.name
      assert_no_text @user.name
    end
  end

  test "searching by status filters results" do
    deleted_user = create(:user, :deleted)

    visit users_url

    select User.human_attribute_name("status.deleted"), from: "q[status_eq]"
    click_on I18n.t("helpers.search.submit", default: "Search")

    within("table tbody") do
      assert_text deleted_user.email
      assert_no_text @user.email
    end
  end

  test "delete button is hidden when editing self" do
    visit edit_user_url(@user)

    assert_no_text I18n.t("helpers.links.delete")
  end

  test "delete button is visible when editing another user" do
    visit edit_user_url(@user_two)

    assert_text I18n.t("helpers.links.delete")
  end

  test "create with duplicate email shows validation error" do
    visit new_user_url

    fill_in "user_email", with: @user_two.email
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"

    click_on I18n.t("helpers.submit.create", model: User.model_name.human)

    assert_text "Email has already been taken"
  end

  test "create with missing email shows validation error" do
    visit new_user_url

    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"

    click_on I18n.t("helpers.submit.create", model: User.model_name.human)

    assert_text "Email"
  end

  test "update with blank email shows validation error" do
    visit edit_user_url(@user)

    fill_in "user_email", with: ""
    click_on I18n.t("helpers.submit.update", model: User.model_name.human)

    assert_text "Email"
  end

  test "unauthenticated user is redirected to sign in" do
    sign_out @user
    visit users_url

    assert_current_path new_user_session_path
  end
end
