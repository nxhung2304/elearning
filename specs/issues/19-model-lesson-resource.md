## Status
- Review: Approved
- PR: —

## Metadata
- **Title:** Model LessonResource — associations, i18n (en)
- **Phase:** 1 - MVP (Week 3-4)
- **GitHub Issue:** #41

---

## Description

Create the `LessonResource` model to store file attachments for a lesson. Files are managed via ActiveStorage (`has_one_attached :file`) — no `file_url` column. `file_name` stores the display name shown to the user. Soft delete via `Discard::Model`; no positional ordering needed.

---

## ERD
```
bigint   id
bigint   lesson_id    "NOT NULL"
string   file_name    "NOT NULL"
datetime discarded_at
# file attachment via has_one_attached :file (ActiveStorage)
```

---

## Acceptance Criteria

- [ ] Migration creates `lesson_resources` table with `lesson_id`, `file_name`, `discarded_at`
- [ ] No `file_url` column — file stored via ActiveStorage
- [ ] `LessonResource` includes `Discard::Model`
- [ ] `LessonResource` validates `file_name` presence
- [ ] `LessonResource` validates `file` attachment presence
- [ ] `LessonResource` has `belongs_to :lesson`
- [ ] `Lesson` has `has_many :lesson_resources, dependent: :restrict_with_error`
- [ ] `Lesson` has `before_discard` callback that calls `lesson_resources.discard_all`
- [ ] Factory `build(:lesson_resource)` is valid with a stubbed file attachment
- [ ] Factory has `:discarded` trait
- [ ] i18n keys added for `lesson_resource` model and all attributes in `config/locales/en.yml`
- [ ] Minitest covers all happy + edge cases listed in story.md

---

## Implementation Checklist

- [ ] Generate migration: `bin/rails g migration CreateLessonResources`
- [ ] Write migration — add columns + `index :lesson_id` + `index :discarded_at`
- [ ] Run `bin/rails db:migrate`
- [ ] Create `app/models/lesson_resource.rb` — `belongs_to :lesson`, `has_one_attached :file`, validations, `Discard::Model`
- [ ] Update `app/models/lesson.rb` — add `has_many :lesson_resources, dependent: :restrict_with_error` + `before_discard :discard_lesson_resources` callback
- [ ] Create `test/factories/lesson_resources.rb` — default factory with stubbed file, `:discarded` trait
- [ ] Create `test/models/lesson_resource_test.rb` — happy + edge cases
- [ ] Add i18n keys to `config/locales/en.yml` under `activerecord.models.lesson_resource` and `activerecord.attributes.lesson_resource`
- [ ] Run `bin/rails test test/models/lesson_resource_test.rb`
- [ ] Run `bin/rails test test/models/lesson_test.rb`
- [ ] Run `bin/rubocop app/models/lesson_resource.rb app/models/lesson.rb test/models/lesson_resource_test.rb test/factories/lesson_resources.rb`

---

## Flow Diagram

```
Lesson soft-delete cascade:
  lesson.discard
       │
       ▼
  before_discard :discard_lesson_resources
       │
       ├── lesson_resources.discard_all  ← sets discarded_at on all kept resources
       └── lesson.discarded_at = Time.current

  lesson.destroy (hard destroy blocked):
       │
       ▼
  dependent: :restrict_with_error
       └── lesson_resources exist? → raises error, destroy aborted

ActiveStorage flow:
  lesson_resource.file.attach(io: ..., filename: ...)
       └── stored via ActiveStorage::Blob → no file_url column needed
  lesson_resource.file.url
       └── resolved via rails_blob_url helper in views
```

---

## Key Decisions

- **No `file_url` column** — ActiveStorage manages blob URLs. Storing a URL in the DB would become stale when storage config changes.
- **`file_name` kept as a separate string column** — display name for the user; the original filename from upload may be sanitized by ActiveStorage. This gives teacher control over the label.
- **`has_one_attached :file`** — one file per resource row. Multiple attachments = multiple `LessonResource` rows. This keeps soft-delete and metadata per-file.
- **`before_discard` on Lesson** — same pattern as Section → Lesson cascade. `dependent: :restrict_with_error` only fires on hard-destroy.
- **No `positioned` ordering** — resources are listed by `created_at`; no reordering UI in scope for Phase 1.
