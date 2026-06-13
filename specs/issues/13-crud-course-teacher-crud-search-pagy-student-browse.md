## **Status:**
- Review: Approved ✅
- PR: Merged ✅ 2026-06-13

## Metadata
- **Title:** [CRUD] Course — Teacher CRUD + search (title, category, level) + Pagy; Student browse
- **Phase:** Phase 1 — MVP (Web) · Week 3-4
- **GitHub Issue:** #28

---

## Description

Implement the `CoursesController` with two distinct audiences:
- **Teacher**: full CRUD on their own courses, Ransack search by title / category / level, Pagy pagination.
- **Student**: browse index of `published` courses only (read-only).
- **Admin**: list all courses (any status), can unpublish.

The `Course` model already exists (`app/models/course.rb`). This task is purely controller + views + authorization.

---

## Acceptance Criteria

- [ ] Teacher can create a new course (title, description, category, level, language, price)
- [ ] Teacher can edit and update their own course
- [ ] Teacher can discard (soft-delete) their own course
- [ ] Teacher cannot edit/destroy a course owned by another teacher (403)
- [ ] Teacher index lists only their courses, supports Ransack search by title, category, level
- [ ] Pagy pagination applied on all index actions
- [ ] Student index lists only `published` + `kept` courses
- [ ] Admin index lists all courses regardless of status; admin can unpublish a course
- [ ] Unauthenticated request redirected to login (Devise)
- [ ] All controller actions covered by Minitest (happy path + edge cases)

---

## Implementation Checklist

- [ ] Add `resources :courses` to `config/routes.rb` with member routes: `patch :publish`, `patch :archive` (Teacher/Admin), `patch :unpublish` (Admin)
- [ ] Create `app/controllers/courses_controller.rb` with `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`
- [ ] Add `publish`, `archive` actions (Teacher/Admin); `unpublish` action (Admin only)
- [ ] Add `before_action :set_teacher, only: %i[new create]` — sets `@course.teacher = current_user`
- [ ] Wire `load_and_authorize_resource` (CanCanCan) — scope per role
- [ ] Update `app/abilities/ability.rb`: Teacher manages own courses; Student reads published; Admin manages all
- [ ] Create views: `index`, `show`, `new`/`edit` (shared `_form` partial)
- [ ] Add Ransack search form on teacher index (title, category_id, level)
- [ ] Add Pagy on all index queries
- [ ] Add i18n keys to `config/locales/en.yml`
- [ ] Write `test/controllers/courses_controller_test.rb`
- [ ] Run `bin/rubocop` and `bin/rails test` — all green

---

## Step-by-step Guide

**Files to create/modify:**
- `config/routes.rb` — add `resources :courses` + member `patch :unpublish`
- `app/controllers/courses_controller.rb` — new file
- `app/abilities/ability.rb` — add Course rules per role
- `app/views/courses/index.html.erb` — role-aware index
- `app/views/courses/show.html.erb`
- `app/views/courses/_form.html.erb` — shared form partial
- `app/views/courses/new.html.erb` + `edit.html.erb`
- `config/locales/en.yml` — add course flash messages
- `test/controllers/courses_controller_test.rb` — new file
- `test/factories/courses.rb` — FactoryBot factory (if not yet present)

**Key decisions:**
- **Ability scoping:** Teacher gets `cannot :read, Course` (overrides `can :read, :all`) + `can :manage, Course, teacher_id: user.id`. Teacher is content-creator only — cannot view other teachers' courses. `Course.accessible_by(current_ability)` then correctly scopes to own courses only.
- **teacher_id on create:** `before_action :set_teacher, only: %i[new create]` runs after `load_and_authorize_resource` and sets `@course.teacher = current_user`. Never sourced from params.
- **Status transitions via explicit actions only:** `status` is NOT in `course_params`. Teacher uses "Publish" (`patch :publish`) and "Archive" (`patch :archive`) buttons. Admin uses "Unpublish" (`patch :unpublish`). Publish is direct — no approval gate. Each action delegates to the model callback (`set_published_at`) which manages `published_at` automatically.
- **Ransack whitelisting:** `ApplicationRecord#ransackable_attributes` already returns all column names minus a denylist — `title`, `level`, `category_id` are all covered. No per-model override needed on `Course`.
- **Pagy page size:** Global default `Pagy::DEFAULT[:limit] = 20` — no per-controller override.
- **Redirects:** `create`/`update` → `course_url(@course)`; `destroy`/`publish`/`archive`/`unpublish` → `courses_url`.
- **Teacher on other courses' show:** 403 via `CanCan::AccessDenied` → redirect to root. Teacher scope is their own catalog only.
- **Student on non-published show:** 403 via `CanCan::AccessDenied` → redirect to root. No custom 404.
- **Single `index.html.erb`** with role-based conditionals — Teacher gets search form + edit/publish/archive/delete buttons; Student gets browse-only list; Admin gets full list with unpublish button.
- **`load_and_authorize_resource` + Ransack pattern:** `load_and_authorize_resource` sets `@courses = Course.accessible_by(current_ability)` (Discard default scope `.kept` already applied). Index chains Ransack: `@q = @courses.ransack(params[:q]); @pagy, @courses = pagy(@q.result(distinct: true))`.
- No `thumbnail_url` upload in this issue — ActiveStorage for thumbnails is deferred.

**Flow:**
```
Request → authenticate_user! → load_and_authorize_resource → CoursesController
                                        |
              ┌─────────────────────────┼──────────────────────┐
              │                         │                       │
           Teacher                   Student                 Admin
    can :manage, Course            can :read, Course      can :manage, :all
    where teacher_id=me            where status=published  all kept courses
              │                         │                       │
    CRUD + publish/archive           index/show           index + unpublish
    Ransack(title,category,level)      Pagy                   Pagy
    Pagy (limit 20)                    │                       │
              │                         │                       │
    create/update → show            render index            render index
    destroy → index

Status transitions (explicit action buttons only):
  draft ──[publish]──▶ published ──[archive]──▶ archived
    ▲                      │
    └──────[unpublish]──────┘   (admin only)
  draft ◀──[archive]──────────────────────────────────────
```

**Non-obvious snippets:**
```ruby
# app/controllers/courses_controller.rb

load_and_authorize_resource

# Chains Ransack + Pagy on top of CanCanCan-scoped @courses
def index
  @q = @courses.ransack(params[:q])
  @pagy, @courses = pagy(@q.result(distinct: true))
end

# Sets teacher_id from current_user — never from params
def set_teacher
  @course.teacher = current_user
end

# title, description, category_id, level, language, price only — status excluded
def course_params
end

# Teacher/Admin: draft → published
def publish
end

# Teacher/Admin: any → archived
def archive
end

# Admin only: published → draft
def unpublish
end
```

```ruby
# app/abilities/ability.rb — Teacher block (replaces current can :read, :all block)

elsif user.teacher?
  can :read, :all
  cannot :read, Course                         # override — teacher sees only own
  can :manage, Course, teacher_id: user.id
  can :update, Profile, user_id: user.id
elsif user.student?
  can :read, User, id: user.id
  can :read, Course, status: Course.statuses[:published]
  can :update, Profile, user_id: user.id
```

```ruby
# test/controllers/courses_controller_test.rb

setup do
  @teacher = create(:user, :teacher)
  @other_teacher = create(:user, :teacher)
  @student = create(:user, :student)
  @admin = create(:user, :admin)
  @course = create(:course, teacher: @teacher)
  @published_course = create(:course, :published, teacher: @teacher)
end

test "teacher can create own course" do
end

test "teacher cannot update another teacher course" do
end

test "teacher can publish their own course" do
end

test "teacher can archive their own course" do
end

test "student can browse published courses" do
end

test "student cannot access new course form" do
end

test "student cannot view draft course show page" do
end

test "admin can unpublish a published course" do
end

test "unauthenticated user is redirected to login" do
end
```

---

## Notes

- `CourseCategory` uses `ancestry` — preload with `CourseCategory.kept.all` in a `before_action` for the form select; avoid N+1.
- `ApplicationRecord#ransackable_attributes` already covers all `courses` columns — no per-model Ransack override needed.
- `total_lessons` is denormalized and updated via job (Phase 1 week 5-6) — display on show, never expose in the form.
- `cannot :read, Course` in Teacher's block must come **after** `can :read, :all` — CanCanCan evaluates in order, last matching rule wins for `accessible_by` queries.
- Factory `discarded_at` was fixed to `nil` — tests using `Course.kept` now find factory records by default.
