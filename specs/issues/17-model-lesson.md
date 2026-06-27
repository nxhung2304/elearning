## Status
- Review: pending
- PR: —

## Metadata
- **Title:** Model Lesson — lesson_type enum (video/text/mixed), is_published, associations, i18n (en)
- **Phase:** 1 - MVP (Week 3-4)
- **GitHub Issue:** #37

---

## Description

Create the `Lesson` model scoped to a `Section`. Lessons have a `lesson_type` enum (`video | text | mixed`) that drives cross-field validation: `content` is required for text/mixed, `video_url` for video/mixed, and `duration_seconds` must be present if and only if `video_url` is set. Soft delete via `Discard::Model`; position ordered per section via `positioning` gem.

---

## ERD
```
bigint id
bigint section_id "NOT NULL"
string title "NOT NULL"
integer lesson_type "NOT NULL | video·text·mixed"
text content
string video_url
integer duration_seconds
integer position "NOT NULL"
boolean is_preview "NOT NULL · def:false"
boolean is_published "NOT NULL · def:false"
datetime published_at
datetime discarded_at
```

## Acceptance Criteria

- [ ] Migration creates `lessons` table with all columns from ERD
- [ ] `lesson_type` is an integer enum (`video: 0, text: 1, mixed: 2`), not null
- [ ] `is_published` is a boolean, not null, default false
- [ ] `is_preview` is a boolean, not null, default false
- [ ] `Lesson` includes `Discard::Model`
- [ ] `Lesson` uses `positioned on: :section` (scoped per section)
- [ ] `Lesson` validates `title` presence
- [ ] Cross-field validation: `content` required when `lesson_type` is `text` or `mixed`
- [ ] Cross-field validation: `video_url` required when `lesson_type` is `video` or `mixed`
- [ ] Cross-field validation: `duration_seconds` required when `video_url` present
- [ ] Cross-field validation: `duration_seconds` must be nil when `video_url` blank
- [ ] `Section` has `before_discard` callback that calls `lessons.discard_all`
- [ ] `Section` keeps `has_many :lessons, dependent: :restrict_with_error`
- [ ] Factory `build(:lesson)` is valid with default `lesson_type: :video`
- [ ] Factory has `:text_lesson` and `:mixed_lesson` traits
- [ ] Factory has `:discarded` trait
- [ ] i18n keys added for `lesson` model and all attributes in `config/locales/en.yml`
- [ ] Minitest covers all happy + edge cases listed in story.md

---

## Implementation Checklist

- [ ] Generate migration: `bin/rails g migration CreateLessons`
- [ ] Write migration — add all columns + `index :discarded_at` + unique index on `[:section_id, :position]`
- [ ] Run `bin/rails db:migrate`
- [ ] Create `app/models/lesson.rb` — enum, validations, associations, `Discard::Model`, `positioned on: :section`
- [ ] Update `app/models/section.rb` — add `has_many :lessons, dependent: :restrict_with_error` + `before_discard :discard_lessons` callback
- [ ] Create `test/factories/lessons.rb` — default `:video` trait, `:text_lesson`, `:mixed_lesson`, `:discarded` traits
- [ ] Create `test/models/lesson_test.rb` — happy + edge cases
- [ ] Add i18n keys to `config/locales/en.yml` under `activerecord.models.lesson` and `activerecord.attributes.lesson`
- [ ] Run `bin/rails test test/models/lesson_test.rb`
- [ ] Run `bin/rails test test/models/section_test.rb`
- [ ] Run `bin/rubocop app/models/lesson.rb app/models/section.rb test/models/lesson_test.rb test/factories/lessons.rb`

---

## Flow Diagram

```
lesson_type validation rules:
  video  → video_url required, duration_seconds required, content optional
  text   → content required, video_url must be nil, duration_seconds must be nil
  mixed  → content required, video_url required, duration_seconds required

duration_seconds constraint:
  video_url present → duration_seconds must be present
  video_url blank   → duration_seconds must be nil

Section soft-delete cascade:
  section.discard
       │
       ▼
  before_discard :discard_lessons
       │
       ├── lessons.discard_all  ← sets discarded_at on all kept lessons
       └── section.discarded_at = Time.current

  section.destroy (hard destroy blocked):
       │
       ▼
  dependent: :restrict_with_error
       └── lessons exist? → raises error, destroy aborted
```

---

## Key Decisions

- **`positioned on: :section`** — same gem as Section; scopes position 1..N per section. Do NOT use `acts_as_list`. Do NOT add `validates :position, presence: true` — the gem manages it.
- **Unique index on `[:section_id, :position]`** — add to the `CreateLessons` migration directly; `positioning` gem relies on this constraint.
- **Cross-field validation via custom validate method** — `validates :video_url, presence: true if :video_or_mixed?` style is cleaner than multiple `with_options` blocks. One `validate :content_or_video_required` method handles the matrix.
- **`duration_seconds` bidirectional constraint** — both directions must be validated: nil when no video, present when video present. A single custom validator covers both.
- **`before_discard` on Section** — same pattern as Course → Section. `dependent: :restrict_with_error` only fires on hard-destroy, not soft-delete.
- **`is_published` vs `status` enum** — Lesson uses a boolean flag (not an enum like Course) per ERD spec. Do not change this to an enum.
