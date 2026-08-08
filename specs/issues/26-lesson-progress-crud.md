## Status
- Review: Merged

## Metadata
- **Title:** LessonProgress CRUD — student updates watched position & completion
- **Phase:** 1 - MVP (Week 5-6 | Enrollment + Progress)
- **Ref:** [ERD → lesson_progresses](../ERD.md#lesson_progresses) · depends on [#25 LessonProgress model](./25-model-lesson-progress.md)

## Description

Cho phép student đang xem lesson tự động lưu vị trí đang xem (`current_position_seconds`) và đánh dấu hoàn thành (`completed`). Endpoint là một `update` idempotent (upsert) trong namespace `my/` — video player (Stimulus) gọi PATCH khi `pause`/`ended`, và khôi phục vị trí khi `loadedmetadata`. Chỉ student đang enroll active vào course mới được cập nhật.

## Acceptance Criteria

- [ ] `PATCH /my/lessons/:lesson_id/progress` cập nhật `current_position_seconds` và/hoặc `completed`
- [ ] Lần cập nhật đầu tiên tạo mới progress record; các lần sau tái sử dụng đúng record (upsert theo `[enrollment, lesson]`, không tạo trùng)
- [ ] `completed: true` set `completed_at`; `completed: false` clear `completed_at` (đã có ở model callback)
- [ ] Position âm bị từ chối với `422` và không lưu gì
- [ ] Success trả `completed` (không body); validation fail trả `422` kèm `errors`
- [ ] Chỉ student enroll **active** vào course được update (CanCanCan); guest bị redirect sign in; student ngoài course bị redirect root
- [ ] Video player khôi phục vị trí xem lần trước khi mở lại lesson

## Implementation Checklist

- [ ] Route: `namespace :my` → `resources :lessons, only: []` với `resource :progress, only: :update, controller: "lesson_progresses"`
- [ ] `My::LessonProgressesController#update` — `load_and_authorize_resource :lesson`, `find_or_initialize_by(enrollment:)` qua `@lesson.enrollment_for(current_user)`, strong params `[:current_position_seconds, :completed]`
- [ ] `Ability` (student): `can :update, LessonProgress` scoped tới lessons thuộc course có enrollment active
- [ ] `Lesson#lesson_progress_for(user)` / `#enrollment_for(user)` helper để view load progress hiện tại
- [ ] `LessonsController#show` — set `@lesson_progress = @lesson.lesson_progress_for(current_user)`
- [ ] View `lessons/show` — `video_tag` với `data-controller="lesson-progress"`, url value + last position value, actions `pause`/`ended`/`loadedmetadata`
- [ ] Stimulus `lesson_progress_controller.js` — `sendProgress()` PATCH JSON kèm CSRF token; `restore()` set `currentTime`
- [ ] Controller test: upsert (create lần đầu / reuse lần sau), mark/un-mark completed, negative position 422, not-enrolled redirect, guest redirect

## User Flow

```
Course Detail
    └── Lesson Show (video player)
            ├── play/seek/pause  → PATCH progress (save current_position_seconds)
            ├── video ended      → PATCH progress
            ├── reopen lesson    → restore currentTime từ last position
            └── mark completed   → PATCH progress (completed: true)
```

## Flow Diagram

```
PATCH /my/lessons/:lesson_id/progress
    → authenticate (Devise)                → guest: redirect sign in
    → load_and_authorize_resource :lesson  → not enrolled: redirect root
    → enrollment = lesson.enrollment_for(current_user)
    → progress = lesson.lesson_progresses.find_or_initialize_by(enrollment:)
    → progress.update(current_position_seconds / completed)
        ├── valid   → 204 No Content
        └── invalid → 422 { errors: [...] }
```

## Key Decisions

- **Namespace `my/` + singular `resource :progress`** — progress là của current_user, không expose `id` trên URL; scope theo `lesson_id` + session user là đủ, tránh IDOR.
- **`find_or_initialize_by(enrollment:)` thay vì tách create/update** — client (video player) không cần biết record đã tồn tại chưa; một endpoint upsert đơn giản hơn cho JS. Unique index `[enrollment_id, lesson_id]` ở DB chặn race khi nhiều PATCH tới đồng thời.
- **`204 No Content` khi success** — request đến từ `fetch` trong Stimulus, không cần render gì; giảm payload cho các lần lưu vị trí liên tục.
- **Authorization scope theo enrollment *active*** — `enrolled_course_ids = user.enrollments.active.pluck(:course_id)`; enrollment bị huỷ/hết hạn không cho ghi progress.
- **`completed_at` do model callback quản** (`before_validation`, xem #25) — controller chỉ truyền `completed`, không tự set timestamp, tránh lệch logic giữa các call site.
