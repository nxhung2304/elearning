****## **Status:**
- Review: Approved
- PR: Merged

## Metadata
- **Title:** Model: Role + UserRole — associations, i18n (en)
- **Phase:** 1 - MVP
- **GitHub Issue:** #9

---

## Description
Create `roles` and `user_roles` tables with their models, validations, and associations. Wire up the `User ↔ Role` many-to-many via `UserRole`. Add English i18n keys for both models. This is a prerequisite for CanCanCan setup (issue #3).

---

## Acceptance Criteria
- [ ] Migration creates `roles` table: `name:string not null`, `code:string not null unique`
- [ ] Migration creates `user_roles` table: `user_id FK not null`, `role_id FK not null`, unique index on `[user_id, role_id]`
- [ ] `Role` model: validates `name` and `code` presence; validates `code` inclusion in `%w[student teacher admin]`; validates `code` uniqueness
- [ ] `UserRole` model: validates `user_id` and `role_id` presence; validates uniqueness of `user_id` scoped to `role_id`
- [ ] `User` model updated: `has_many :user_roles`, `has_many :roles, through: :user_roles`
- [ ] `Role` model: `has_many :user_roles`, `has_many :users, through: :user_roles`
- [ ] `config/locales/models/en.yml` updated with Role and UserRole keys
- [ ] Factories: `:role` (student/teacher/admin traits), `:user_role`
- [ ] Minitest: user gets correct role via join table (happy)
- [ ] Minitest: duplicate UserRole is invalid (edge)
- [ ] Minitest: Role code outside whitelist is invalid (edge)
- [ ] All tests pass: `bin/rails test test/models/role_test.rb test/models/user_role_test.rb`
- [ ] RuboCop passes: `bin/rubocop app/models/role.rb app/models/user_role.rb`

---

## Implementation Checklist
- [x] Generate migration for `roles`: `make gen-model NAME=Role FIELDS="name:string code:string"` ✅ 2026-05-17
- [x] Generate migration for `user_roles`: `make gen-model NAME=UserRole FIELDS="user:references role:references"` ✅ 2026-05-17
- [x] Edit roles migration: add `null: false` on `name` and `code`; add `unique: true` index on `code` ✅ 2026-05-17
- [x] Edit user_roles migration: add `null: false` on both FKs; replace default index with a unique composite index on `[user_id, role_id]`; remove `t.timestamps` (join table) ✅ 2026-05-17
- [x] Run `bin/rails db:migrate` ✅ 2026-05-17
- [x] Write `app/models/role.rb` — associations + validations + annotate comment (auto by annotaterb after migrate) ✅ 2026-05-17
- [x] Write `app/models/user_role.rb` — associations + validations ✅ 2026-05-17
- [ ] Update `app/models/user.rb` — add `has_many :user_roles` and `has_many :roles, through: :user_roles`
- [x] Update `config/locales/models/en.yml` — add Role and UserRole keys ✅ 2026-05-17
- [ ] Create `test/factories/roles.rb` — default + `:student`, `:teacher`, `:admin` traits
- [ ] Create `test/factories/user_roles.rb`
- [ ] Write `test/models/role_test.rb`
- [ ] Write `test/models/user_role_test.rb`
- [ ] Run `bin/rails test test/models/role_test.rb test/models/user_role_test.rb`
- [ ] Run `bin/rubocop app/models/role.rb app/models/user_role.rb test/models/role_test.rb test/models/user_role_test.rb`

---

## Step-by-step Guide

**Files to create/modify:**
- `db/migrate/TIMESTAMP_create_roles.rb` — roles table with constraints
- `db/migrate/TIMESTAMP_create_user_roles.rb` — join table with unique composite index
- `app/models/role.rb` — validations, associations
- `app/models/user_role.rb` — validations, associations
- `app/models/user.rb` — add has_many associations (roles, user_roles)
- `config/locales/models/en.yml` — add Role and UserRole i18n keys
- `test/factories/roles.rb` — factory with traits
- `test/factories/user_roles.rb` — factory
- `test/models/role_test.rb` — model tests
- `test/models/user_role_test.rb` — model tests

**Key decisions:**
- `code` is the machine-readable identifier used by CanCanCan ability checks — validate inclusion in whitelist `%w[student teacher admin]` at the model layer, not just with a DB check constraint
- `UserRole` join table has NO `id` primary key is tempting but Rails' `belongs_to` + FactoryBot work more cleanly with an `id` — keep `id` for now
- No `timestamps` on `user_roles` — it's a pure join table; `created_at` is not needed
- Do NOT include `Discard::Model` on either `Role` or `UserRole` — roles are reference data, not soft-deleted records (per ERD)
- Uniqueness validated at model layer (`validates :user_id, uniqueness: { scope: :role_id }`) AND enforced by DB unique index — both layers needed
- `User` model already has Devise and status; only append the two new `has_many` lines to avoid touching existing logic

**Flow:**
```
Data relationship (many-to-many via join table):

  users ──< user_roles >── roles
    id         user_id       id
               role_id       name
                             code (student|teacher|admin)

Write path (assigning a role to a user):
  UserRole.create!(user: user, role: role)
       │
       ▼
  model validates presence + uniqueness scope
       │
       ▼
  DB unique index on [user_id, role_id] catches race condition
       │
       ├── valid  ──► record saved
       └── invalid ──► ActiveRecord::RecordInvalid

Query path (check user's role):
  user.roles.exists?(code: "admin")
  user.roles.map(&:code)  #=> ["student", "teacher"]
```

**Non-obvious snippets:**
```ruby
# db/migrate/TIMESTAMP_create_roles.rb
def change
  create_table :roles do |t|
    # 1. name: string, null: false
    # 2. code: string, null: false
    # 3. timestamps
  end
  # 4. add_index :roles, :code, unique: true
end

# db/migrate/TIMESTAMP_create_user_roles.rb
def change
  create_table :user_roles do |t|
    # 1. t.references :user, null: false, foreign_key: true, index: false
    # 2. t.references :role, null: false, foreign_key: true, index: false
    # (no timestamps)
  end
  # 3. add_index :user_roles, [:user_id, :role_id], unique: true
end

# app/models/role.rb
class Role < ApplicationRecord
  CODES = %w[student teacher admin].freeze

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  # 1. validates name presence
  # 2. validates code presence, uniqueness, inclusion in CODES
end

# app/models/user_role.rb
class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role

  # 1. validates user_id presence
  # 2. validates user_id uniqueness scoped to role_id
end

# app/models/user.rb (append only — do not touch existing Devise/status code)
  # 1. has_many :user_roles, dependent: :destroy
  # 2. has_many :roles, through: :user_roles

# config/locales/models/en.yml — add under activerecord:
#   models:
#     role: "Role"
#     user_role: "User Role"
#   attributes:
#     role:
#       name: "Name"
#       code: "Code"
#     user_role:
#       user_id: "User"
#       role_id: "Role"

# test/factories/roles.rb
FactoryBot.define do
  factory :role do
    # 1. name: "Student" (sequence or static)
    # 2. code: "student"

    trait :student do
      # code: "student", name: "Student"
    end

    trait :teacher do
      # code: "teacher", name: "Teacher"
    end

    trait :admin do
      # code: "admin", name: "Admin"
    end
  end
end

# test/factories/user_roles.rb
FactoryBot.define do
  factory :user_role do
    # 1. association :user
    # 2. association :role
  end
end

# test/models/role_test.rb
class RoleTest < ActiveSupport::TestCase
  test "valid with name and code" do
  end

  test "invalid without name" do
  end

  test "invalid without code" do
  end

  test "invalid when code is not in whitelist" do
  end

  test "invalid when code is duplicate" do
  end

  test "user can be assigned a role through user_roles" do
  end
end

# test/models/user_role_test.rb
class UserRoleTest < ActiveSupport::TestCase
  test "valid with user and role" do
  end

  test "invalid when duplicate user_role" do
  end

  test "invalid without user_id" do
  end

  test "invalid without role_id" do
  end
end
```

---

## Notes
- CanCanCan (issue #3) depends on this issue — complete and merge this first before setting up `Ability`
- `Role::CODES` constant is the single source of truth for valid codes; CanCanCan's `Ability` class will call `user.roles.exists?(code: "admin")` — do not change code values without updating Ability
- `dependent: :destroy` on `Role#has_many :user_roles` ensures no orphan join rows if a Role is ever deleted (unlikely in production but safe for tests)
