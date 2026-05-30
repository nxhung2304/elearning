# Story

# Phase 1 — MVP (Web)
> 🎯 Deadline: **2026-06-28**

---

## Week 1-2 | Setup + Auth

- [x] Setup: Rails project, PostgreSQL, Solid Queue + Solid Cache + Solid Cable ✅ 2026-05-16
- [x] Setup: Devise (session-based), Views Login/Register/Logout ✅ 2026-05-16
- [x] Setup: Flash messages + error handling ✅ 2026-05-16
- [x] Setup: Discard gem convention (include Discard::Model cho model chính) ✅ 2026-05-17
- [x] Setup: Minitest + FactoryBot + shoulda + Capybara config ✅ 2026-05-16
- [x] [Model] User — status enum (active/inactive/suspended/deleted), associations, i18n (en) ✅ 2026-05-16
- [x] [CRUD] User — Admin manage users (list, show, ban/unban) + Pagy ✅ 2026-05-16
- [x] [Fix] User — thêm discarded_at + include Discard::Model ✅ 2026-05-30
- [x] [Model] Role + UserRole — associations, i18n (en) ✅ 2026-05-17
- [x] Gemfile: thêm cancancan — bỏ sidekiq, redis ✅ 2026-05-17
- [x] Setup: CanCanCan + Ability class ✅ 2026-05-17
- [x] Seeds: admin, teacher, student accounts với đúng role
- [x] [Model] Profile — validations, associations, i18n (en) ✅ 2026-05-29
- [x] [CRUD] Profile — Student/Teacher tự edit profile ✅ 2026-05-30
- [ ] [Refactor] ApplicationRecord — rename `displayable_columns` → `visible_columns`

---

### [Model] Role + UserRole

**Role columns:**
- `name` — string, not null
- `code` — string, not null, uniq (`student` | `teacher` | `admin`)

**UserRole columns:**
- `user_id` — not null, FK
- `role_id` — not null, FK
- Index trên `[user_id, role_id]` — uniq

**Associations:**
```ruby
# Role
has_many :user_roles
has_many :users, through: :user_roles

# User
has_many :user_roles
has_many :roles, through: :user_roles
```

**Minitest:**
- Happy: user có đúng role
- Edge: duplicate user_role → invalid, role code ngoài whitelist → invalid

---

### Setup: Authorization (CanCanCan)

> ⚠️ Cần `Role + UserRole` tồn tại trước bước này

1. Add `cancancan` gem, xoá `sidekiq` + `redis` khỏi Gemfile
2. Generate `Ability` model: `rails g cancan:ability`
3. Define base abilities theo role trong `app/abilities/ability.rb`

### Setup: Discard gem

- Add `discard` gem
- Include `Discard::Model` vào tất cả model chính (User, Course, Section, Lesson, Enrollment...)
- Default scope tự động filter `.kept` — không cần thêm scope thủ công

### Seeds

```ruby
# db/seeds.rb — tạo 3 roles + 3 accounts mẫu
# admin@example.com / teacher@example.com / student@example.com
```

---

### [Model] User ✅

**Columns:**
- `status` — not null, default: `active`
  - enum: `0:active` `1:inactive` `2:suspended` `3:deleted`
- Devise fields (email, encrypted_password, last_sign_in_at, sign_in_count)
- `discarded_at` — soft delete

**Minitest:**
- Happy case: status present, set all enum values
- Edge case: status null → invalid

**Actions (CRUD):**
- `Index` — Admin: list all users (Pagy)
- `Show` — show a user or current_user
- `Create` — new user, prevent duplicate email
- `Update` — update user, prevent duplicate email
- `Destroy` — soft delete (discard)
- Minitest controller:
  - Happy: access index/new/edit, perform create/update/destroy
  - Edge: 401 unauthorized, missing params, record not found

---

### [Model] Profile + [CRUD] Profile

**Columns:**
- `user_id` — not null, uniq FK (1-1 với User)
- `full_name` — string
- `avatar_url` — string (ActiveStorage)
- `bio` — text
- `phone` — string
- `discarded_at`

**Controller:**
- `Edit` / `Update` — Student/Teacher tự edit profile của mình
- CanCanCan: chỉ được sửa profile của chính mình

**Minitest:**
- Happy: update full_name, bio
- Edge: update profile của người khác → 403

---

## Week 3-4 | Courses + Sections + Lessons

- [ ] [Model] CourseCategory — parent_id (nested), associations, i18n (en)
- [ ] [CRUD] CourseCategory — Admin CRUD, Pagy
- [ ] [Model] Course — enums (draft/published/archived), level, language, associations, i18n (en)
- [ ] [CRUD] Course — Teacher CRUD + search (title, category, level) + Pagy; Student browse
- [ ] [Model] Section — position, associations, i18n (en)
- [ ] [CRUD] Section — Teacher CRUD (nested dưới Course)
- [ ] [Model] Lesson — lesson_type enum (video/text/mixed), is_published, associations, i18n (en)
- [ ] [CRUD] Lesson — Teacher CRUD (nested dưới Section) + ActiveStorage upload video
- [ ] [Model] LessonResource — associations, i18n (en)
- [ ] [CRUD] LessonResource — Teacher upload/delete file đính kèm

---

### [Model] CourseCategory + [CRUD]

**Columns:**
- `name` — not null
- `slug` — not null, uniq
- `parent_id` — nullable FK (self-referential, nested categories)
- `discarded_at`

**Associations:**
```ruby
belongs_to :parent, class_name: 'CourseCategory', optional: true
has_many :children, class_name: 'CourseCategory', foreign_key: :parent_id
has_many :courses
```

**Controller (Admin only):**
- CRUD đầy đủ + Pagy
- Ransack search by name

**Minitest:**
- Happy: create category, create sub-category (parent_id present)
- Edge: parent_id không tồn tại → invalid

---

### [Model] Course + [CRUD]

**Columns:**
- `teacher_id` — not null, FK → users
- `category_id` — FK → course_categories
- `title` — not null, uniq, index
- `slug` — not null, uniq, auto-generate từ title
- `description` — not null
- `thumbnail_url` — ActiveStorage
- `level` — enum: `beginner` `intermediate` `advanced`
- `language` — enum: `vi` `en`
- `price` — decimal(10,2), not null
- `total_lessons` — integer, denormalized (update qua job)
- `status` — enum: `draft` `published` `archived`
- `published_at`
- `discarded_at`

**Minitest model:**
- Happy: present values
- Edge: published_at set khi status != published, status ngoài enum, price âm, slug duplicate, title blank

**Controller:**
- Teacher: CRUD + search (Ransack: title, category, level) + Pagy
- Student: browse published courses
- Admin: list all, unpublish

**Minitest controller:**
- Happy: teacher CRUD, student browse
- Edge: 401, missing params, record not found, teacher sửa course của người khác → 403

---

### [Model] Section + [CRUD]

**Columns:**
- `course_id` — not null, FK
- `title` — not null
- `position` — integer, default: 0 (dùng `acts_as_list`)
- `discarded_at`

**Controller (nested dưới Course):**
- Index, Show, Create, Update, Destroy
- Chỉ Teacher sở hữu course mới được CRUD

**Minitest model:**
- Happy: set all values
- Edge: course_id null/not found, position < 0, title blank

**Minitest controller:**
- Happy: access + perform CRUD
- Edge: 401, missing params, record not found, action trên section của course khác → 403

---

### [Model] Lesson + [CRUD]

**Columns:**
- `section_id` — not null, FK
- `title` — not null
- `lesson_type` — enum: `video` `text` `mixed`
- `content` — text (required nếu type = text/mixed)
- `video_url` — ActiveStorage (required nếu type = video/mixed)
- `duration_seconds` — not null nếu video_url present
- `position` — not null, default: 0 (`acts_as_list`)
- `is_preview` — boolean, not null, default: false
- `is_published` — boolean, not null, default: false
- `published_at`
- `discarded_at`

**Validations:**
- `content` hoặc `video_url` phải có ít nhất 1
- `duration_seconds` required nếu `video_url` present
- `duration_seconds` không được set nếu `video_url` blank

**Minitest model:**
- Happy: set all values theo từng lesson_type
- Edge:
  - section_id null/not found
  - title blank
  - duration_seconds nil nhưng video_url present → invalid
  - duration_seconds có value nhưng video_url nil → invalid
  - content blank nhưng type = text → invalid

**Controller (nested dưới Section/Course):**
- Teacher CRUD + ActiveStorage upload video

---

### [Model] LessonResource + [CRUD]

**Columns:**
- `lesson_id` — not null, FK
- `file_name` — string, not null
- `file_url` — ActiveStorage (local)
- `discarded_at`

**Controller:**
- Teacher upload file đính kèm vào lesson
- Teacher delete (soft delete)

**Minitest:**
- Happy: upload file, list resources
- Edge: lesson_id null, upload file khi không phải owner lesson → 403

---

## Week 5-6 | Enrollment + Progress

- [ ] [Model] EventLog — associations
- [ ] [Model] Enrollment — status enum, associations, business rules, i18n (en)
- [ ] [CRUD] Enrollment — Student enroll, danh sách khóa đã enroll (Pagy)
- [ ] [Model] LessonProgress — watched seconds, position, associations, i18n (en)
- [ ] [CRUD] LessonProgress — Student update watched position, mark completed
- [ ] [Model] CourseProgress — progress_percentage, completed_lessons_count, associations, i18n (en)
- [ ] Job: UpdateCourseProgressJob (Solid Queue)
- [ ] Web: Progress bar trên course page
- [ ] Minitest: integration tests enrollment flow + progress flow

---

### [Model] EventLog

**Columns** (từ ERD):
- `user_id` — not null, FK
- `event_type` — string, not null
- `metadata` — jsonb
- `created_at`
- Không có `discarded_at` — audit log không được xóa

**Notes:**
- Không include Discard::Model
- Dùng để log actions quan trọng: ban/unban, enroll, payment...
- Minitest: happy case create với metadata hợp lệ

---

### [Model] Enrollment + [CRUD]

**Columns:**
- `user_id` — not null, index, FK
- `course_id` — not null, index, FK
- `status` — enum: `active` `completed` `expired` `revoked`
- `enrolled_at` — not null
- `expired_at` — nullable
- `discarded_at`
- *(payment_id thêm ở Phase 2)*

**Business rules:**
- Không enroll duplicate (uniq index trên [user_id, course_id])
- Không enroll course đã archived
- Không enroll nếu user bị suspended
- `expired_at` phải > `enrolled_at` nếu có

**Minitest model:**
- Happy: set all values
- Edge:
  - course_id null/not found
  - user_id null/not found
  - duplicate enrollment → invalid
  - expired_at < enrolled_at → invalid
  - status ngoài enum

**Controller:**
- Student: enroll course, list enrolled courses (Pagy)
- Modify Course controller: show progress nếu đã enroll

---

### [Model] LessonProgress + [CRUD]

**Columns:**
- `enrollment_id` — not null, FK
- `lesson_id` — not null, FK
- `completed` — boolean, not null, default: false
- `completed_at` — required nếu `completed = true`
- `total_watched_seconds` — integer (≤ lesson.duration_seconds)
- `current_position_seconds` — integer (≤ lesson.duration_seconds)

**Minitest model:**
- Happy: update watched seconds, mark complete
- Edge:
  - current_position_seconds nil nhưng total_watched_seconds present → invalid
  - total_watched_seconds > duration_seconds → invalid
  - completed_at nil khi completed = true → invalid

**Controller:**
- Student: update current_position_seconds (resume playback)
- Student: mark lesson completed

---

### [Model] CourseProgress

**Columns:**
- `enrollment_id` — not null, uniq FK (1-1 với Enrollment)
- `progress_percentage` — decimal, default: 0
- `completed_lessons_count` — integer, default: 0
- `completed_at` — set khi progress_percentage = 100

**Notes:**
- Không update trực tiếp — chỉ update qua `UpdateCourseProgressJob`
- Tự động issued Certificate khi completed_at set (Phase 3)

---

### Job: UpdateCourseProgressJob

```ruby
# app/jobs/update_course_progress_job.rb
# Trigger: sau mỗi LessonProgress mark complete
# Logic:
#   1. Đếm completed lessons trong enrollment
#   2. Tính progress_percentage = completed / total * 100
#   3. Update CourseProgress
#   4. Set completed_at nếu = 100%
```

---

---

# Phase 2 — Payments + Quizzes + Reviews (Web)
> 🎯 Deadline: **2026-08-23**

## Week 7-9 | Payments

- [ ] Migration: thêm payment_id (nullable) vào enrollments
- [ ] [Model] Payment — status enum, associations, i18n (en)
- [ ] [Model] PaymentTransaction — status enum, associations, i18n (en)
- [ ] Service: CreatePaymentService, ProcessPaymentService (mock flow)
- [ ] [CRUD] Payment — Student tạo payment, xem lịch sử (Pagy)
- [ ] Minitest: payment flow tests

**Payment columns:** user_id, amount, currency, provider, status (pending/processing/paid/failed/refunded/cancelled), paid_at
**PaymentTransaction columns:** payment_id, transaction_code, provider_response, status, raw_payload

---

## Week 10-13 | Quizzes + Reviews

- [ ] [Model] Quiz — passing_score, associations, i18n (en)
- [ ] [Model] QuizQuestion — question_type enum, position, associations, i18n (en)
- [ ] [Model] QuizOption — correct flag, associations, i18n (en)
- [ ] [CRUD] Quiz + QuizQuestion + QuizOption — Teacher CRUD
- [ ] [Model] QuizAttempt — status enum, score, associations, i18n (en)
- [ ] [Model] QuizAnswer — associations, i18n (en)
- [ ] [CRUD] QuizAttempt — Student làm quiz, submit, xem kết quả
- [ ] Service: SubmitQuizAttemptService (tính score, set status)
- [ ] [Model] Tag + CourseTag — associations, i18n (en)
- [ ] [CRUD] Tag — Admin CRUD, Pagy
- [ ] [Model] CourseReview — rating, associations, i18n (en)
- [ ] [CRUD] CourseReview — Student tạo review; search + Pagy trên course page
- [ ] Minitest: quiz + review tests

> 🚧 TODO: thêm implementation detail khi bắt đầu Phase 2

---

# Phase 3 — Notifications + Certificates + Analytics (Web)
> 🎯 Deadline: **2026-09-20**

## Week 14-16 | Notifications + Certificates

- [ ] [Model] Notification — notification_type, read_at, associations, i18n (en)
- [ ] Job: SendNotificationJob — trigger khi enroll, complete course
- [ ] [CRUD] Notification — bell icon, mark as read, Pagy
- [ ] [Model] Certificate — certificate_code, associations, i18n (en)
- [ ] Job: IssueCertificateJob — trigger khi course_progress = 100%
- [ ] Web: Trang certificate public (verify bằng code)
- [ ] Minitest: notification + certificate tests

## Week 17 | Analytics + Admin

- [ ] [Model] AdminLog — polymorphic target, associations, i18n (en)
- [ ] [CRUD] Admin: manage users (list, ban/unban) + Pagy
- [ ] [CRUD] Admin: manage courses (list, unpublish) + search + Pagy
- [ ] Web: Analytics dashboard — enrollment count, completion rate, revenue (mock)
- [ ] Minitest: admin + analytics tests

> 🚧 TODO: thêm implementation detail khi bắt đầu Phase 3

---

# Phase 4 — Advanced (Web)
> 🎯 Deadline: **2026-10-18**

## Week 18-19 | Hotwire + Action Cable + Wishlist

- [ ] Hotwire/Turbo: polish forms, nested resource updates không reload
- [ ] Action Cable: live notification bell (Turbo Streams)
- [ ] [Model] Wishlist — associations, i18n (en)
- [ ] [CRUD] Wishlist — Student add/remove, Pagy
- [ ] Minitest: tests cho wishlist + notification realtime

## Week 20-21 | Refactor + Performance

- [ ] Related courses: gợi ý theo category (simple query, không cần ML)
- [ ] Performance: N+1 audit, eager loading toàn bộ
- [ ] Query optimization (index review, explain analyze)
- [ ] Refactor + cleanup toàn bộ codebase
- [ ] Minitest: full coverage review

> 🚧 TODO: thêm implementation detail khi bắt đầu Phase 4

---

# Phase 5 — API (Mobile)
> 🎯 Deadline: **2026-11-15**
> Refactor Web sang API để Flutter consume

## Week 22-23 | API Setup + Auth + Courses

- [ ] Thêm Grape gem + grape-entity, mount `/api/v1/`
- [ ] Migration: thêm `jti` vào users + tạo `jwt_denylists`
- [ ] Thêm devise-jwt
- [ ] API: Auth (sign_in, sign_up, sign_out)
- [ ] API: Courses, Sections, Lessons (reuse Services + grape-entity)
- [ ] Minitest: request tests

## Week 24-25 | API Full

- [ ] API: Enrollments, LessonProgress, CourseProgress
- [ ] API: Quizzes, Reviews, Notifications, Certificates
- [ ] Swagger / API docs
- [ ] Minitest: full request coverage

> 🚧 TODO: thêm implementation detail khi bắt đầu Phase 5
