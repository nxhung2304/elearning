## Status
- Review: Approved
- PR: —

## Metadata
- **Title:** [CRUD] LessonResource — Teacher upload/delete file đính kèm
- **Phase:** 1 - MVP (Week 3-4)
- **GitHub Issue:** 43

---

## Description

Implement the controller and views for `LessonResource` so a Teacher can upload file attachments to a lesson and soft-delete them. Files are stored via ActiveStorage (`has_one_attached :file`). The resource is nested under `Lesson` (which is nested under `Section` → `Course`). Only the Teacher who owns the course may manage its lesson resources.

---

## Acceptance Criteria

- [ ] Teacher can upload a file attachment to a lesson (form on lesson show/edit page)
- [ ] Teacher can view the list of resources attached to a lesson
- [ ] Teacher can soft-delete (discard) a lesson resource; it no longer appears in the list
- [ ] Non-owner teacher attempting to manage another teacher's resources receives 403
- [ ] Unauthenticated requests are redirected to login
- [ ] File size validation enforced (≤ 10 MB) — invalid upload shows error message
- [ ] `file_name` is shown in the resource list; defaults to original filename if not provided
- [ ] Routes are nested under `lessons` (shallow or fully nested)
- [ ] CanCanCan ability guards `create` and `destroy` on `LessonResource`
- [ ] Minitest covers happy + edge cases listed in story.md

---

## Implementation Checklist

- [ ] Add nested route under `lessons`: `resources :lesson_resources, only: [:create, :destroy]`
- [ ] Generate controller: `bin/rails g controller LessonResources create destroy`
- [ ] `LessonResourcesController#create` — find lesson (scoped to current teacher's course), authorize, attach file, redirect back
- [ ] `LessonResourcesController#destroy` — find resource, authorize, call `resource.discard`, redirect back
- [ ] Update `app/abilities/ability.rb` — Teacher can `:create` and `:destroy` `LessonResource` if they own the lesson's course
- [ ] Add `_lesson_resources` partial to lesson show view — list resources with file name, download link, and delete button
- [ ] Add upload form (file field + file_name field) to lesson show/edit view
- [ ] Add i18n keys to `config/locales/en.yml` for flash messages (uploaded, deleted)
- [ ] Create `test/controllers/lesson_resources_controller_test.rb` — happy + edge cases
- [ ] Run `bin/rails test test/controllers/lesson_resources_controller_test.rb`
- [ ] Run `bin/rubocop app/controllers/lesson_resources_controller.rb app/abilities/ability.rb`

---

## User Flow

```
Course Show
    └── Section (accordion)
            └── Lesson Show
                    ├── Resource list (file_name · Download · [Delete])
                    └── Upload form → [file_name input] [file picker] [Upload]
                                          ├── success → Lesson Show (resource appended)
                                          └── error   → Lesson Show (flash error)
```

---

## Wireframe

```
Lesson: "Introduction to Rails"   (/courses/:id/sections/:id/lessons/:id)
──────────────────────────────────────────────────────────────────────────

  [Content / Video player ...]

  Attachments
  ───────────────────────────────────────────
  slides.pdf          Download · Delete
  exercise.zip        Download · Delete

  Upload new attachment
  ┌─────────────────────────┐  ┌──────────────────┐
  │ Display name (optional) │  │ Choose file...   │
  └─────────────────────────┘  └──────────────────┘
  [Upload]
```

---

## Key Decisions

- **Nested under `lessons`, not standalone** — a `LessonResource` has no meaning outside its lesson; shallow nesting keeps URLs readable (`/lessons/:lesson_id/lesson_resources`).
- **`only: [:create, :destroy]`** — no index/show/edit; resource list is rendered inline on the lesson page. No dedicated resource page needed in Phase 1.
- **Soft delete (`discard`) not hard delete** — consistent with the rest of the domain; lets the `before_discard` cascade on `Lesson` restore resources if the lesson is later un-discarded.
- **`file_name` defaults to original filename** — if the Teacher leaves the display-name field blank, fall back to `blob.filename` so the field is never blank in the UI.
- **CanCanCan scope via course ownership** — ability checks `lesson.section.course.teacher_id == user.id`; avoids loading a separate policy object for a simple ownership check.
