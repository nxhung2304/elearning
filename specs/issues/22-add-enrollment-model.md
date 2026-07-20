## Status
- Review: Approved

## Metadata
- **Title:** Enrollment Model — status enum, associations, business rules, i18n (en)
- **Phase:** 1 - MVP (Week 5-6 | Enrollment + Progress)
- **Ref:** [ERD → enrollments](../ERD.md#enrollments)

## Description

`Enrollment` liên kết một `User` (student) với một `Course` mà họ đã đăng ký học. Mỗi user chỉ được enroll vào 1 course tối đa 1 lần (unique index `[user_id, course_id]`). Model quản lý vòng đời enrollment qua `status` enum (active/completed/expired/revoked) và enforce các business rule về thời gian (`enrolled_at` không ở tương lai, `expired_at` bắt buộc và phải sau `enrolled_at` khi status là `expired`). Soft delete qua `Discard::Model` để giữ lịch sử enrollment.

## ERD

```
- id                          # bigint, PK
- user_id                     # bigint, not null, index, FK → users
- course_id                   # bigint, not null, index, FK → courses
- status                      # integer enum, not null, default: active
    - active
    - completed
    - expired
    - revoked
- enrolled_at                 # datetime, not null
- expired_at                  # datetime, nullable
- discarded_by_course         # boolean, default: false, null: false
- discarded_at                # datetime, nullable — soft delete
# uniq index on [user_id, course_id]
# payment_id KHÔNG có ở Phase 1 — thêm vào migration Phase 2
```

## Acceptance Criteria

- [ ] `Enrollment belongs_to :user` và `belongs_to :course`
- [ ] `status` là enum (`active: 0, completed: 1, expired: 2, revoked: 3`), default `active`
- [ ] `user_id` unique theo scope `course_id` (1 user chỉ enroll 1 lần / course)
- [ ] `status` bắt buộc (`presence: true`)
- [ ] `enrolled_at` bắt buộc và không được ở tương lai (`comparison: { less_than_or_equal_to: -> { Time.current } }`)
- [ ] Khi `status` là `expired`: `expired_at` bắt buộc và phải lớn hơn `enrolled_at`
- [ ] `Enrollment` include `Discard::Model` (soft delete, giữ lịch sử enrollment)
- [ ] `Course` có `before_discard` cascade discard tất cả enrollments của course (set `discarded_by_course: true` rồi discard)
- [ ] `Course` có `before_undiscard` chỉ restore enrollment có `discarded_by_course: true` (enrollment bị revoke/expire thủ công không bị restore theo)
- [ ] `User` discard **không** cascade sang enrollments — giữ nguyên lịch sử học tập của user
- [ ] i18n (en) cho model name + attributes (`status`, `enrolled_at`, `expired_at`, `discarded_at`)

## Implementation Checklist

- [ ] Migration `create_enrollments` — `user` + `course` references (not null, FK), `status` integer default 0, `enrolled_at` not null, `expired_at` nullable, `discarded_at` nullable, unique index `[user_id, course_id]`, index `discarded_at`
- [ ] `app/models/enrollment.rb` — `include Discard::Model`, `belongs_to :user`, `belongs_to :course`, `enum :status`, validations trên
- [ ] `User has_many :enrollments` / `Course has_many :enrollments` (nếu chưa có)
- [ ] i18n (en) — `enrollment` model name + attributes trong `config/locales/models/en.yml`
- [ ] FactoryBot factory `enrollment` (status active, enrolled_at hiện tại, expired_at nil)
- [ ] Minitest: association `belongs_to :user`/`:course`, uniqueness `user_id` scoped to `course_id`, presence `status`/`enrolled_at`, `enrolled_at` không ở tương lai, `expired_at` presence + so sánh khi status expired

## Flow Diagram

```
Student enroll vào course
    → Enrollment.create!(user:, course:, enrolled_at: Time.current)
        → validate uniqueness [user_id, course_id]
        → validate enrolled_at <= Time.current
        → status = :active (default)

status: active → completed → (course hoàn thành)
                → expired    (yêu cầu expired_at > enrolled_at)
                → revoked    (admin/teacher thu hồi quyền truy cập)
```

## Key Decisions

- Unique index `[user_id, course_id]` thay vì validate riêng ở tầng application — đảm bảo tính toàn vẹn dữ liệu ở tầng DB, tránh race condition khi 2 request enroll cùng lúc.
- `expired_at` chỉ bắt buộc khi `status == expired` (`if: -> { expired? }`) — các status khác (active/completed/revoked) không cần mốc thời gian này.
- `payment_id` chưa thêm ở Phase 1 — theo ERD, sẽ bổ sung migration riêng ở Phase 2 khi có Payment model, tránh thay đổi schema sớm khi chưa cần.
- Dùng `Discard::Model` thay vì hard delete — enrollment là dữ liệu lịch sử học tập (progress, quiz attempts phase sau sẽ tham chiếu), không nên xoá cứng.
