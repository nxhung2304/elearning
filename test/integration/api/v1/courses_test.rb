require "test_helper"

class Api::V1::CoursesTest < ActionDispatch::IntegrationTest
  COURSES_PATH = "/api/v1/courses".freeze
  PER_PAGE = Pagy::DEFAULT[:limit]

  setup do
    Course.delete_all
    @user = create(:user)
  end

  def get_courses(query = "", user: @user)
    headers = user ? { "Authorization" => "Bearer #{issue_access_token(user)}" } : {}
    get "#{COURSES_PATH}?#{query}", headers: headers
  end

  def issue_access_token(user)
    access_token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    access_token
  end

  def json
    JSON.parse(response.body)
  end

  def titles
    json["data"].map { |item| item["title"] }
  end

  def create_published_course(published_at: Time.current, **attributes)
    course = create(:course, :published, **attributes)
    course.update_columns(published_at: published_at)
    course
  end

  test "requires a token" do
    get_courses(user: nil)

    assert_response :unauthorized
    assert_equal "unauthorized", json["errors"].first["code"]
  end

  test "rejects an invalid token" do
    get COURSES_PATH, headers: { "Authorization" => "Bearer invalid.token.value" }

    assert_response :unauthorized
    assert_equal "unauthorized", json["errors"].first["code"]
  end

  test "returns only published and kept courses" do
    published = create_published_course
    create(:course)
    create(:course, :archived)
    discarded = create_published_course
    discarded.discard

    get_courses

    assert_response :ok
    assert_equal [ published.title ], titles
  end

  test "orders by published_at descending then id descending" do
    older = create_published_course(published_at: 2.days.ago)
    same_time = 1.day.ago
    first_tied = create_published_course(published_at: same_time)
    second_tied = create_published_course(published_at: same_time)

    get_courses

    assert_equal [ second_tied.title, first_tied.title, older.title ], titles
  end

  test "returns the documented fields for each item" do
    course = create_published_course(price: 49.5, total_lessons: 12)

    get_courses

    item = json["data"].first
    assert_equal %w[category id level price slug teacher title total_lessons], item.keys.sort
    assert_equal course.id, item["id"]
    assert_equal "beginner", item["level"]
    assert_equal "49.5", item["price"]
    assert_equal 12, item["total_lessons"]
    assert_equal({ "id" => course.category.id, "name" => course.category.name }, item["category"])
    assert_equal({ "id" => course.teacher.id, "name" => course.teacher.name }, item["teacher"])
  end

  test "returns a free course price as a string" do
    create_published_course(price: 0)

    get_courses

    assert_equal "0.0", json["data"].first["price"]
  end

  test "returns a null teacher name when the teacher has no name" do
    teacher = create(:user, name: nil)
    create_published_course(teacher: teacher)

    get_courses

    assert_nil json["data"].first["teacher"]["name"]
  end

  test "paginates with a full page before the last page" do
    (PER_PAGE + 1).times { create_published_course }
    create(:course, :published).discard

    get_courses

    assert_equal PER_PAGE, json["data"].size
    assert_equal({ "page" => 1, "per_page" => PER_PAGE, "total_pages" => 2, "total_count" => PER_PAGE + 1 }, json["meta"])

    get_courses("page=2")

    assert_equal 1, json["data"].size
    assert_equal 2, json["meta"]["page"]
  end

  test "returns an empty page with meta when page is beyond the last page" do
    create_published_course

    get_courses("page=999")

    assert_response :ok
    assert_equal [], json["data"]
    assert_equal 1, json["meta"]["total_count"]
    assert_equal 999, json["meta"]["page"]
  end

  test "returns an empty list with meta when there are no courses" do
    get_courses

    assert_response :ok
    assert_equal [], json["data"]
    assert_equal 0, json["meta"]["total_count"]
  end

  test "filters by level" do
    beginner = create_published_course(level: :beginner)
    create_published_course(level: :advanced)

    get_courses("q[level_eq]=#{Course.levels[:beginner]}")

    assert_equal [ beginner.title ], titles
  end

  test "filters by title ignoring case" do
    match = create_published_course(title: "Learn Ruby Fast")
    create_published_course(title: "Learn Go")

    get_courses("q[title_i_cont]=rUBY")

    assert_equal [ match.title ], titles
  end

  test "filters by category including its subtree" do
    parent = create(:course_category)
    child = create(:course_category, parent: parent)
    discarded_child = create(:course_category, parent: parent)
    in_parent = create_published_course(category: parent)
    in_child = create_published_course(category: child)
    create_published_course

    get_courses("q[category_id_eq]=#{parent.id}")

    assert_equal [ in_parent.title, in_child.title ].sort, titles.sort

    discarded_child.discard
    get_courses("q[category_id_eq]=#{child.id}")

    assert_equal [ in_child.title ], titles
  end

  test "excludes courses under a discarded subcategory when filtering by its ancestor" do
    parent = create(:course_category)
    kept_child = create(:course_category, parent: parent)
    discarded_child = create(:course_category, parent: parent)
    grandchild_under_discarded = create(:course_category, parent: discarded_child)
    in_kept_child = create_published_course(category: kept_child)
    create_published_course(category: discarded_child).discard
    create_published_course(category: grandchild_under_discarded).discard
    discarded_child.discard

    get_courses("q[category_id_eq]=#{parent.id}")

    assert discarded_child.reload.discarded?
    assert grandchild_under_discarded.reload.discarded?
    assert_equal [ in_kept_child.title ], titles
  end

  test "returns an empty list with meta for a discarded category" do
    category = create(:course_category)
    create_published_course(category: category).discard
    category.discard

    get_courses("q[category_id_eq]=#{category.id}")

    assert category.reload.discarded?
    assert_response :ok
    assert_equal [], json["data"]
    assert_equal 0, json["meta"]["total_count"]
  end

  test "combines category and level filters" do
    parent = create(:course_category)
    child = create(:course_category, parent: parent)
    create_published_course(category: parent, level: :beginner)
    advanced_in_child = create_published_course(category: child, level: :advanced)

    get_courses("q[category_id_eq]=#{parent.id}&q[level_eq]=#{Course.levels[:advanced]}")

    assert_equal [ advanced_in_child.title ], titles
  end

  test "returns an empty list with meta for an unknown category" do
    create_published_course

    get_courses("q[category_id_eq]=0")

    assert_response :ok
    assert_equal [], json["data"]
    assert_equal 0, json["meta"]["total_count"]
  end

  test "returns an empty list with meta when no course matches the filters" do
    create_published_course(title: "Learn Ruby")

    get_courses("q[title_i_cont]=nomatch")

    assert_response :ok
    assert_equal [], json["data"]
    assert_equal 0, json["meta"]["total_count"]
  end

  test "ignores filters that are not part of the contract" do
    create_published_course

    get_courses("q[status_eq]=#{Course.statuses[:draft]}&q[price_gt]=999999")

    assert_equal 1, json["data"].size
  end

  test "rejects invalid params with invalid_params" do
    [ "q[level_eq]=9", "q[level_eq]=abc", "page=0", "page=abc", "q[category_id_eq]=abc" ].each do |query|
      get_courses(query)

      assert_response :unprocessable_entity, query
      assert_equal "invalid_params", json["errors"].first["code"], query
    end
  end
end
