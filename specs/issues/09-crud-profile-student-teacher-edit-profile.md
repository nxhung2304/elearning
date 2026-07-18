## **Status:**
- Review: Approved
- PR: Merged ✅ 2026-05-30

## Metadata
- **Title:** [CRUD] Profile — Student/Teacher tự edit profile
- **Phase:** 1 - MVP (Week 1-2 | Setup + Auth)
- **GitHub Issue:** #20

---

## Description
Add `ProfilesController` with `edit` and `update` actions so that Student and Teacher can update their own profile (full_name, bio, phone, avatar). Access is gated by CanCanCan — a user can only modify their own profile. Profiles are auto-created on first edit if they don't yet exist (via `current_user.build_profile`).

---

## Acceptance Criteria
- [x] `GET /profile/edit` renders an edit form pre-filled with the current user's profile fields
- [x] `PATCH /profile` updates full_name, bio, phone successfully and redirects with a flash notice
- [x] Active Storage avatar upload works via the form (optional — no error if blank; replaces existing attachment if one is present)
- [x] CanCanCan ability rule `can :update, Profile, user_id: user.id` is defined in `app/abilities/ability.rb` for student and teacher roles
- [x] Profile is auto-created (build_profile) if the current user doesn't have one yet
- [x] i18n flash messages use existing `controller.updated` key
- [x] `full_name` field has `required: true` in the form
- [x] Minitest controller: student updates their own profile
- [x] Minitest controller: teacher updates their own profile
- [x] Minitest controller: `set_profile` always resolves to `current_user`'s profile (never another user's)
- [x] Minitest ability: `Ability.new(student).can?(:update, other_profile)` → false

---

## Implementation Checklist
- [x] Add singular resource route: `resource :profile, only: %i[edit update]` in `config/routes.rb`
- [x] Add CanCanCan ability in `app/abilities/ability.rb`: `can :update, Profile, user_id: user.id` for student and teacher roles
- [x] Create `app/controllers/profiles_controller.rb` with `edit` and `update` actions
- [x] Add `authorize_resource` (class-level, authorize-only) in the controller — do NOT use `load_and_authorize_resource`
- [x] Handle profile auto-creation: use `current_user.profile || current_user.build_profile`
- [x] Create `app/views/profiles/edit.html.erb` with a form for full_name, bio, phone, avatar
- [x] Create `test/controllers/profiles_controller_test.rb` (happy: student update, teacher update; scope: set_profile always uses current_user)
- [x] Add ability tests to existing `test/models/ability_test.rb`: student/teacher cannot update another user's profile
- [x] Run `bin/rails test test/controllers/profiles_controller_test.rb test/models/ability_test.rb`
- [x] Run `bin/rubocop app/controllers/profiles_controller.rb app/views/profiles/edit.html.erb`

---

## Step-by-step Guide

**Files to create/modify:**
- `config/routes.rb` — add `resource :profile, only: %i[edit update]`
- `app/abilities/ability.rb` — add Profile update ability for student/teacher
- `app/controllers/profiles_controller.rb` — edit + update actions
- `app/views/profiles/edit.html.erb` — edit form
- `test/controllers/profiles_controller_test.rb` — happy path + set_profile scope verification
- `test/models/ability_test.rb` — cross-user profile update blocked by CanCanCan rule

**Key decisions:**
- Use **singular resource** (`resource :profile`) — a user has exactly one profile; routes become `/profile/edit` and `PATCH /profile` (no `:id` in URL)
- Use `current_user.profile || current_user.build_profile` rather than `Profile.find` — prevents exposure of other users' profile IDs and auto-creates on first visit
- Use `authorize_resource` (not `load_and_authorize_resource`) at the class level — `load_and_authorize_resource` calls `Profile.find(params[:id])` which fails for singular resource (no `:id` in URL); `authorize_resource` skips the load step and just authorizes `@profile` that was already set by `before_action :set_profile`
- Avatar uses only `has_one_attached :avatar` (Active Storage) — `avatar_url` string column has been removed from the model; permit `:avatar` in params; display with `profile.avatar` and guard with `profile.avatar.attached?` in views
- Do NOT expose admin-only fields (user_id, discarded_at, status) in `profile_params`
- **403 test placement:** singular resource makes controller-level 403 unreachable via normal routes; split coverage — controller test verifies `set_profile` scopes to `current_user`, ability unit test verifies `can?(:update, other_profile)` returns `false`

**Flow:**
```
Student/Teacher → GET /profile/edit
                       │
                       ▼
              ProfilesController#edit
                       │
                  before_action: set_profile
                  (current_user.profile || build_profile)
                       │
                       ▼
               authorize_resource (class-level)
               checks can?(:update, @profile)
                       │
               ├── NO ──► CanCan::AccessDenied → 403
               │
               └── YES ──► render edit form

POST / PATCH /profile
                       │
                       ▼
              ProfilesController#update
                       │
              @profile.update(profile_params)
                       │
               ├── valid? ──NO──► render :edit (422)
               │
               └── YES ──► redirect_to edit_profile_path, flash[:success]
```

**Non-obvious snippets:**
```ruby
# config/routes.rb
Rails.application.routes.draw do
  # 1. Add inside the draw block (after devise_for):
  resource :profile, only: %i[edit update]
end

# app/abilities/ability.rb
class Ability
  include CanCan::Ability

  def initialize(user)
    # 1. Keep existing admin/teacher/student blocks
    # 2. Inside student AND teacher role blocks, add:
    #    can :update, Profile, user_id: user.id
  end
end

# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  before_action :set_profile
  authorize_resource  # authorize-only; @profile already loaded by set_profile

  def edit
  end

  def update
    # 1. if @profile.update(profile_params)
    #      flash[:success] = t("controller.updated", text: Profile.model_name.human)
    #      redirect_to edit_profile_path
    #    else
    #      render :edit, status: :unprocessable_entity
    #    end
  end

  private

    def set_profile
      # 1. @profile = current_user.profile || current_user.build_profile
    end

    def profile_params
      # 1. params.require(:profile).permit(:full_name, :bio, :phone, :avatar)
    end
end

# app/views/profiles/edit.html.erb
# 1. form_with model: @profile, url: profile_path do |f|
# 2. f.text_field :full_name
# 3. f.text_area :bio
# 4. f.text_field :phone
# 5. f.file_field :avatar  ← only if not already attached, or always show to replace
# 6. f.submit

# test/controllers/profiles_controller_test.rb
class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    # 1. @student_profile = create(:profile)  ← auto-creates student user
    # 2. @teacher_profile = create(:profile, user: create(:user, :teacher))
    # 3. sign_in @student_profile.user
  end

  test "student can access edit profile page" do
    # get edit_profile_path
    # assert_response :success
  end

  test "student can update their own profile" do
    # patch profile_path, params: { profile: { full_name: "New Name", bio: "Hello" } }
    # assert_redirected_to edit_profile_path
    # assert_equal "New Name", @student_profile.reload.full_name
  end

  test "teacher can update their own profile" do
    # sign_in @teacher_profile.user
    # patch profile_path, params: { profile: { full_name: "Teacher Name" } }
    # assert_redirected_to edit_profile_path
  end

  test "set_profile always resolves to current user profile" do
    # get edit_profile_path
    # assert_equal @student_profile, assigns(:profile)
    # (proves the controller never exposes another user's profile via this route)
  end
end

# test/models/ability_test.rb  (add to existing file if present)
class AbilityTest < ActiveSupport::TestCase
  test "student cannot update another user's profile" do
    # student = create(:user, :student)
    # other_profile = create(:profile)  ← belongs to a different user
    # ability = Ability.new(student)
    # assert_not ability.can?(:update, other_profile)
  end

  test "teacher cannot update another user's profile" do
    # teacher = create(:user, :teacher)
    # other_profile = create(:profile)
    # ability = Ability.new(teacher)
    # assert_not ability.can?(:update, other_profile)
  end
end
```

---

## Notes
- Depends on issue #7 ([Model] Profile) — migration and model must be merged first
- The `resource :profile` singular route means there is no `:id` param; `set_profile` always resolves via `current_user` — this is the authorization boundary
- Admin profile management (if ever needed) is a separate concern; this issue is strictly self-service edit for student/teacher
- **First-time create vs update:** treated as the same flow — `update` action handles both (Active Record's `update` on an unsaved record calls `save`); flash always uses `t("controller.updated", ...)` regardless; no special-case branching needed
- `avatar_url` column removed (issue #7 spec is stale on this — ignore references to `avatar_url` there); Active Storage `has_one_attached :avatar` is the only avatar mechanism; display with `image_tag profile.avatar` guarded by `profile.avatar.attached?`
- **`full_name` required in UI:** add `required: true` to the `full_name` field in the form for immediate browser feedback; server-side `validates :full_name, presence: true` remains the authoritative safety net
