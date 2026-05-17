## **Status:**
- Review: Approved
- PR: Merged

## Metadata
- **Title:** Setup: CanCanCan + Ability class
- **Phase:** 1 — MVP (Web), Week 1-2: Setup + Auth
- **GitHub Issue:** #12

---

## Description

Wire up CanCanCan authorization by generating the `Ability` class and defining role-based permissions for admin, teacher, and student. The `cancancan` gem is already in the Gemfile (added in issue #3). This task creates the `app/abilities/ability.rb` file, adds role-helper methods to `User`, and registers a global `AccessDenied` rescue handler in `ApplicationController`.

---

## Acceptance Criteria
- [ ] `app/abilities/ability.rb` exists and defines abilities for all three roles
- [ ] `User` model exposes `has_role?`, `admin?`, `teacher?`, `student?` helpers
- [ ] `ApplicationController` rescues `CanCan::AccessDenied` and renders 403
- [ ] No existing controller tests are broken
- [ ] Minitest: Ability tests cover happy path and deny path for each role

---

## Implementation Checklist
- [x] Run `rails g cancan:ability` to generate `app/abilities/ability.rb` ✅ 2026-05-17
- [x] Define abilities per role in `ability.rb` ✅ 2026-05-17
- [x] Add `has_role?` + role-predicate helpers to `User` model ✅ 2026-05-17
- [x] Add `rescue_from CanCan::AccessDenied` in `ApplicationController` ✅ 2026-05-17
- [x] Write `test/models/ability_test.rb` — happy + deny cases per role ✅ 2026-05-17
- [x] Run `bin/rails test test/models/ability_test.rb` — all green ✅ 2026-05-17
- [x] Run `make lint` — no RuboCop offenses ✅ 2026-05-17


---

## Step-by-step Guide

**Files to create/modify:**
- `app/abilities/ability.rb` — create (via generator, then fill body)
- `app/models/user.rb` — add `has_role?` + predicate helpers
- `app/controllers/application_controller.rb` — add `rescue_from`
- `test/models/ability_test.rb` — create

**Key decisions:**
- Role check is done via the join table (`user.roles.exists?(code: "admin")`), not a column on users — keeps roles flexible.
- Add a memoized `has_role?` helper on `User` instead of querying inside `Ability` inline, so it's easy to stub in tests.
- Do NOT add `load_and_authorize_resource` globally in `ApplicationController` — controllers call it individually as models are built. This issue only sets up the Ability class + error handler.
- Return 403 JSON for API requests and redirect with flash for HTML — check `request.format.json?` in the rescue block.

**Flow:**
```
Request
  └─► ApplicationController before_action :authenticate_user!
            │
            ▼
      Controller action
            │
            ├─► authorize! :action, resource     (called per-controller)
            │         │
            │    CanCan::AccessDenied?
            │         │ yes
            │         ▼
            │   rescue_from handler
            │         ├─► HTML → redirect_to root, alert: "Access denied"
            │         └─► JSON → render json: {error: "Forbidden"}, status: 403
            │
            └─► Ability#initialize(user)
                      │
                      ├─► user.admin?   → can :manage, :all
                      ├─► user.teacher? → can :manage, Course, teacher_id: user.id
                      │                   can :manage, Section (via course)
                      │                   can :manage, Lesson  (via section)
                      └─► user.student? → can :read, Course (published only, Phase 1 stub)
                                          can :manage, Profile, user_id: user.id
```

**Non-obvious snippets:**

```ruby
# app/models/user.rb — add after existing associations

def has_role?(code)
  # 1. Query roles join table for matching code string
  # 2. Memoize with @role_codes ||= roles.pluck(:code)
end

def admin?
  # delegate to has_role?("admin")
end

def teacher?
  # delegate to has_role?("teacher")
end

def student?
  # delegate to has_role?("student")
end
```

```ruby
# app/abilities/ability.rb

class Ability
  include CanCan::Ability

  def initialize(user)
    # 1. Return (no permissions) if user is nil or not active
    # 2. Branch on user.admin? → can :manage, :all
    # 3. Branch on user.teacher? → define teacher permissions (stub: manage own Course once Course exists)
    # 4. Branch on user.student? → define student permissions (stub: read Course)
    # 5. Any authenticated user: can :read, :dashboard (placeholder)
  end
end
```

```ruby
# app/controllers/application_controller.rb — add inside class body

rescue_from CanCan::AccessDenied do |exception|
  # 1. If request.format.json? → render json error 403
  # 2. Otherwise → redirect_to root_path, alert: exception.message
end
```

```ruby
# test/models/ability_test.rb

class AbilityTest < ActiveSupport::TestCase
  # Admin abilities
  test "admin can manage all" do
    # create(:user) with admin role, build Ability, assert can?(:manage, :all)
  end

  test "non-admin cannot manage users" do
    # create(:user) with student role, assert cannot?(:manage, User)
  end

  # Teacher abilities
  test "teacher can manage own course" do
  end

  test "teacher cannot manage another teacher course" do
  end

  # Student abilities
  test "student can read published course" do
  end

  test "student cannot manage course" do
  end

  # Profile abilities
  test "student can manage own profile" do
  end

  test "student cannot manage another user profile" do
  end

  # Suspended / inactive user
  test "suspended user has no abilities" do
    # create(:user, status: :suspended), Ability.new(user), assert cannot?(:read, :dashboard)
  end
end
```

---

## Notes
- `cancancan` is already installed — skip gem/bundle step. Just run the generator.
- Teacher and Student abilities reference models (`Course`, `Profile`) that don't exist yet — stub them with `can :manage, Course` inside a guard `if defined?(Course)` or simply leave a comment `# Phase 1: Course abilities defined in issue #X`. The ability class must not raise `NameError` on boot.
- Memoize `has_role?` with an instance variable to avoid N+1 in views/controllers that check multiple roles in the same request.
