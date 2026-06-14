## **Status:**
- Review: Approved ✅
- PR: Merged ✅ 2026-06-13

## Metadata
- **Title:** Section Model — positioning gem, soft delete, cascade discard from Course
- **Phase:** 1 - MVP (Week 3-4)
- **GitHub Issue:** #30

---

## Description

Create the `Section` model scoped to a `Course`. Sections maintain an ordered position within their course using the `positioning` gem (scoped per course). Soft delete via `Discard::Model`. When a course is soft-deleted, its sections are cascaded. The migration gets a unique index on `[course_id, position]` for data integrity.

---

## Gems added

- `positioning` — ordered list management with `before:/after:` relative positioning; replaces `acts_as_list`

---

## Acceptance Criteria

- [ ] `gem 'positioning'` added to Gemfile
- [ ] Migration has unique index on `[:course_id, :position]`
- [ ] `Section` includes `Discard::Model`
- [ ] `Section` uses `positioned on: :course` (scoped per course)
- [ ] `Section` does NOT include `PositionValidatable` (positioning gem manages position)
- [ ] `Section` validates `title` presence
- [ ] `Course` has `before_discard` callback that calls `sections.discard_all`
- [ ] `Course` keeps `has_many :sections, dependent: :restrict_with_error` (hard-delete guard)
- [ ] Factory `build(:section)` is valid (no `discarded_at` default)
- [ ] Factory has `:discarded` trait for tests that need a soft-deleted section
- [ ] Section test covers: valid factory, `validate_presence_of(:title)`, `belong_to(:course)`, `respond_to(:discard)`, `respond_to(:kept)`
- [ ] i18n already complete — no changes needed

---

## Implementation Checklist

- [ ] Add `gem 'positioning'` to `Gemfile` and run `bundle install`
- [ ] Update `db/migrate/20260613084224_create_sections.rb` — add unique index on `[:course_id, :position]`
- [ ] Run `bin/rails db:migrate` (or `db:rollback` + re-migrate if already migrated)
- [ ] Update `app/models/section.rb` — add `Discard::Model`, `positioned on: :course`; remove `PositionValidatable`
- [ ] Update `app/models/course.rb` — add `before_discard :discard_sections` callback
- [ ] Update `test/factories/sections.rb` — remove `discarded_at`, remove `position` (positioning sets it), add `:discarded` trait
- [ ] Update `test/models/section_test.rb` — add Discard respond_to tests
- [ ] Run `bin/rails test test/models/section_test.rb`
- [ ] Run `bin/rails test test/models/course_test.rb`
- [ ] Run `bin/rubocop app/models/section.rb app/models/course.rb test/models/section_test.rb test/factories/sections.rb`

---

## Step-by-step Guide

**Files to create/modify:**
- `Gemfile` — add `gem 'positioning'`
- `db/migrate/20260613084224_create_sections.rb` — add unique index on `[:course_id, :position]`
- `app/models/section.rb` — include Discard::Model, positioned on: :course
- `app/models/course.rb` — add before_discard cascade
- `test/factories/sections.rb` — fix factory, add :discarded trait
- `test/models/section_test.rb` — add Discard coverage

**Key decisions:**
- **`positioning` not `acts_as_list`** — `positioned on: :course` scopes position per course. The gem's author recommends `positioning` for new projects. Do NOT use `acts_as_list scope: :course_id`.
- **Remove `PositionValidatable` from Section** — `positioning` manages position automatically (sets it after validation). Do NOT add `validates :position, presence: true` on Section. The concern stays in the codebase for other models.
- **Unique index on `[course_id, position]`** — add to the existing `CreateSections` migration, not a new migration. `positioning` gem relies on this constraint for integrity.
- **`before_discard :discard_sections` on Course** — `dependent: :restrict_with_error` only fires on hard-destroy, not soft-delete. The callback bridges the gap for discard cascades.
- **Factory `discarded_at` removed** — `discarded_at { Time.current }` was wrong; it created already-discarded sections. Default is `nil`. Use `:discarded` trait when a soft-deleted section is needed.
- **`position` removed from factory** — `positioning` auto-assigns position on create. Setting it manually in factory bypasses the gem and can break ordering.

**Flow:**
```
Section positioning (per course):
  course.sections: [S1(pos=1), S2(pos=2), S3(pos=3)]

  Section.create(course: course)           → appended at pos=4
  Section.create(course: course, position: {before: S2}) → pos=2, S2 shifts to 3, S3 to 4
  section.update(position: :first)         → pos=1, others shift down

Course soft-delete cascade:
  course.discard
       │
       ▼
  before_discard :discard_sections
       │
       ├── sections.discard_all   ← sets discarded_at on all kept sections
       └── course.discarded_at = Time.current

  course.discard (hard destroy blocked):
  course.destroy
       │
       ▼
  dependent: :restrict_with_error
       └── sections exist? → raises error, destroy aborted
```

**Non-obvious snippets:**
```ruby
# db/migrate/20260613084224_create_sections.rb
class CreateSections < ActiveRecord::Migration[8.1]
  def change
    create_table :sections do |t|
      t.references :course, null: false, foreign_key: true
      t.string  :title,       null: false
      t.integer :position,    null: false, default: 0
      t.datetime :discarded_at
      t.timestamps
      t.index :discarded_at
    end
    add_index :sections, [:course_id, :position], unique: true
  end
end

# app/models/section.rb
class Section < ApplicationRecord
  include Discard::Model

  # positioned on: :course scopes position 1..N per course
  positioned on: :course

  belongs_to :course

  validates :title, presence: true
end

# app/models/course.rb (additions only)
before_discard :discard_sections

private

# cascades soft-delete to all kept sections when course is discarded
def discard_sections
end

# test/factories/sections.rb
FactoryBot.define do
  factory :section do
    title { Faker::Lorem.sentence(word_count: 3) }
    association :course

    trait :discarded do
      discarded_at { Time.current }
    end
  end
end

# test/models/section_test.rb
test "valid factory" do
end

context "associations" do
  should belong_to(:course)
end

context "validations" do
  should validate_presence_of(:title)
end

context "soft delete" do
  test "responds to discard" do
  end

  test "responds to kept scope" do
  end
end
```

---

## Notes

- `positioning` uses 0 and negative integers internally during reordering — do NOT add `greater_than_or_equal_to: 0` DB constraints on position. The unique index is sufficient.
- If the migration was already run (`db:migrate` done), rollback first: `bin/rails db:rollback`, then add the unique index and re-migrate.
- `sections.discard_all` is a Discard gem batch method — updates `discarded_at` for all kept sections in one SQL query without triggering individual callbacks.
- The `PositionValidatable` concern is kept in `app/models/concerns/position_validatable.rb` — it's used by `CourseCategory` and potentially other models. Do not delete it.

### Decisions made during grill (2026-06-13)

- **`include Discard::Model` missing** — omission in original Section model; added now.
- **Factory `discarded_at` bug** — `discarded_at { Time.current }` created already-discarded sections by default; removed.
- **`positioning` over `acts_as_list`** — same author recommends `positioning` for new projects; better relative positioning API and concurrency handling.
- **Unique index in existing migration** — not a new migration; added inside `CreateSections`.
- **`before_discard` cascade** — `dependent: :restrict_with_error` only guards hard-destroy; cascade added via callback.
- **Title length** — `presence: true` only, consistent with rest of codebase.
- **i18n** — already complete (`section` model + all attributes defined in `en.yml`).
