## **Status:**
- Review: Approved
- PR: Merged

## Metadata
- **Title:** CourseCategory Model — ancestry (nested), friendly_id (slug), i18n (en)
- **Phase:** 1 - MVP (Week 3-4)
- **GitHub Issue:** [#22](https://github.com/nxhung2304/elearning/issues/22)

---

## Description
Create the `CourseCategory` model with self-referential parent/child nesting via the `ancestry` gem, auto-generated slug from `name` via `friendly_id`, `position` for sibling sort order, soft delete via `Discard::Model`, and i18n attribute names in `config/locales/models/en.yml`.

---

## Gems added
- `ancestry` — self-referential tree via `ancestry` string column; provides `.parent`, `.children`, `.descendants`, `.ancestors` without N+1
- `friendly_id` — slug generation with uniqueness suffix (`-2`, `-3`, ...); locks slug after creation via `should_generate_new_friendly_id?`

---

## Acceptance Criteria
- [ ] Add `gem "ancestry"` and `gem "friendly_id"` to Gemfile; run `bundle install`
- [ ] Migration creates `course_categories` table with: `name`, `slug` (uniq index), `ancestry` (string, indexed, nullable), `position` (default 0), `discarded_at`
- [ ] No `parent_id` FK column — ancestry gem manages the tree via `ancestry` string path (e.g. `"1/2/3"`)
- [ ] `slug` is auto-generated from `name` via `friendly_id`; locked after creation via `should_generate_new_friendly_id? { slug.blank? }`
- [ ] `validates :name, presence: true`
- [ ] `validates :slug, presence: true, uniqueness: true`
- [ ] `validates :position, numericality: { greater_than_or_equal_to: 0 }`
- [ ] `has_ancestry` — provides `.parent`, `.children`, `.descendants`, `.ancestors`, `.subtree`, `.root?`, `.leaf?`
- [ ] `belongs_to :parent` and `has_many :children` come from `has_ancestry` — no manual association needed
- [ ] `has_many :courses` association defined
- [ ] `include Discard::Model` — default scope `.kept` active
- [ ] `before_validation { self.name = name&.strip }` — strips leading/trailing whitespace
- [ ] `validate :parent_must_be_kept` — rejects discarded category as parent (ancestry does not scope `.kept`)
- [ ] Self-reference and circular reference are prevented automatically by `ancestry` gem
- [ ] `before_discard` checks NO descendant has `.kept` courses; rejects entire discard via `throw :abort` *(deferred — Course model not yet created)*
- [ ] `after_discard` cascade-discards kept children (each child's own `after_discard` fires recursively)
- [ ] No `after_undiscard` cascade — children stay discarded after parent is restored (manual restore only)
- [ ] Factory `create(:course_category)` works without arguments; `:with_parent` trait creates a sub-category
- [ ] i18n keys added to `config/locales/models/en.yml` under `activerecord.models` and `activerecord.attributes.course_category`
- [ ] Minitest: happy — create top-level category; create sub-category with valid parent
- [ ] Minitest: edge — name blank → invalid; discarded parent → invalid; slug auto-generated and unique

---

## Implementation Checklist
- [ ] Add `gem "ancestry"` and `gem "friendly_id"` to Gemfile; run `bundle install`
- [ ] Generate migration: `bin/rails g migration CreateCourseCategories`
- [ ] Run `bin/rails db:migrate`
- [ ] Create `app/models/course_category.rb`
- [ ] Create `test/factories/course_categories.rb`
- [ ] Create `test/models/course_category_test.rb`
- [ ] Add i18n keys to `config/locales/models/en.yml`
- [ ] Run `bin/rails test test/models/course_category_test.rb`
- [ ] Run `bin/rubocop app/models/course_category.rb test/models/course_category_test.rb`
- [ ] *(deferred — after Course model)* Add `has_many :courses` to `course_category.rb`
- [ ] *(deferred — after Course model)* Add `before_discard :ensure_subtree_has_no_active_courses` + implement callback

---

## Step-by-step Guide

**Files to create/modify:**
- `Gemfile` — add `ancestry`, `friendly_id`
- `db/migrate/TIMESTAMP_create_course_categories.rb` — table definition
- `app/models/course_category.rb` — model with ancestry, friendly_id, discard callbacks
- `test/factories/course_categories.rb` — default factory + `:with_parent` trait
- `test/models/course_category_test.rb` — model tests
- `config/locales/models/en.yml` — add `course_category` model + attribute keys

**Key decisions:**
- **`ancestry` replaces `parent_id` FK** — stores tree path as string (`"1/2"`, `"1/2/3"`). Provides `.descendants` in a single `WHERE ancestry LIKE '…%'` query — no N+1 recursive DFS. Schema: one nullable `ancestry` string column with index.
- **`friendly_id` replaces manual slug loop** — `use: :slugged` handles uniqueness suffix (`-2`, `-3`, ...) automatically, scoped against ALL records via `FriendlyId::Slug` history. Lock after creation: `should_generate_new_friendly_id? { slug.blank? }`.
- **`parent_must_be_kept` custom validation** — ancestry does not scope `.kept`. A discarded category can still be set as parent without this guard. Validate: `parent.present? && parent.discarded?` → add error.
- **Self-reference and circular chains prevented by `ancestry`** — no manual `validates :parent_id, exclusion` needed.
- **`before_discard` uses `descendants`** — `descendants.kept.joins(:courses).merge(Course.kept).exists?` — single query, no recursive Ruby DFS. *(implement when Course model is created)*
- **`after_discard` cascade via `children.kept.find_each(&:discard)`** — each child fires its own `before_discard` + `after_discard` recursively; grandchildren handled automatically.
- **Discard guard scoped to `.kept` courses only** — `courses.kept.exists?`. Soft-deleted courses do not block discard. *(implement when Course model is created)*
- **Undiscard: no cascade restore** — children stay discarded; admin restores each level manually.
- **`dependent: :nullify` removed** — ancestry manages the tree; hard `destroy` on a parent via ancestry either re-roots or nullifies children depending on `has_ancestry` options (default: re-roots children to root). DB FK constraint on courses prevents hard destroy if courses exist.
- **`has_many :courses` with no `dependent:`** — DB FK prevents hard destroy if courses exist; `before_discard` guards soft-delete path. *(add when Course model is created)*
- **Slug uniqueness via `friendly_id`** — suffix loop scopes against ALL records including discarded. DB unique index on `slug` as defense in depth.
- **`position` defaults to 0** — no auto-increment; set manually via CRUD (issue 11). Validated `>= 0` at model layer only. Allow ties, sort by `position ASC, id ASC`.

**Flow:**
```
CourseCategory tree (ancestry):

  ancestry: nil     → root category (position: 0)
       │
       ├── ancestry: "1"   → child A (position: 0)
       │       └── ancestry: "1/2" → grandchild (position: 0)
       └── ancestry: "1"   → child B (position: 1)

Slug generation (friendly_id — create only, locked after):
  new record, slug blank
       │
       ▼
  friendly_id generates slug = name.parameterize
  taken? → append "-2", "-3", ... (all records incl. discarded)
       │
       ▼
  should_generate_new_friendly_id? { slug.blank? }
  → slug never regenerated when name changes

Discard flow:
  admin calls category.discard
       │
       ▼
  [deferred] before_discard: descendants.kept.joins(:courses).merge(Course.kept).exists?
       ├── YES → errors.add + throw :abort (nothing written)
       └── NO  ↓
  discarded_at set → .kept scope excludes this category
       │
       ▼
  after_discard: children.kept.find_each(&:discard)
       └── each child fires its own before_discard + after_discard (recursive)

Undiscard flow:
  admin calls category.undiscard
       │
       ▼
  discarded_at = nil (parent restored)
  children stay discarded — no after_undiscard callback

Hard destroy flow:
  category.destroy
       │
       ├─ DB FK constraint blocks if courses exist
       └─ ancestry re-roots children (parent_id → nil)
```

**Non-obvious snippets:**
```ruby
# Gemfile
gem "ancestry"
gem "friendly_id"

# db/migrate/TIMESTAMP_create_course_categories.rb
def change
  create_table :course_categories do |t|
    t.string  :name,         null: false
    t.string  :slug,         null: false
    t.string  :ancestry                    # managed by ancestry gem, nullable
    t.integer :position,     default: 0, null: false
    t.datetime :discarded_at

    t.timestamps
  end

  add_index :course_categories, :slug,        unique: true
  add_index :course_categories, :ancestry
  add_index :course_categories, :discarded_at
end

# app/models/course_category.rb
include Discard::Model
has_ancestry
extend FriendlyId
friendly_id :name, use: :slugged

before_validation { self.name = name&.strip }

# has_many :courses  # deferred — Course model not yet created

validates :name,     presence: true
validates :slug,     presence: true, uniqueness: true
validates :position, numericality: { greater_than_or_equal_to: 0 }

validate :parent_must_be_kept, if: -> { parent_id.present? }

# before_discard :ensure_subtree_has_no_active_courses  # deferred — Course model not yet created
after_discard  :discard_children

def should_generate_new_friendly_id?
  slug.blank?
end

private

def parent_must_be_kept
  errors.add(:parent_id, :invalid) if parent&.discarded?
end

# deferred — implement when Course model is created
# def ensure_subtree_has_no_active_courses
#   has_active = descendants.kept.joins(:courses).merge(Course.kept).exists? ||
#                courses.kept.exists?
#   if has_active
#     errors.add(:base, :has_active_courses)
#     throw :abort
#   end
# end

def discard_children
  children.kept.find_each(&:discard)
end

# test/factories/course_categories.rb
FactoryBot.define do
  factory :course_category do
    sequence(:name) { |n| "Category #{n}" }
    # slug auto-generated by friendly_id

    trait :with_parent do
      association :parent, factory: :course_category
    end
  end
end

# test/models/course_category_test.rb

test "valid with name only" do
end

test "invalid when name is blank" do
end

test "slug is auto-generated from name" do
end

test "slug is unique — friendly_id appends suffix" do
end

test "valid sub-category with existing kept parent" do
end

test "invalid when parent is discarded" do
end

test "position defaults to 0" do
end

test "soft delete excludes record from default scope" do
end

test "slug does not change when name is updated" do
end

test "discard cascades to kept children" do
end

test "discard cascades recursively to grandchildren" do
end

# deferred — Course model not yet created
# test "discard blocked when category has active courses" do
# end
#
# test "discard blocked when a descendant has active courses" do
# end

test "invalid when parent_id is self (self-reference)" do
end

test "name is stripped of leading and trailing whitespace" do
end

test "undiscard does not restore discarded children" do
end
```

---

## Notes
- `ancestry` gem manages tree via `ancestry` string path — no `parent_id` FK column in schema. Use `.parent_id` virtual attribute (provided by gem) in forms/factories.
- `friendly_id` with `use: :slugged` requires a `slug` column in the table. No separate `friendly_id_slugs` history table needed unless `use: [:slugged, :history]` is added.
- `descendants.kept` scopes `.kept` on the relation — requires `Discard::Model` default scope on `CourseCategory`. Verify this works with ancestry's query before shipping.
- `ensure_subtree_has_no_active_courses` checks both `descendants.kept` courses AND direct `courses.kept` of self (descendants does not include self). *(deferred — implement when Course model is created)*
- `before_discard` / `after_discard` use Discard gem callbacks — `throw :abort` halts the same way as `before_destroy`.
- Deeper circular chain detection is handled by `ancestry` gem automatically — no custom guard needed.
- N+1 on discard cascade (`children.kept.find_each(&:discard)`) is acceptable for Phase 1 shallow trees; `ancestry` bulk-discard via `descendants` can be optimized in Phase 4.
