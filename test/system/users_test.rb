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
end
