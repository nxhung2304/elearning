require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  context "Student" do
    setup do
      @student = create(:user, :student)

      sign_in @student
    end

    should "can access to edit page" do
      get edit_profile_path

      assert_response :success
    end

    should "can update their own profile" do
      dummy_name = "New name"
      patch profile_path, params: { profile: { full_name: dummy_name } }
      @student.profile.reload

      assert_redirected_to edit_profile_path
      assert_equal dummy_name, @student.profile.full_name
    end
  end

  context "Teacher" do
    setup do
      @teacher = create(:user, :teacher)

      sign_in @teacher
    end

    should "can access to edit page" do
      get edit_profile_path

      assert_response :success
    end

    should "can update their own profile" do
      dummy_name = "New name"
      patch profile_path, params: { profile: { full_name: dummy_name } }
      @teacher.profile.reload

      assert_redirected_to edit_profile_path
      assert_equal dummy_name, @teacher.profile.full_name
    end
  end
end
