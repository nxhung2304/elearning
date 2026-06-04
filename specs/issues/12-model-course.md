
## **Status:**
- ✅ Merged: 2026-06-03

## Metadata
- **Title:** Course Model — enums (draft/published/archived), level, language, associations, i18n (en)
- **Phase:** 1 - MVP (Week 3-4)
- **GitHub Issue:** #26

---

## Description

Create the `Course` model with three integer enums (`status`, `level`, `language`), `friendly_id` slug from title (locked after creation), soft delete via `Discard::Model`, `belongs_to :teacher` and `belongs_to :category`, `has_many :sections / :enrollments`, price validation, and `published_at` lifecycle callback. Also activate the previously-deferred `before_discard :ensure_subtree_has_no_active_courses` guard in `CourseCategory` and add `has_many :courses` to that model.

---

## Gems added

- `friendly_id` — already in Gemfile (added for CourseCategory); no new gem required

---

## Acceptance Criteria

- [ ] Migration creates `courses` table matching ERD schema
- [ ] `status` enum: `draft` (0) | `published` (1) | `archived` (2); default `draft`
- [ ] `level` enum: `beginner` (0) | `intermediate` (1) | `advanced` (2); not null
- [ ] `language` enum: `vi` (0) | `en` (1); not null
- [ ] `slug` auto-generated from `title` via `friendly_id`; locked after creation via `should_generate_new_friendly_id?`
- [ ] `validates :title, presence: true, uniqueness: true`
- [ ] `validates :description, presence: true`
- [ ] `validates :price, numericality: { greater_than_or_equal_to: 0 }`
- [ ] `validate :published_at_requires_published_status` — `published_at` must be nil when status is not `published`
- [ ] `before_validation :set_published_at` — sets `published_at = Time.current` when status changes to `published`; clears it when status changes away from `published`
- [ ] `include Discard::Model` — default scope `.kept` active
- [ ] `belongs_to :teacher, class_name: "User"`
- [ ] `belongs_to :category, class_name: "CourseCategory"`
- [ ] `has_many :sections, dependent: :destroy` (hard destroy cascades; soft-delete via Section's own `discard`)
- [ ] `has_many :lessons, through: :sections`
- [ ] `has_many :enrollments`
- [ ] `CourseCategory` updated: add `has_many :courses`; implement deferred `before_discard :ensure_subtree_has_no_active_courses`
- [ ] Factory `create(:course)` works without arguments; traits `:published`, `:archived`
- [ ] i18n keys added to `config/locales/models/en.yml` under `activerecord.models` and `activerecord.attributes.course`
- [ ] Minitest model: happy — create with all present values; set each enum value
- [ ] Minitest model: edge — title blank, price negative, status outside enum, published_at present when status is draft, slug duplicate

---

## Implementation Checklist

- [ ] Generate migration: `bin/rails g migration CreateCourses`
- [ ] Run `bin/rails db:migrate`
- [ ] Create `app/models/course.rb`
- [ ] Update `app/models/course_category.rb` — add `has_many :courses`, implement `ensure_subtree_has_no_active_courses`
- [ ] Create `test/factories/courses.rb`
- [ ] Create `test/models/course_test.rb`
- [ ] Add i18n keys to `config/locales/models/en.yml`
- [ ] Run `bin/rails test test/models/course_test.rb`
- [ ] Run `bin/rubocop app/models/course.rb app/models/course_category.rb test/models/course_test.rb`

---

## Step-by-step Guide

**Files to create/modify:**
- `db/migrate/TIMESTAMP_create_courses.rb` — table definition
- `app/models/course.rb` — model with enums, friendly_id, discard, validations, callbacks
- `app/models/course_category.rb` — add `has_many :courses`; implement deferred discard guard
- `test/factories/courses.rb` — default factory + `:published`, `:archived` traits
- `test/models/course_test.rb` — model tests
- `config/locales/models/en.yml` — add `course` model + attribute keys

**Key decisions:**
- **`friendly_id` slug from `title`** — `use: %i[slugged finders]` (consistent with `CourseCategory`); `should_generate_new_friendly_id? { slug.blank? }` locks slug after creation; uniqueness suffix auto-appended (`-2`, `-3`, ...).
- **`teacher_id` / `category_id` FK columns** — migration must use `t.references :teacher` and `t.references :category` (no `_id` suffix); Rails appends `_id` automatically. Model uses `belongs_to` with no explicit `foreign_key:` override. ⚠️ Original migration used `:category_id` / `:teacher_id` generating double-`_id` columns — rollback and fix required.
- **`enum :language` values** — `{ vi: 0, en: 1 }` (short locale codes). Do NOT use `english`/`vietnamese`. i18n labels: `vi → "Vietnamese"`, `en → "English"`.
- **`published_at` lifecycle** — managed by `before_validation` callback (NOT `before_save`). Ensures `published_at` is cleared before the strict validator runs, so unpublishing passes. Controller only sets `status`; the model owns the timestamp.
- **`set_published_at` logic** — set `published_at = Time.current` when `will_save_change_to_status? && published?`; clear to nil when `will_save_change_to_status? && status_was == "published"`. No `persisted?` guard needed — `status_was` returns nil for new records, not `"published"`, so the clear branch never fires incorrectly.
- **`validate :published_at_requires_published_status`** — strict: `errors.add(:published_at, :invalid) if !published? && published_at.present?`. Fires on every save. Safe because `before_validation :set_published_at` already cleared `published_at` before this runs.
- **`validates :published_at, presence: true, if: :published?`** — kept as explicit safety net even though the callback always sets it. Guards against a silent callback bug.
- **`validates :title, uniqueness:`** — scoped to kept records: `uniqueness: { conditions: -> { kept } }`. A soft-deleted course title can be reused.
- **`validates :level, presence: true` and `validates :language, presence: true`** — required; these columns have no DB default so `nil` would raise a raw `PG::NotNullViolation` without a model-layer guard.
- **`validates :price`** — `numericality: { greater_than_or_equal_to: 0 }` only; no `presence: true` (numericality already rejects nil).
- **`validates :slug` — OMIT** — slug always generated by `friendly_id`.
- **`validates :total_lessons` — OMIT** — managed by a background job (future issue); DB default 0 is the only constraint.
- **`sections dependent: :destroy`** — hard-cascade sections when course is hard-destroyed. Do NOT add `dependent:` for enrollments — orphaned enrollments handled separately.
- **`CourseCategory#ensure_subtree_has_no_active_courses`** (renamed from `ensure_no_courses_assigned`) — must check BOTH `courses.kept.exists?` (self) AND `descendants.kept.joins(:courses).merge(Course.kept).exists?`. Original only checked descendants — a category with direct active courses could be discarded.
- **`CourseCategory has_many :courses, dependent: :restrict_with_error`** — blocks hard-destroy if any courses exist, consistent with the discard guard.
- **Seeds** — update `language: :english` → `language: :en` in `db/seeds.rb`.
- **Test for invalid enum** — `assert_raises(ArgumentError) { course.status = 99 }` (Rails 7+ raises on out-of-range integer, not `valid? == false`).

**Flow Diagram:**
```
Status transition:
  [draft] ──publish──▶ [published] ──archive──▶ [archived]
     ▲                      │                        │
     └──────────────────────┘                        │
            unpublish                                │
                                                     │
     (no transition from archived → published        │
      without explicit status= assignment)           │
                                                     ▼
                                                (terminal — no auto-transition)

before_validation :set_published_at:  ← NOTE: before_validation, not before_save
  status changed to "published"?
    YES → published_at = Time.current
    NO  → status changed away from "published"?
            YES → published_at = nil
            NO  → no-op

validate :published_at_requires_published_status:
  !published? && published_at.present?
    YES → errors.add(:published_at, :invalid)
    NO  → no-op
  (published_at is already cleared by before_validation above, so unpublish passes)

CourseCategory discard guard (now active, checks self + descendants):
  category.discard
       │
       ▼
  before_discard: self.courses.kept.exists?          ← self check (was missing)
  OR descendants.kept.joins(:courses).merge(Course.kept).exists?
       ├── YES → errors.add(:base, :has_active_courses) + throw :abort
       └── NO  → discarded_at set; children cascade via after_discard
```

**Non-obvious snippets:**
```ruby
# db/migrate/TIMESTAMP_create_courses.rb
def change
  create_table :courses do |t|
    t.references :teacher,  null: false, foreign_key: { to_table: :users }
    t.references :category, null: false, foreign_key: { to_table: :course_categories }
    t.string   :title,           null: false
    t.string   :slug,            null: false
    t.text     :description,     null: false
    t.integer  :level,           null: false
    t.integer  :language,        null: false
    t.decimal  :price,           precision: 10, scale: 2, null: false, default: 0
    t.integer  :total_lessons,   null: false, default: 0
    t.integer  :status,          null: false, default: 0
    t.datetime :published_at
    t.datetime :discarded_at

    t.timestamps
  end

  add_index :courses, :slug,         unique: true
  add_index :courses, :title,        unique: true
  add_index :courses, :discarded_at
end

# app/models/course.rb
class Course < ApplicationRecord
  include Discard::Model

  extend FriendlyId
  friendly_id :title, use: %i[slugged finders]

  belongs_to :teacher, class_name: "User"
  belongs_to :category, class_name: "CourseCategory"
  has_many :sections, dependent: :destroy
  has_many :lessons, through: :sections
  has_many :enrollments

  enum :status,   { draft: 0, published: 1, archived: 2 }
  enum :level,    { beginner: 0, intermediate: 1, advanced: 2 }
  enum :language, { vi: 0, en: 1 }

  validates :title,       presence: true, uniqueness: { conditions: -> { kept } }
  validates :description, presence: true
  validates :price,       numericality: { greater_than_or_equal_to: 0 }
  validates :level,       presence: true
  validates :language,    presence: true
  validates :published_at, presence: true, if: :published?
  # no validates :slug (friendly_id guarantees it)
  # no validates :total_lessons (managed by background job)

  validate :published_at_requires_published_status

  before_validation :set_published_at

  def should_generate_new_friendly_id?
    slug.blank?
  end

  private

  def set_published_at
    if will_save_change_to_status? && published?
      self.published_at = Time.current
    elsif will_save_change_to_status? && status_was == "published"
      self.published_at = nil
    end
  end

  def published_at_requires_published_status
    errors.add(:published_at, :invalid) if !published? && published_at.present?
  end
end

# app/models/course_category.rb  (additions)
has_many :courses, dependent: :restrict_with_error
before_discard :ensure_subtree_has_no_active_courses

private

def ensure_subtree_has_no_active_courses
  has_active = courses.kept.exists? ||
               descendants.kept.joins(:courses).merge(Course.kept).exists?
  return unless has_active

  errors.add(:base, :has_active_courses)
  throw(:abort)
end

# test/factories/courses.rb
FactoryBot.define do
  factory :course do
    association :teacher, factory: :user
    association :category, factory: :course_category
    sequence(:title) { |n| "Course #{n}" }
    description { "A test course description." }
    level       { :beginner }
    language    { :en }   # ← :en matches enum { vi: 0, en: 1 }
    price       { 0 }
    status      { :draft }
    # NOTE: do NOT set slug (friendly_id generates it from title)
    # NOTE: do NOT set published_at or discarded_at in default factory

    trait :published do
      status { :published }
      # NOTE: do NOT set published_at manually — before_validation sets it automatically
    end

    trait :archived do
      status { :archived }
    end
  end
end

# test/models/course_test.rb

test "valid with all required attributes" do
end

test "invalid when title is blank" do
end

test "invalid when description is blank" do
end

test "invalid when price is negative" do
end

test "slug is auto-generated from title" do
end

test "slug is locked after creation" do
end

test "slug duplicate appends suffix" do
end

test "published_at is set when status transitions to published" do
end

test "published_at is cleared when status transitions away from published" do
end

test "invalid when published_at is set on a draft course" do
end

test "invalid when status value is outside enum" do
end

test "belongs to teacher" do
end

test "belongs to category" do
end

test "soft delete excludes record from default scope" do
end
```

---

## Notes

- `enum :status` with keyword args (`enum :status, { draft: 0 }`) is the Rails 7+ syntax; avoid positional `enum status:` hash syntax to be explicit.
- `friendly_id` is already bundled — no Gemfile change needed.
- `total_lessons` is intentionally not validated — it is managed by a background job (future issue). Set default 0 in migration only.
- `thumbnail_url` is nullable and stores a URL string for now; ActiveStorage attachment comes in a later issue.
- After creating this model, run `bin/rails test test/models/course_category_test.rb` to ensure the deferred discard guard tests still pass.
- `sections dependent: :destroy` triggers Rails `before_destroy` / `after_destroy` callbacks on Section; this is intentional for hard-delete only. Soft-delete callers should call `course.discard` then `course.sections.kept.find_each(&:discard)` (handled in a future issue when Section model exists).

### Clarified during drill + grill (2026-06-03)

- **Migration FK bug** — existing migration used `t.references :category_id` / `:teacher_id`, generating `category_id_id` / `teacher_id_id`. Roll back, fix to `t.references :category` / `:teacher`, re-migrate.
- **Language enum** — `{ vi: 0, en: 1 }`. The implemented `{ english: 0, vietnamese: 1 }` was wrong. i18n labels: `vi → "Vietnamese"`, `en → "English"`.
- **`set_published_at` must be `before_validation`** — `before_save` fires after validation; unpublishing would fail the strict guard before the callback clears `published_at`. `before_validation` fixes the ordering.
- **`published_at_requires_published_status` is strict** — `!published? && published_at.present?` on every save. `before_validation` already cleared `published_at` so unpublish passes cleanly.
- **`validates :published_at, presence: true, if: :published?`** — kept as explicit safety net alongside the strict guard.
- **Title uniqueness scoped to kept** — `uniqueness: { conditions: -> { kept } }` so soft-deleted course titles can be reused.
- **`validates :level/language, presence: true`** — no DB default on these columns; model-layer presence prevents raw `PG::NotNullViolation`.
- **`validates :price` — no `presence: true`** — `numericality` already rejects nil.
- **`finders` module** — `use: %i[slugged finders]` consistent with `CourseCategory`.
- **`has_many :courses, dependent: :restrict_with_error`** on `CourseCategory` — blocks hard-destroy when courses exist.
- **Guard renamed** to `ensure_subtree_has_no_active_courses`; must check both `courses.kept.exists?` (self) and descendants.
- **Factory** — no `slug`, `published_at`, or `discarded_at` in default trait. `:published` trait sets only `status { :published }`; callback sets `published_at`.
- **Invalid enum test** — `assert_raises(ArgumentError) { course.status = 99 }`.
- **Seeds** — update `language: :english` → `language: :en` in `db/seeds.rb`.
