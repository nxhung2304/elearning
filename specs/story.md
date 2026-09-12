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
- [x] [Model] User — status enum (active/inactive/suspended/deleted), associations, i18n (en) ✅ 2026-05-16 [ERD → users](ERD.md#users)
- [x] [CRUD] User — Admin manage users (list, show, ban/unban) + Pagy ✅ 2026-05-16
- [x] [Fix] User — thêm discarded_at + include Discard::Model ✅ 2026-05-30
- [x] [Model] Role + UserRole — associations, i18n (en) ✅ 2026-05-17 [ERD → roles](ERD.md#roles) [ERD → user_roles](ERD.md#user_roles)
- [x] Gemfile: thêm cancancan — bỏ sidekiq, redis ✅ 2026-05-17
- [x] Setup: CanCanCan + Ability class ✅ 2026-05-17
- [x] Seeds: admin, teacher, student accounts với đúng role
- [x] [Model] Profile — validations, associations, i18n (en) ✅ 2026-05-29 [ERD → profiles](ERD.md#profiles)
- [x] [CRUD] Profile — Student/Teacher tự edit profile ✅ 2026-05-30
- [x] [Refactor] ApplicationRecord — rename `visible_columns` → `visible_columns`

---

## Week 3-4 | Courses + Sections + Lessons

- [x] [Model] CourseCategory — ancestry (nested), friendly_id (slug), i18n (en) ✅ 2026-05-31 [ERD → course_categories](ERD.md#course_categories)
- [x] [CRUD] CourseCategory — Admin CRUD, Pagy ✅ 2026-06-03
- [x] [Model] Course — enums (draft/published/archived), level, language, associations, i18n (en) ✅ 2026-06-21 [ERD → courses](ERD.md#courses)
- [x] [CRUD] Course — Teacher CRUD + search (title, category, level) + Pagy; Student browse ✅ 2026-06-13
- [x] [Model] Section — position, associations, i18n (en) ✅ 2026-06-**13** [ERD → sections](ERD.md#sections)
- [x] [CRUD] Section — Teacher CRUD (nested dưới Course)
- [x] [Refactor] Use manual columns in views instead of auto columns helper
- [x] [Model] Lesson — lesson_type enum (video/text/mixed), is_published, associations, i18n (en) [ERD → lessons](ERD.md#lessons)
- [x] [CRUD] Lesson — Teacher CRUD (nested dưới Section) + ActiveStorage upload video
- [x] [Model] LessonResource — associations, i18n (en) [ERD → lesson_resources](ERD.md#lesson_resources)
- [x] [CRUD] LessonResource — Teacher upload/delete file đính kèm

---

## Week 5-6 | Enrollment + Progress

- [x] [Model] EventLog — associations [ERD → event_logs](ERD.md#event_logs)
- [x] [Model] Enrollment — status enum, associations, business rules, i18n (en) [ERD → enrollments](ERD.md#enrollments)
- [x] [CRUD] Enrollment — Student enroll, danh sách khóa đã enroll (Pagy)
- [x] [Model] LessonProgress — watched seconds, position, associations, i18n (en) [ERD → lesson_progresses](ERD.md#lesson_progresses)
- [x] [CRUD] LessonProgress — Student update watched position, mark completed
- [ ] [Model] CourseProgress — progress_percentage, completed_lessons_count, associations, i18n (en) [ERD → course_progresses](ERD.md#course_progresses)
- [ ] Job: UpdateCourseProgressJob (Solid Queue)
- [ ] Web: Progress bar trên course page
- [ ] Minitest: integration tests enrollment flow + progress flow

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

---

## Week 10-13 | Quizzes + Reviews

- [ ] Setup: ViewComponent gem — add `view_component` to Gemfile; create `app/components/`; use for QuizQuestion, QuizOption (reused in teacher CRUD + student attempt), NotificationBell (Phase 3)
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
