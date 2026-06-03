## **Status:**
- Review: Approved
- PR: -

## Metadata
- **Title:** CourseCategory CRUD (Admin — Controller + Tests)
- **Phase:** 1 — MVP / Courses
- **GitHub Issue:** #24

---

## Description

Implement a `CourseCategoriesController` providing full Admin CRUD for course categories. Supports hierarchical display (via the `ancestry` gem), paginated listing with Ransack search by name, soft delete via `discard`, and slug-based lookup via `friendly_id`. Admin-only access enforced by CanCanCan.

---

## Acceptance Criteria

- [ ] `GET /course_categories` renders a paginated list (Pagy) of all kept categories; Ransack search by name
- [ ] `GET /course_categories/new` renders the new category form with a parent selector
- [ ] `POST /course_categories` creates a category; re-renders form on validation failure
- [ ] `GET /course_categories/:slug` shows a single category with its children listed
- [ ] `GET /course_categories/:slug/edit` renders the edit form
- [ ] `PATCH/PUT /course_categories/:slug` updates a category; re-renders on failure
- [ ] `DELETE /course_categories/:slug` soft-deletes (discards) the category and cascades to children; redirects to index
- [ ] Accessing any action as non-admin → CanCanCan raises `CanCan::AccessDenied` → 403
- [ ] Minitest: happy-path access (index, new, edit, show) and mutations (create, update, destroy)
- [ ] Minitest: unauthenticated access → redirect to sign-in
- [ ] Minitest: non-admin access → 403
- [ ] Minitest: missing params → unprocessable entity
- [ ] Minitest: unknown slug → 404 / redirect with flash
- [ ] Minitest: discard blocked when category has active children (verify via model; controller just surfaces the error)

---

## Implementation Checklist

- [ ] Add `resources :course_categories` to `config/routes.rb`
- [ ] Create `app/controllers/course_categories_controller.rb` with full CRUD
- [ ] Add `can :manage, CourseCategory` for admin in `app/models/ability.rb`
- [ ] Create views under `app/views/course_categories/`: `index`, `show`, `new`, `edit`, `_form`
- [ ] `index` — Ransack search form + Pagy table with Name, Depth, Position, Actions columns
- [ ] `_form` — name field + parent selector (collection of kept categories excluding self on edit) + position field
- [ ] `show` — display category details + list of direct children
- [ ] Use `friendly.find(params[:id])` in `set_course_category` (friendly_id resolves slugs)
- [ ] Soft delete: call `@course_category.discard` in `destroy`, not `destroy`
- [ ] Rescue `ActiveRecord::RecordNotFound` and `FriendlyId::SlugNotFound` in `set_course_category`
- [ ] Create `test/controllers/course_categories_controller_test.rb`
- [ ] Factory already exists at `test/factories/course_categories.rb` — reuse as-is

---

## Step-by-step Guide

**Files to create/modify:**

- `config/routes.rb` — add `resources :course_categories`
- `app/controllers/course_categories_controller.rb` — new file, full CRUD
- `app/models/ability.rb` — add `can :manage, CourseCategory` for admin role
- `app/views/course_categories/index.html.erb` — paginated table + search
- `app/views/course_categories/show.html.erb` — detail + children list
- `app/views/course_categories/new.html.erb` — wraps `_form`
- `app/views/course_categories/edit.html.erb` — wraps `_form`
- `app/views/course_categories/_form.html.erb` — shared form partial
- `test/controllers/course_categories_controller_test.rb` — new file

**Key decisions:**

- **Authorization:** CanCanCan `authorize_resource` in the controller. Admin can `:manage` CourseCategory. Any non-admin hitting a CRUD action raises `CanCan::AccessDenied`. Rescue it in `ApplicationController` (or rescue inline) and return 403.
- **Slug lookup:** `friendly_id` gem rewrites `.find` when you call `CourseCategory.friendly.find(params[:id])`. Routes still use `:id` param; Rails sends the slug string in params.
- **Soft delete:** Call `.discard` not `.destroy`. The model's `after_discard :discard_children` callback cascades to kept children automatically.
- **Discard error surfacing:** If `before_discard` eventually blocks (when Course model is added), the discard returns `false`. In the controller, check the return value and flash an error rather than redirecting with success.
- **Parent selector:** In `_form`, list `CourseCategory.kept` as parent options. On edit, exclude the category being edited and all its descendants to prevent creating invalid ancestry loops.
- **Index scope:** Show only kept categories (`CourseCategory.kept`). Discarded categories are hidden from the list.
- **Ransack scope:** Wrap `.kept` with ransack: `@q = CourseCategory.kept.ransack(params[:q])`. Never call `pagy(CourseCategory.all)` then filter.
- **Depth display:** Use `ancestry` gem's `.depth` method on each record for the indented tree display in the index table.

**Flow Diagram:**

```
Request → authenticate_user! ──(unauthenticated)──→ redirect /auth/sign_in
         ↓
         authorize_resource (CanCanCan)
         ──(non-admin)──→ CanCan::AccessDenied → 403
         ↓
GET  /course_categories
  → @q = CourseCategory.kept.ransack(params[:q])
  → @pagy, @categories = pagy(@q.result(distinct: true))
  → render index

GET  /course_categories/new
  → @course_category = CourseCategory.new → render new

POST /course_categories
  → CourseCategory.new(params)
      → save OK  → redirect show, flash :notice
      → save ERR → render new, status 422

GET  /course_categories/:slug       → set_course_category → render show
GET  /course_categories/:slug/edit  → set_course_category → render edit

PATCH /course_categories/:slug
  → set_course_category → update(params)
      → OK  → redirect show, flash :notice
      → ERR → render edit, status 422

DELETE /course_categories/:slug
  → set_course_category
  → @course_category.discard
      → OK    → redirect index, flash :notice
      → false → redirect show, flash :alert (blocked by guard)

set_course_category:
  CourseCategory.friendly.find(params[:id])
    ──(RecordNotFound | SlugNotFound)──→ redirect index, flash :alert
```

**Skeleton — controller:**

```ruby
# app/controllers/course_categories_controller.rb
class CourseCategoriesController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  before_action :set_course_category, only: %i[show edit update destroy]

  def index
    # @q = CourseCategory.kept.ransack(params[:q])
    # @pagy, @course_categories = pagy(@q.result(distinct: true))
  end

  def show
  end

  def new
    # @course_category = CourseCategory.new
  end

  def create
    # @course_category = CourseCategory.new(course_category_params)
    # save → redirect or render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    # @course_category.update(course_category_params) → redirect or render :edit, status: :unprocessable_entity
  end

  def destroy
    # if @course_category.discard → redirect index, notice
    # else → redirect show, alert (blocked by guard)
  end

  private

    def set_course_category
      # @course_category = CourseCategory.friendly.find(params[:id])
      # rescue ActiveRecord::RecordNotFound, FriendlyId::SlugNotFound
      #   redirect_to course_categories_path, alert: t("errors.not_found")
    end

    def course_category_params
      # params.require(:course_category).permit(:name, :parent_id, :position)
    end
end
```

**Skeleton — ability:**

```ruby
# app/models/ability.rb  (inside the admin block)
# can :manage, CourseCategory
```

**Skeleton — test:**

```ruby
# test/controllers/course_categories_controller_test.rb
class CourseCategoriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # @admin   = create(:user, :admin)
    # @student = create(:user)
    # @category = create(:course_category)
    # sign_in @admin
  end

  # --- Happy path: access ---
  test "admin can access index" do
  end

  test "admin can access new" do
  end

  test "admin can access show" do
  end

  test "admin can access edit" do
  end

  # --- Happy path: mutations ---
  test "admin can create a category" do
    # assert_difference "CourseCategory.count", 1 do
    #   post course_categories_url, params: { course_category: attributes_for(:course_category) }
    # end
  end

  test "admin can update a category" do
    # patch course_category_url(@category), params: { course_category: { name: "Updated" } }
    # assert_redirected_to course_category_url(@category.reload)
  end

  test "admin can discard a category" do
    # delete course_category_url(@category)
    # assert @category.reload.discarded?
    # assert_redirected_to course_categories_url
  end

  # --- Edge: unauthenticated ---
  test "index redirects when not signed in" do
    # sign_out @admin; get course_categories_url
    # assert_redirected_to new_user_session_path
  end

  # --- Edge: non-admin (403) ---
  test "student cannot access index" do
    # sign_in @student; get course_categories_url; assert_response :forbidden
  end

  test "student cannot create a category" do
    # sign_in @student; post course_categories_url, params: { ... }; assert_response :forbidden
  end

  # --- Edge: missing params ---
  test "create with blank name returns unprocessable entity" do
    # post course_categories_url, params: { course_category: { name: "" } }
    # assert_response :unprocessable_entity
  end

  test "update with blank name returns unprocessable entity" do
  end

  # --- Edge: record not found ---
  test "show with unknown slug redirects" do
    # get course_category_url("nonexistent-slug")
    # assert_redirected_to course_categories_url
  end
end
```

---

## Key Decisions

- **`load_and_authorize_resource` vs manual `authorize!`:** Use `load_and_authorize_resource` — it handles both `set_course_category` and the authorization check in one call. Remove the manual `before_action :set_course_category` if `load_and_authorize_resource` covers it; only keep the explicit setter if friendly_id lookup is needed (since `load_and_authorize_resource` uses `find(params[:id])` which friendly_id monkey-patches when called as `Model.find`). Verify whether plain `CourseCategory.find(params[:id])` resolves slugs — if it does, `load_and_authorize_resource` is sufficient. If not, keep the explicit `set_course_category` override.
- **Destroy vs discard:** Never call `.destroy`. Call `.discard`. The `Discard::Model` default scope (`.kept`) ensures discarded records disappear from all queries automatically.
- **Flash i18n:** Reuse generic controller keys: `t("controller.created", text: ...)`, `t("controller.updated", ...)`, `t("controller.destroyed", ...)`. Add a specific `t("course_categories.destroy.blocked")` key for the case when discard is blocked.
- **Parent selector on edit:** Exclude `@course_category` and `@course_category.subtree` from the parent dropdown options to prevent ancestry loops.

---

## Notes

- **`ancestry` gem tree helpers:** `.root?`, `.children`, `.siblings`, `.depth`, `.subtree`, `.descendants` are all available on any `CourseCategory` instance. Use `.depth` in the index table to visually indicate nesting level.
- **`friendly_id` locked slug:** `should_generate_new_friendly_id?` returns `false` once slug is set, so updating the name does NOT regenerate the slug. The URL stays stable after creation.
- **Discard cascade:** `after_discard :discard_children` on the model cascades to direct children, which recursively trigger their own `after_discard`. No extra logic needed in the controller.
- **CanCanCan 403 rescue:** Add `rescue_from CanCan::AccessDenied, with: :handle_access_denied` in `ApplicationController` if not already present. `handle_access_denied` should render a 403 status.
- **Ransack + kept scope:** Always chain ransack on `.kept` not on the raw model class: `CourseCategory.kept.ransack(params[:q])`. This ensures discarded categories never appear in search results.
