## **Status:**
- Review: Approved
- PR: Merged

## Metadata
- **Title:** User CRUD (Controller + Tests)
- **Phase:** 1 — MVP / User
- **GitHub Issue:** #6

---

## Description

Implement a `UsersController` providing full CRUD for user management (admin-style, separate from Devise registration). The controller lists all users, shows any user or the current user, creates/updates users with email uniqueness enforced by the model, and destroys a user. Includes Minitest coverage for happy paths and edge cases.

---

## Acceptance Criteria

- [ ] `GET /users` renders a paginated list of all users
- [ ] `GET /users/:id` renders a user's profile; `GET /users/me` redirects to the current user's show page
- [ ] `GET /users/new` renders a new-user form
- [ ] `POST /users` creates a user; re-renders form on duplicate email or missing params
- [ ] `GET /users/:id/edit` renders the edit form for a user
- [ ] `PATCH/PUT /users/:id` updates a user; re-renders form on duplicate email or missing params
- [ ] `DELETE /users/:id` sets user `status` to `:deleted` and redirects to index (no DB row removed)
- [ ] All actions return 302 redirect to sign-in for unauthenticated requests (Devise `authenticate_user!`)
- [ ] Minitest: happy-path access (index, new, edit) and mutations (create, update, destroy)
- [ ] Minitest: 401/redirect for unauthenticated access to every action
- [ ] Minitest: missing required params → unprocessable entity
- [ ] Minitest: unknown id → 404 / redirect with flash
- [ ] `DELETE /users/:id` where `:id` is `current_user` → redirects with alert, status unchanged

---

## Implementation Checklist

- [ ] Add `resources :users` + `get "users/me"` route to `config/routes.rb`
- [ ] Scaffold controller and views: `make gen-controller NAME=Users ACTIONS="index show new create edit update destroy"`
- [ ] Fill in `app/controllers/users_controller.rb` with all 7 CRUD actions (replaces scaffolded stubs)
- [ ] Add `before_action :authenticate_user!` to `UsersController`
- [ ] Add `before_action :set_user` for show / edit / update / destroy
- [ ] Create views: `index`, `show`, `new`, `edit`, `_form` under `app/views/users/`
- [ ] Use `pagy` + `ransack` in the `index` action (`@q = User.ransack(params[:q])`, then `pagy(@q.result)`)
- [ ] Add a search form in `index.html.erb` using ransack's `search_form_for`
- [ ] Reuse Devise email-uniqueness validation — no extra controller-level check needed
- [ ] Strip blank password params in `update` before calling `user.update`
- [ ] Create `test/controllers/users_controller_test.rb` with all test cases
- [ ] Factory already exists at `test/factories/users.rb` — reuse as-is

---

## Step-by-step Guide

**Files to create/modify:**

- `config/routes.rb` — add resource routes and `me` alias
- `app/controllers/users_controller.rb` — new file, full CRUD
- `app/views/users/index.html.erb` — paginated table
- `app/views/users/show.html.erb` — user profile card
- `app/views/users/new.html.erb` — wraps `_form`
- `app/views/users/edit.html.erb` — wraps `_form`
- `app/views/users/_form.html.erb` — shared form partial
- `test/controllers/users_controller_test.rb` — new file
- `test/factories/users.rb` — FactoryBot factory (may already exist)

**Key decisions:**

- **Authorization:** Any authenticated user may perform all actions — no role check. Enforced solely by `authenticate_user!`.
- **Destroy = logical delete:** `DELETE /users/:id` calls `user.status_deleted!` (enum bang method), not `destroy`. Row stays in DB. The `deleted` status already blocks sign-in via `active_for_authentication?`.
- **Index:** Use ransack + pagy together: `@q = User.ransack(params[:q]); @pagy, @users = pagy(@q.result(distinct: true))`. `Pagy::Backend` is already in `ApplicationController`; add `Pagy::Frontend` to `ApplicationHelper`.
- **Update password:** Permit `password`/`password_confirmation` in strong params, but strip them when blank before calling `update`. Prevents Devise from treating blank as a password change.
- **Email uniqueness:** Enforced by Devise `:validatable` — no extra model or controller validation needed.
- **`users/me` route:** Declare before `resources :users` in routes to avoid Rails treating `"me"` as an `:id`.
- **Strong params:** Permit `name`, `email`, `password`, `password_confirmation`, `status` — never `encrypted_password`.

**Flow:**

```
Request → authenticate_user! ──(not signed in)──→ redirect /users/sign_in

Authenticated:
  GET  /users           → @q = User.ransack(q_params)
                        → @pagy, @users = pagy(@q.result)
                        → render index (search form + paginated table)
  GET  /users/me        → redirect_to user_path(current_user)
  GET  /users/:id       → set_user → render show
  GET  /users/new       → @user = User.new → render new
  POST /users           → User.new(user_params)
                             → save OK  → redirect show, flash :notice
                             → save ERR → render new, status 422
  GET  /users/:id/edit  → set_user → render edit
  PATCH /users/:id      → set_user → strip blank passwords → update(params)
                             → OK  → redirect show, flash :notice
                             → ERR → render edit, status 422
  DELETE /users/:id     → set_user → user.status_deleted!
                        → redirect index, flash :notice

set_user:
  User.find(params[:id]) ──(RecordNotFound)──→ redirect index, flash :alert

Destroy (logical delete):
  active → status_deleted! → deleted   (blocks sign-in automatically)
```

**Non-obvious snippets:**

```ruby
# config/routes.rb
get "users/me", to: "users#me", as: :me   # before resources
resources :users

# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[show edit update destroy]

  def index
    # 1. @q = User.ransack(params[:q])
    # 2. @pagy, @users = pagy(@q.result(distinct: true))
  end

  def me
    # 1. redirect_to user_path(current_user)
  end

  def show
    # @user already set by set_user
  end

  def new
    # 1. assign @user = User.new
  end

  def create
    # 1. build @user = User.new(user_params)
    # 2. if @user.save → redirect_to @user, notice: t(".success")
    # 3. else → render :new, status: :unprocessable_entity
  end

  def edit
    # @user already set
  end

  def update
    # 1. strip blank password params: params = user_params.reject { |k, v| /password/.match?(k) && v.blank? }
    # 2. if @user.update(cleaned_params) → redirect_to @user, notice: t(".success")
    # 3. else → render :edit, status: :unprocessable_entity
  end

  def destroy
    # 1. if @user == current_user → redirect_to users_path, alert: t(".cannot_delete_self") and return
    # 2. @user.status_deleted!   (logical delete via enum bang method)
    # 3. redirect_to users_path, notice: t(".success")
  end

  private

  def set_user
    # 1. @user = User.find(params[:id])
    # 2. rescue ActiveRecord::RecordNotFound → redirect_to users_path, alert: t("errors.not_found")
  end

  def user_params
    # 1. params.require(:user).permit(:name, :email, :password, :password_confirmation, :status)
  end
end

# test/controllers/users_controller_test.rb
class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # 1. create(:user) as @user
    # 2. create(:user) as @other  (a second user for show/edit/destroy targets)
    # 3. sign_in @user
  end

  # --- Happy path: access ---
  test "can access index" do
  end

  test "can access new" do
  end

  test "can access edit" do
  end

  test "can access show for another user" do
  end

  test "me redirects to current user show" do
  end

  # --- Happy path: mutations ---
  test "can create a user" do
    # assert_difference "User.count", 1
  end

  test "can update a user" do
  end

  test "destroy sets user status to deleted" do
    # delete user_path(@other)
    # assert @other.reload.status_deleted?
    # assert_redirected_to users_path
  end

  test "cannot delete self" do
    # delete user_path(@user)
    # assert_redirected_to users_path
    # refute @user.reload.status_deleted?
  end

  # --- Edge: unauthenticated (401 / redirect) ---
  test "index redirects when not signed in" do
    # sign_out @user; get users_path; assert_redirected_to new_user_session_path
  end

  test "show redirects when not signed in" do
  end

  test "new redirects when not signed in" do
  end

  test "edit redirects when not signed in" do
  end

  test "create redirects when not signed in" do
  end

  test "update redirects when not signed in" do
  end

  test "destroy redirects when not signed in" do
  end

  # --- Edge: missing params ---
  test "create with missing email returns unprocessable entity" do
    # post users_path, params: { user: { name: "X" } }
    # assert_response :unprocessable_entity
  end

  test "update with blank email returns unprocessable entity" do
  end

  # --- Edge: record not found ---
  test "show with unknown id redirects" do
    # get user_path(id: 0)
    # assert_redirected_to users_path
  end

  test "update with unknown id redirects" do
  end

  test "destroy with unknown id redirects" do
  end

  # --- Edge: duplicate email ---
  test "create with duplicate email returns unprocessable entity" do
    # post users_path, params: { user: { email: @other.email, ... } }
    # assert_response :unprocessable_entity
  end

  test "update with duplicate email returns unprocessable entity" do
  end
end
```

---

## Key Decisions

- **Index scope:** Show ALL users regardless of status — active, inactive, suspended, deleted. No default scope filtering now. Ransack lets admins filter by status if needed.
- **Form helper:** Use `simple_form_for` in `_form.html.erb`. Gem is installed; less boilerplate, auto-generates labels and error wrappers.
- **Flash i18n — success messages:** Reuse existing generic keys: `t("controller.created", text: User.model_name.human)`, `t("controller.updated", ...)`, `t("controller.destroyed", ...)`. Do NOT use `t(".success")` relative keys.
- **Flash i18n — error messages:** `errors.not_found` and `users.destroy.cannot_delete_self` do not exist yet — add them to `config/locales/en.yml`.
- **Logical delete vs discard gem:** `status_deleted!` is the correct mechanism for User. The `discard` gem is for future models that lack a status field. User already gates auth on `status_active?`, so the enum IS the soft-delete.
- **`Pagy::Frontend`:** Already present in `ApplicationHelper` — no action needed.
- **`Pagy::Backend`:** Already present in `ApplicationController` — no action needed.

---

## Notes

- **Destroy is logical, not physical:** `status_deleted!` keeps the row in DB. `User.count` does NOT change on destroy — tests must assert `user.reload.status_deleted?`, not `assert_difference "User.count", -1`.
- **`deleted` status blocks sign-in automatically** — `active_for_authentication?` already returns `false` for any non-active status, so no extra guard needed after logical delete.
- **Password stripping on update:** Use `reject { |k, v| /password/.match?(k) && v.blank? }` on the permitted params hash before calling `update`. Do not call `update_without_password` — that strips status/email edits too.
- **ransack + pagy order:** Call `ransack` first, then `pagy(@q.result)`. Never call `pagy(User.all)` and then filter — ransack must wrap the base scope.
- **cancancan not installed:** `cancancan` is missing from the Gemfile. Once added, `load_and_authorize_resource` will replace `before_action :set_user` entirely. For now, keep `set_user` inline — do not extract it to a concern since cancancan will own it later.
- **Index scope (deferred):** `GET /users` currently shows ALL users regardless of status (active, inactive, suspended, deleted). Once cancancan + roles are added, non-active users (inactive, suspended, deleted) should be hidden from lower-privilege actors or filtered by default scope based on role. Do not add this filtering now — keep the scope open until authorization is in place.
