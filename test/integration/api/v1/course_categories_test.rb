require "test_helper"

class Api::V1::CourseCategoriesTest < ActionDispatch::IntegrationTest
  CATEGORIES_PATH = "/api/v1/course_categories".freeze

  setup do
    @user = create(:user)
  end

  def get_categories(user: @user)
    headers = user ? { "Authorization" => "Bearer #{issue_access_token(user)}" } : {}
    get CATEGORIES_PATH, headers: headers
  end

  def issue_access_token(user)
    access_token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    access_token
  end

  def json
    JSON.parse(response.body)
  end

  test "requires a token" do
    get_categories(user: nil)

    assert_response :unauthorized
    assert_equal "unauthorized", json["errors"].first["code"]
  end

  test "returns a flat list with id, name and parent_id" do
    parent = create(:course_category)
    child = create(:course_category, parent: parent)

    get_categories

    assert_response :ok
    items = json["data"].index_by { |item| item["id"] }
    assert_equal %w[id name parent_id], items[parent.id].keys.sort
    assert_nil items[parent.id]["parent_id"]
    assert_equal parent.id, items[child.id]["parent_id"]
  end

  test "excludes discarded categories" do
    kept = create(:course_category)
    discarded = create(:course_category)
    discarded.discard

    get_categories

    ids = json["data"].map { |item| item["id"] }
    assert_includes ids, kept.id
    assert_not_includes ids, discarded.id
  end

  test "orders by position" do
    third = create(:course_category)
    first = create(:course_category)
    second = create(:course_category)
    first.update!(position: 1)
    second.update!(position: 2)
    third.update!(position: 3)

    get_categories

    ids = json["data"].map { |item| item["id"] }
    assert_equal [ first.id, second.id, third.id ], ids & [ first.id, second.id, third.id ]
  end
end
