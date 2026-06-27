## Status
- Review: Approved
- PR: —

## Metadata
- **Title:** [CRUD] Lesson — Teacher CRUD (nested under Section) + ActiveStorage upload video
- **Phase:** Phase 1 — MVP (Web) · Week 3-4
- **GitHub Issue:** - #39

---

## Description

Teacher CRUD cho Lesson, nested dưới Section + Course (`/courses/:course_id/sections/:section_id/lessons`). Model `Lesson` đã có sẵn — task này bổ sung:

- `has_one_attached :video` trên Lesson model, thay thế `video_url` string bằng ActiveStorage attachment
- Controller + views đầy đủ cho Teacher CRUD
- Form upload video qua `multipart/form-data` với `file_field :video`

---

## Acceptance Criteria

- [ ] Route deeply nested: `resources :courses do; resources :sections do; resources :lessons; end; end`
- [ ] `Lesson` có `has_one_attached :video`
- [ ] Migration xóa cột `video_url` (thay bằng ActiveStorage attachment)
- [ ] Lesson model validation cập nhật: dùng `video.attached?` thay vì `video_url.present?`
- [ ] Teacher CRUD lessons thuộc section của course mình
- [ ] Teacher không truy cập lessons của course người khác (403)
- [ ] Form: `title`, `lesson_type`, `content`, `video` (file upload), `duration_seconds`, `is_preview`, `is_published`
- [ ] `content` field ẩn/hiện theo `lesson_type` (text/mixed cần content; video không cần)
- [ ] `video` upload field ẩn/hiện theo `lesson_type` (video/mixed cần video)
- [ ] Index scoped theo section; không cần search/Pagy (lessons per section ít)
- [ ] Show: tất cả fields + video player nếu video đã attach
- [ ] Unauthenticated → redirect login
- [ ] Minitest: happy path + edge cases

---

## Implementation Checklist

- [ ] Migration: xóa cột `video_url` — `bin/rails g migration RemoveVideoUrlFromLessons video_url:string`
- [ ] Cập nhật `app/models/lesson.rb`:
  - Thêm `has_one_attached :video`
  - Đổi validation `video_url` → `validates :video, attached: true, if: -> { video? || mixed? }`
  - Đổi validation `duration_seconds absence` khi text (không cần thay đổi)
- [ ] Cập nhật `test/factories/lessons.rb` — xóa `video_url` trait, dùng `after(:build)` để attach video stub nếu cần
- [ ] Cập nhật `test/models/lesson_test.rb` — sửa các test liên quan đến `video_url`
- [ ] Nested route trong `config/routes.rb`:
  ```ruby
  resources :courses do
    resources :sections do
      resources :lessons
    end
  end
  ```
- [ ] `LessonsController`:
  - `load_and_authorize_resource :course`
  - `load_and_authorize_resource :section, through: :course`
  - `load_and_authorize_resource :lesson, through: :section`
  - Actions: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`
  - `destroy` dùng `discard` (soft delete)
  - `lesson_params`: `title`, `lesson_type`, `content`, `video`, `duration_seconds`, `is_preview`, `is_published`
- [ ] `ability.rb` — Teacher: `can :manage, Lesson, section: { course_id: Course.kept.where(teacher_id: user.id).ids }`
- [ ] Views: `index`, `show`, `_form`, `new`, `edit`
  - `_form`: Stimulus controller để toggle `content` / `video` fields theo `lesson_type`
- [ ] Thêm link "Lessons" trên `sections#show`
- [ ] i18n keys trong `en.yml` cho `lesson` attributes (cập nhật `video_url` → `video`)
- [ ] `test/controllers/lessons_controller_test.rb`
- [ ] `bin/rails test test/models/lesson_test.rb`
- [ ] `bin/rails test test/controllers/lessons_controller_test.rb`
- [ ] `bin/rubocop app/models/lesson.rb app/controllers/lessons_controller.rb`

---

## User Flow

```
Section#show  (/courses/:course_id/sections/:section_id)
    └── [Lessons] link
            └── Lesson#index  (/courses/:id/sections/:id/lessons)
                    ├── [New Lesson]  → Lesson#new  → Lesson#show
                    ├── [Edit]        → Lesson#edit → Lesson#show
                    └── [Delete]      → Lesson#index
```

---

## Wireframe

**Index** — `/courses/:course_id/sections/:section_id/lessons`
```
← Back to Section: Introduction

Lessons                                          [+ New Lesson]
──────────────────────────────────────────────────────────────

  #   Title                   Type    Published   Actions
  ────────────────────────────────────────────────────────
  1   What is Rails?          video   Yes         Show · Edit · Delete
  2   Installing Ruby         video   No          Show · Edit · Delete
  3   Core Concepts           text    No          Show · Edit · Delete
```

**New / Edit Form**
```
← Back to Lessons

New Lesson
──────────────────────────────

Title         [                              ]

Lesson Type   ( ) Video  ( ) Text  ( ) Mixed

Content       [                              ]  ← visible if text/mixed
              [                              ]

Video         [Choose file...]               ← visible if video/mixed
Duration (s)  [     ]

              [ ] Preview lesson
              [ ] Published

              [Save]
```

**Show**
```
← Back to Lessons

What is Rails?
──────────────────────────────
Type          video
Duration      312s
Preview       No
Published     Yes
Created       27 Jun 2026

[video player if video attached]

                               [Edit]  [Delete]
```

---

## Key Decisions

- **Xóa `video_url` column, dùng ActiveStorage** — `video_url` string không đủ để handle file upload natively; ActiveStorage cung cấp direct upload, service URL, và variant support. `video.attached?` thay thế `video_url.present?` trong mọi validation.
- **Deeply nested route** — Lesson không tồn tại độc lập, phụ thuộc Section → Course. Nesting 3 cấp là trade-off chấp nhận được ở Phase 1; có thể shallow-nest Phase 2+ nếu cần.
- **Không dùng Ransack/Pagy ở Index** — số lesson per section thường nhỏ (< 20), không cần pagination.
- **Stimulus toggle fields** — `lesson_type` selector drive visibility của `content` và `video` inputs; tránh full page reload khi teacher đổi type.
- **`able.rb` condition qua join** — CanCanCan không support hash condition qua 2 cấp join (`section: { course: { teacher_id: } }`) → dùng subquery: `section_id: Section.kept.where(course_id: Course.kept.where(teacher_id: user.id).ids).ids`.
- **`duration_seconds` nhập thủ công** — Phase 1 không có video duration detection; teacher nhập tay. Phase 2+ có thể auto-detect từ blob metadata.
