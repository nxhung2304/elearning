## Goal

Build an online learning platform where:

- teachers can create and manage courses
- students can enroll and learn
- system tracks learning progress

The project aims to simulate a real-world backend system instead of a simple CRUD application.

---

# Roles

## Student

Can:

- browse & search courses
- enroll into courses
- watch lessons
- track learning progress

---

## Teacher

Can:

- create courses
- manage sections
- manage lessons
- publish courses

---

## Admin

Can:

- manage users
- manage courses
- moderate platform content

---

# Core Features

## Authentication

Users can:

- register
- login
- logout

Token-based via JWT (devise-jwt). Token revoked on logout.

---

## Course Management

Teachers can:

- create course
- update course
- publish/unpublish course

Each course contains:

- sections
- lessons (video / text / mixed)

---

## Enrollment

Students can enroll into courses.

Rules:

- cannot enroll twice
- archived courses cannot be enrolled
- suspended users cannot enroll

---

## Lesson Learning

Students can:

- watch lesson videos
- continue from last watched position
- mark lessons as completed

System tracks:

- watched progress (seconds)
- completed lessons
- learning progress percentage

---

## Search & Filter

Students can browse courses by:

- keyword (title, description)
- category
- level (beginner / intermediate / advanced)
- language

---

## Pagination

All list endpoints support pagination:

- `page` and `per_page` params
- response includes `meta.total`, `meta.page`, `meta.per_page`

---

# Non-Functional Requirements

## Performance

- API response < 300ms cho các endpoint thông thường
- Pagination bắt buộc cho tất cả list endpoints
- Eager loading để tránh N+1 queries

## Security

- JWT token revocation khi logout (via jwt_denylist)
- Authorization check mọi action qua CanCanCan
- Không expose sensitive fields (encrypted_password, jti)
- Strong params validation toàn bộ input

## Scalability

- Background jobs (Sidekiq) cho heavy tasks: tính progress, xử lý media
- Redis caching cho data ít thay đổi (course info, categories)

## Error Handling

Tất cả lỗi trả về format chuẩn:

```json
{
  "error": {
    "code": "unauthorized",
    "message": "You are not authorized to perform this action"
  }
}
```

Common error codes:

| Code | HTTP Status | Mô tả |
|---|---|---|
| `unauthorized` | 401 | Chưa đăng nhập |
| `forbidden` | 403 | Không có quyền |
| `not_found` | 404 | Resource không tồn tại |
| `validation_failed` | 422 | Dữ liệu không hợp lệ |
| `conflict` | 409 | Duplicate (e.g. enroll twice) |
| `internal_error` | 500 | Lỗi hệ thống |

---

## File / Video Storage

- Dùng **ActiveStorage** lưu local (development)
- Video lessons upload qua API, lưu local disk
- Media processing (nếu cần) chạy qua Sidekiq background job
- Có thể migrate lên S3 sau khi deploy production

---

## Rate Limiting

- Apply tại Grape middleware
- Login endpoint: max 10 requests/phút/IP
- Upload endpoint: max 5 requests/phút/user

---

# MVP Scope

Included:

- users
- roles
- courses
- sections
- lessons
- enrollments
- lesson progresses

Excluded (Phase 2+):

- payments
- quizzes
- certificates
- notifications
- realtime learning
- recommendation system

---

# Core User Flows

## Teacher Creates Course

```text
Teacher login
→ create course
→ create sections
→ create lessons (upload video)
→ publish course
```

---

## Student Enrollment

```text
Student browse / search course
→ enroll into course
→ access lessons
```

---

## Student Learning

```text
Student open lesson
→ watch video
→ progress saved (current_position_seconds)
→ continue watching later
→ complete lesson
→ course progress updated (background job)
```

---

# Success Criteria

- Teacher can publish courses successfully
- Student can enroll into courses
- Student progress is tracked correctly
- Learning progress persists across sessions
- Authorization prevents unauthorized actions
- API returns consistent error format
- All list endpoints paginated

---

# Technical Goals

The project should practice:

- RESTful API design (Grape, /api/v1/)
- Database design & query optimization
- JWT Authentication (Devise + devise-jwt)
- Authorization (CanCanCan)
- Validation & error handling
- Testing (RSpec)
- Service object architecture
- Background jobs (Sidekiq)
- Real-world backend patterns
