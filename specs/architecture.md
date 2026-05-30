# Architecture

> 📎 [[20-Projects/elearning/Roadmap|Roadmap]] · [[20-Projects/elearning/ERD|ERD]] · [[20-Projects/elearning/story|Story]]

## Approach

- **Phase 1-4**: Rails Web App (MVC + ERB + Hotwire) — học full flow backend
- **Phase 5 (cuối)**: Expose API (Grape + grape-entity + devise-jwt) cho Mobile (Flutter)

---

## Tech Stack — Web Phase (1-4)

| Layer | Tech |
|---|---|
| Framework | Ruby on Rails 8.1 (full-stack mode) |
| Views | ERB + Hotwire (Turbo + Stimulus) |
| CSS | TailwindCSS + DaisyUI |
| Forms | simple_form |
| Video player | Plyr.js |
| Asset pipeline | Propshaft + importmap |
| Auth | Devise (session/cookie-based) |
| Authorization | CanCanCan |
| Search | Ransack |
| Pagination | Pagy |
| Soft delete | Discard (`discarded_at`) — áp dụng cho tất cả model chính |
| Database | PostgreSQL |
| Cache | Solid Cache (DB-backed, Rails 8 default) |
| Background jobs | Solid Queue (DB-backed, Rails 8 default) |
| Action Cable | Solid Cable (DB-backed, Rails 8 default) |
| File storage | ActiveStorage (local disk) |
| Image processing | image_processing |
| Email preview | letter_opener_web (development) |
| Testing | Minitest + FactoryBot + shoulda-matchers + shoulda-context + Capybara + Selenium |
| Linting | RuboCop (rubocop-rails-omakase) |
| Security | Brakeman + bundler-audit |
| Git hooks | Overcommit |
| Dev tools | annotaterb, pry-rails, faker |

> **Không dùng Redis** — thay bằng Solid Stack (Cache + Queue + Cable)

---

## Tech Stack — API Phase (5)

| Layer | Tech |
|---|---|
| API | Grape — `/api/v1/` |
| Serializer | grape-entity |
| Auth | Devise + devise-jwt |
| Token revocation | jwt_denylists table |

---

## Gemfile — Cần thêm

```ruby
gem "cancancan"
gem "ransack"
# DaisyUI qua importmap hoặc npm
```

## Gemfile — Cần bỏ

```ruby
# gem "sidekiq"   # thay bằng solid_queue
# gem "redis"     # không còn cần — dùng solid stack
```

---

## Patterns

- **Service Object** — business logic tách khỏi controller và model
- **Policy-based authorization** — CanCanCan `Ability` class, check mọi action
- **Soft delete** — Discard gem, filter `kept` scope mặc định
- **Background jobs** — Solid Queue cho heavy tasks (progress update, file processing)
- **Domain-oriented folder structure** — tổ chức theo domain

---

## Folder Structure

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── courses_controller.rb
│   ├── enrollments_controller.rb
│   └── lesson_progresses_controller.rb
│
├── models/
│   ├── user.rb
│   ├── course.rb
│   ├── section.rb
│   ├── lesson.rb
│   ├── enrollment.rb
│   └── ...
│
├── views/
│   ├── layouts/
│   │   └── application.html.erb   # TailwindCSS + DaisyUI
│   ├── courses/
│   ├── lessons/
│   └── enrollments/
│
├── services/
│   ├── courses/
│   │   ├── create_course_service.rb
│   │   └── publish_course_service.rb
│   ├── enrollments/
│   │   └── enroll_student_service.rb
│   └── progresses/
│       └── update_lesson_progress_service.rb
│
├── abilities/
│   └── ability.rb                 # CanCanCan
│
└── jobs/                          # Solid Queue
    └── update_course_progress_job.rb

test/
├── models/
├── controllers/
├── system/                        # Capybara system tests
├── services/
├── factories/                     # FactoryBot
└── test_helper.rb
```

---

## Soft Delete Convention (Discard)

```ruby
# Tất cả model chính include Discard::Model
class Course < ApplicationRecord
  include Discard::Model
  # discarded_at :datetime
  # default_scope -> { kept }
end

# Soft delete
course.discard

# Hard delete (nếu cần)
course.destroy

# Query
Course.kept      # chưa bị xóa (default)
Course.discarded # đã bị xóa mềm
```

---

## Authentication Flow (Devise)

```
POST /users/sign_in
→ Devise validates credentials
→ Session created (cookie-based)
→ Redirect to dashboard

DELETE /users/sign_out
→ Session destroyed
→ Redirect to login
```

---

## Authorization Flow (CanCanCan)

```
Request hits controller action
→ authenticate_user! (Devise)
→ authorize! :action, Resource (CanCanCan)
→ Ability class kiểm tra role-based rules
→ 403 / redirect nếu không có quyền
```

---

## Background Job Flow (Solid Queue)

```
Student completes lesson
→ Controller gọi UpdateLessonProgressService
→ Enqueue UpdateCourseProgressJob (Solid Queue)
→ Worker: tính progress_percentage
→ Update course_progresses table
```

---

## Hotwire Usage

```
Turbo Frames  → CRUD forms, nested resources (sections/lessons)
Turbo Streams → Realtime notification bell (Phase 4, via Solid Cable)
Stimulus      → Plyr.js video player init, UI interactions
```

---

## Testing Strategy

```
Minitest unit    → Models, Services (FactoryBot + shoulda)
Minitest functional → Controllers
Capybara system  → Critical user flows (enroll, watch lesson, submit quiz)
```

---

## Error Handling (Web)

- Flash messages cho user-facing errors
- Service Objects return `{ success: bool, error: "message" }`
- Rescue controller errors → redirect với notice

---

## Phase 5 — API (grape-entity)

```ruby
module Entities
  class Course < Grape::Entity
    expose :id, :title, :slug, :level
    expose :teacher, using: Entities::UserBasic
  end
end
```

Khi lên API:
1. Thêm Grape + grape-entity, mount `/api/v1/`
2. Migration: thêm `jti` vào users + tạo `jwt_denylists`
3. Thêm devise-jwt
4. Dùng lại toàn bộ Services — không viết lại business logic
5. Wrap response qua grape-entity
