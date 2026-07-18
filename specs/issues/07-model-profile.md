## **Status:**
- Review: Approved
- PR: Merged ✅ 2026-05-29

## Metadata
- **Title:** [Model] Profile — validations, associations, i18n (en)
- **Phase:** 1 - MVP (Week 1-2 | Setup + Auth)
- **GitHub Issue:** #16

---

## Description
Create the `Profile` model with a 1-1 association to `User`. Profiles store display information (full_name, avatar_url, bio, phone) and support soft delete via Discard. Include i18n attribute labels in `config/locales/models/en.yml`. Cover the model with Minitest.

---

## Acceptance Criteria
- [x] Migration creates `profiles` table with correct columns, unique index on `user_id`, and `NOT NULL` constraint on `full_name`
- [x] `Profile` model includes `Discard::Model` for soft delete
- [x] `belongs_to :user` (not null) and `User has_one :profile` association are defined
- [x] `validates :user_id, uniqueness: true` enforces the 1-1 constraint at the model layer
- [x] ActiveStorage `has_one_attached :avatar` declared on the model
- [x] `avatar_url` column stores a plain string fallback (no Active Storage dependency required by callers)
- [x] i18n keys added under `en.activerecord.attributes.profile.*` in `config/locales/models/en.yml`
- [x] Factory `create(:profile)` works without arguments (auto-creates user via association)
- [x] Minitest: profile with valid attributes is valid
- [x] Minitest: profile without user_id → invalid
- [x] Minitest: duplicate profile for same user → invalid
- [x] Minitest: `discarded_at` scoping — discarded profile is excluded from `.kept`

---

## Implementation Checklist
- [x] Generate migration: `make gen-model NAME=Profile FIELDS="user_id:references:uniq full_name:string avatar_url:string bio:text phone:string discarded_at:datetime"`
- [x] Review and fix migration: add `null: false` on `user_id` and `full_name`, ensure unique index `index_profiles_on_user_id`
- [x] Run `bin/rails db:migrate`
- [x] Add `include Discard::Model` to `app/models/profile.rb`
- [x] Add `belongs_to :user` and `has_one_attached :avatar` to `Profile`
- [x] Add `has_one :profile` (with `dependent: :destroy` — hard delete when user is destroyed) to `User`
- [x] Add `validates :user_id, uniqueness: true` to `Profile`
- [x] Add i18n keys in `config/locales/models/en.yml` under `activerecord.attributes.profile`
- [x] Create `test/factories/profiles.rb`
- [x] Write `test/models/profile_test.rb`
- [x] Run `bin/rails test test/models/profile_test.rb`
- [x] Run `bin/rubocop app/models/profile.rb test/models/profile_test.rb test/factories/profiles.rb`

---

## Step-by-step Guide

**Files to create/modify:**
- `db/migrate/TIMESTAMP_create_profiles.rb` — profiles table with FK + unique index + discarded_at
- `app/models/profile.rb` — Discard, belongs_to, has_one_attached, validations
- `app/models/user.rb` — add `has_one :profile`
- `config/locales/models/en.yml` — i18n attribute labels for Profile
- `test/factories/profiles.rb` — factory with user association
- `test/models/profile_test.rb` — model validations and discard scope tests

**Key decisions:**
- `user_id` NOT NULL + unique index enforced at both DB and model layer — DB constraint prevents race conditions; `validates :user_id, uniqueness: true` surfaces a friendly error before the query
- Use `has_one_attached :avatar` (Active Storage) — `avatar_url` string column is a plain fallback/cache; do not remove it; callers that just need a URL string use `avatar_url`, callers that need full AS features use `profile.avatar`
- Include `Discard::Model` — do NOT use `dependent: :destroy` on `has_many` side; `User` → `has_one :profile` uses regular `dependent: :destroy` since destroying a user is an admin action that should hard-delete the profile
- No `discarded_at` default scope conflict: Profile's soft delete is independent of User's `status` enum — a profile can be discarded while its user is still active
- Do not add Ransack search or Pagy here — those belong in the `[CRUD] Profile` issue (#8)

**Flow:**
```
Data relationship:
  User (1) ──has_one──► Profile (1)
   │                       │
   │  user_id FK (uniq)    │
   └───────────────────────┘

Write path (model layer):
  params[:profile] arrives at controller
       │
       ▼
  profile = current_user.build_profile(params)  ← or find existing
       │
       ├── user_id present? ──NO──► invalid, :blank error
       │
       ├── user_id unique? ───NO──► invalid, :taken error
       │
       └── YES ──► profile.save ──► DB insert
                       │
                       ▼
                  profiles table
                  (discarded_at NULL = kept)

Soft delete:
  profile.discard  ──► sets discarded_at = Time.current
  Profile.kept     ──► excludes discarded records (default scope)
  Profile.discarded ──► shows only soft-deleted
```

**Non-obvious snippets:**
```ruby
# db/migrate/TIMESTAMP_create_profiles.rb
def change
  create_table :profiles do |t|
    # 1. Add user_id: references, null: false, foreign_key: true, index: false (add unique index below)
    # 2. Add full_name: string, null: false
    # 3. Add avatar_url: string
    # 4. Add bio: text
    # 5. Add phone: string
    # 6. Add discarded_at: datetime
    t.timestamps
  end
  # 7. Add unique index on user_id
  add_index :profiles, :user_id, unique: true
end

# app/models/profile.rb
class Profile < ApplicationRecord
  include Discard::Model

  # 1. belongs_to :user (enforces user_id NOT NULL at model layer)
  # 2. has_one_attached :avatar
  # 3. validates :user_id, uniqueness: true
end

# app/models/user.rb (addition only)
# 1. Add: has_one :profile, dependent: :destroy

# config/locales/models/en.yml
en:
  activerecord:
    attributes:
      profile:
        # full_name, avatar_url, bio, phone, discarded_at

# test/factories/profiles.rb
FactoryBot.define do
  factory :profile do
    # 1. association :user  ← auto-creates a user via :user factory
    # 2. full_name — use Faker::Name.full_name
    # 3. bio — use Faker::Lorem.sentence
    # 4. phone — use Faker::PhoneNumber.phone_number
    # 5. avatar_url — leave nil (optional)
  end
end

# test/models/profile_test.rb
class ProfileTest < ActiveSupport::TestCase
  # Shoulda-matchers
  test "associations and validations" do
    # should belong_to(:user)
    # should validate_uniqueness_of(:user_id)
  end

  test "valid with all attributes" do
  end

  test "invalid without user" do
    # build(:profile, user: nil).valid? → false
  end

  test "invalid when duplicate profile for same user" do
    # create(:profile, user: user)
    # build(:profile, user: user).valid? → false
  end

  test "discard scoping excludes discarded profiles" do
    # profile = create(:profile)
    # profile.discard
    # Profile.kept does NOT include profile
    # Profile.discarded includes profile
  end
end
```

---

## Notes
- `avatar_url` string column coexists with `has_one_attached :avatar` — the string is a plain URL fallback; the CRUD issue (#8) will decide which one to display in views
- The `[CRUD] Profile` issue (#8) adds the controller (`Edit`/`Update`) and CanCanCan authorization rule (`can :update, Profile, user_id: user.id`) — do not add those here
- annotaterb will auto-update schema comments in `profile.rb` after migration — do not edit the header block manually
