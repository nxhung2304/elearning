## **Status:**
- Review: Approved
- PR
    - Link: https://github.com/nxhung2304/elearning/pull/4
    - Status: Merged

## Metadata
- **Title:** User Model — status column & validations
- **Phase:** 1 - MVP
- **GitHub Issue:** #3

---

## Description
Add `status` column to the `users` table as an integer enum (NOT NULL, default 1/active). Define enum values and model validations. Override Devise's `active_for_authentication?` so only `active` users can sign in. Cover the model and auth gate with Minitest.

---

## Acceptance Criteria
- [ ] Migration adds `status: integer, null: false, default: 1` with an index
- [ ] Model defines enum: `inactive(0), active(1), suspended(2), deleted(3)` with `prefix: true`
- [ ] `validates :status, presence: true` in the model
- [ ] `active_for_authentication?` returns true only for `status_active?` users
- [ ] Factory default is `status: :active`; traits `:inactive`, `:suspended`, `:deleted` override status
- [ ] Minitest: `build(:user, status: nil).valid?` → false
- [ ] Minitest: all four enum values can be set and read back
- [ ] Minitest: `active_for_authentication?` returns false for inactive/suspended/deleted

---

## Implementation Checklist
- [ ] Fix existing migration `db/migrate/20260516063235_add_status_to_users.rb` in place: correct `t.add_column` → `add_column`, add index
- [ ] Run `bin/rails db:migrate`
- [ ] Add `enum` + `validates` + `active_for_authentication?` + `inactive_message` to `User` model
- [ ] Update `test/factories/users.rb` — add `status: :active` default and `:inactive`, `:suspended`, `:deleted` traits
- [ ] Write tests in `test/models/user_test.rb` (use shoulda-matchers for enum test)
- [ ] Run `bin/rails test test/models/user_test.rb`
- [ ] Run `bin/rubocop app/models/user.rb test/models/user_test.rb`

---

## Step-by-step Guide

**Files to create/modify:**
- `db/migrate/TIMESTAMP_add_status_to_users.rb` — add status column + index
- `app/models/user.rb` — enum, validation, Devise auth gate
- `test/factories/users.rb` — status default + active trait
- `test/models/user_test.rb` — enum, null, and auth gate tests

**Key decisions:**
- Integer enum (not string) — DB default is `1` (active) so new registrations are immediately usable; `inactive`, `suspended`, `deleted` are admin-imposed states
- `prefix: true` on the enum — generates `status_active?`, `status_inactive?` etc., avoids collision with Devise's own `active?` method
- Validate presence at the model layer in addition to the DB NOT NULL constraint — catches `nil` before the query hits the DB
- `active_for_authentication?` lives on the model, not a controller `before_action` — keeps auth logic in one place and works with all Devise flows (session, token, etc.)
- Factory default is `active` — mirrors the DB default; use `trait :inactive` / `trait :suspended` / `trait :deleted` explicitly where auth blocking needs to be tested
- **Migration**: fix the existing untracked file `20260516063235_add_status_to_users.rb` in place (has `t.add_column` bug and missing index) — do not regenerate
- **Enum test**: use shoulda-matchers `define_enum_for` matcher — covers values, prefix, and type in one assertion; no manual loop needed
- **Devise modules in use**: `database_authenticatable, registerable, recoverable, rememberable, validatable` — no `confirmable` or `lockable`, so `active_for_authentication?` override has no conflicts

**Flow:**
```
Status transitions (admin-driven after registration):
  [register] ──► active(1)
                    │
          ┌─────────┴──────────┐
          ▼                    ▼
     inactive(0)          suspended(2)
                               │
                               ▼
                          deleted(3)  ← terminal

Devise sign-in gate:
  User submits credentials
       │
       ▼
  Devise validates password
       │
       ▼
  active_for_authentication?
       ├── status_active? == true  ──► sign in, redirect to root
       └── status_active? == false ──► reject, flash :not_active
```

**Non-obvious snippets:**
```ruby
# db/migrate/TIMESTAMP_add_status_to_users.rb
def change
  # 1. Add status column: integer, not null, default 1
  # 2. Add index on status
end

# app/models/user.rb

# 1. Declare integer enum with prefix to avoid Devise method collisions
# 2. Validate presence of status

# 3. Override Devise: allow sign-in only when status is active
def active_for_authentication?
  # call super, then check status
end

# 4. Return :not_active — Devise uses this symbol to render the blocked sign-in flash message
def inactive_message
  # always return :not_active (this method is only called when active_for_authentication? is false)
end

# test/factories/users.rb
factory :user do
  # existing fields ...
  # 1. Set status default to :active (so tests can sign in without extra setup)

  # 2. trait :inactive → status: :inactive
  trait :inactive do
  end

  # 3. trait :suspended → status: :suspended
  trait :suspended do
  end

  # 4. trait :deleted → status: :deleted
  trait :deleted do
  end
end

# test/models/user_test.rb
# 1. nil status → invalid
test "invalid when status is nil" do
end

# 2. each enum value can be set and read back
test "all enum values are valid" do
end

# 3-6. active_for_authentication? per status
test "active_for_authentication? is true when active" do
end

test "active_for_authentication? is false when inactive" do
end

test "active_for_authentication? is false when suspended" do
end

test "active_for_authentication? is false when deleted" do
end
```

---

## Notes
- `discard` gem is in the Gemfile — `status: :deleted` and `discard` serve different purposes for now; keep them separate (discard may be used for hard-soft-delete on other models)
- Existing `user_test.rb` tests use `build(:user)` with no status — they still pass because factory default `active` mirrors the DB default now
- Enum test uses shoulda-matchers: `should define_enum_for(:status).with_values(inactive: 0, active: 1, suspended: 2, deleted: 3).with_prefix(:status)`
- The existing migration file at `db/migrate/20260516063235_add_status_to_users.rb` had two bugs before being fixed: `t.add_column` (invalid in `def change`) and a missing index on `status`
