require "test_helper"
require "pry-rails"

class LessonsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers if defined?(Devise)

  setup do
    @lesson = lessons(:one) if respond_to?(:lessons)
    @user = users(:admin) if respond_to?(:users)
    sign_in @user if respond_to?(:sign_in) && @user
    # @role = roles(:admin)
  end

  test "should get index" do
    get lessons_url
    assert_response :success
  end

  test "should get new" do
    get new_lesson_url
    assert_response :success
  end

  test "should create lesson" do
    assert_difference("Lesson.count", 1) do
      post lessons_url, params: { lesson: {
                # TODO: add valid attributes
              } }
    end

    assert_redirected_to lessons_url
  end

  test "should not create lesson" do
    assert_no_difference("Lesson.count") do
      post lessons_url, params: { lesson: {
        # TODO: add invalid attributes
      } }
    end

    assert_response :success
  end

  test "should show lesson" do
    get lesson_url(@lesson)
    assert_response :success
  end
  test "should update lesson as admin" do
    patch lesson_url(@lesson), params: { lesson: {
            # TODO: add valid attributes
          } }
    
    assert_redirected_to lessons_url
  end

  test "should update lesson as non-admin" do
    # sign_in users(:user) # Use a non-admin fixture
    patch lesson_url(@lesson), params: { lesson: {
            # TODO: add valid attributes
          } }
    
    # This assertion depends on the current_user role and the controller logic
    # assert_redirected_to edit_lesson_path(@lesson)
  end

  test "should not update lesson" do
    # Assuming assert_no_changes is available or use assert_equal
    patch lesson_url(@lesson), params: { lesson: {
      # TODO: add invalid attributes
    } }

    assert_response :success
  end

  test "should destroy lesson" do
    assert_difference("Lesson.count", -1) do
      delete lesson_url(@lesson)
    end

    assert_redirected_to lessons_url
  end

end
