## Status
- Review: Approved

## Metadata
- **Title:** LessonProgress Model — watched seconds, position, associations, i18n (en)
- **Phase:** 1 - MVP (Week 5-6 | Enrollment + Progress)
- **Issue:** #53
- **Ref:** [ERD → lesson_progresses](../ERD.md#lesson_progresses)

## Description

`LessonProgress` theo dõi tiến độ học của một student trên từng lesson trong phạm vi một enrollment. Nó ghi lại vị trí đang xem (`current_position_seconds`), tổng thời gian đã xem (`total_watched_seconds`) và trạng thái hoàn thành (`completed` + `completed_at`). Đây là nguồn dữ liệu để tính `CourseProgress` (task kế tiếp) và render progress bar trên course page.

## ERD

```
- id                          # bigint, PK
- enrollment_id               # bigint, not null, FK → enrollments
- lesson_id                   # bigint, not null, FK → lessons
- completed                   # boolean, not null, default: false
- completed_at                # datetime, nullable (required if completed = true)
- total_watched_seconds       # integer, nullable
- current_position_seconds    # integer, nullable
```

## Acceptance Criteria

- [ ] `LessonProgress belongs_to :enrollment` và `belongs_to :lesson`
- [ ] `Enrollment has_many :lesson_progresses` / `Lesson has_many :lesson_progresses`
- [ ] `completed` là boolean, not null, default `false`
- [ ] `completed_at` bắt buộc khi `completed == true`, ngược lại nullable
- [ ] `total_watched_seconds` và `current_position_seconds` nullable, nếu có phải `>= 0`
- [ ] Một enrollment chỉ có tối đa 1 progress record / lesson (unique `[enrollment_id, lesson_id]`)
- [ ] i18n (en) cho model name + attributes (`completed`, `completed_at`, `total_watched_seconds`, `current_position_seconds`)

## Implementation Checklist

- [ ] Migration `create_lesson_progresses` — `enrollment` + `lesson` references (not null, FK), `completed` boolean not null default false, `completed_at` datetime nullable, `total_watched_seconds` / `current_position_seconds` integer nullable, unique index `[enrollment_id, lesson_id]`
- [ ] `app/models/lesson_progress.rb` — `belongs_to :enrollment`, `belongs_to :lesson`, validations trên
- [ ] i18n (en) — `lesson_progress` model name + attributes trong `config/locales/models/en.yml`
- [ ] FactoryBot factory `lesson_progress` (completed false, watched/position nil; trait `:completed` set `completed: true` + `completed_at`)
- [ ] Minitest: association `belongs_to :enrollment`/`:lesson`, uniqueness `enrollment_id` scoped to `lesson_id`, `completed_at` presence khi completed, numericality `>= 0` cho watched/position

## Flow Diagram

```
Student xem lesson
    → LessonProgress.find_or_create_by(enrollment:, lesson:)
        → update current_position_seconds (tua/tiếp tục)
        → tăng total_watched_seconds
    → khi xem hết / bấm "mark completed"
        → completed = true, completed_at = Time.current
        → (trigger CourseProgress recompute — task sau)
```

## Key Decisions

- Progress gắn với `enrollment_id` (không phải `user_id` trực tiếp) — cùng một user re-enroll một course sau này sẽ có bộ progress riêng, không lẫn với lần học trước.
- `completed_at` chỉ required khi `completed == true` (`if: -> { completed }`) — record đang học dở không cần mốc thời gian này. Migration để `completed_at` nullable để khớp business rule (ERD hiện ghi not null — dùng nullable là đúng semantics).
- Unique index `[enrollment_id, lesson_id]` ở tầng DB để tránh tạo trùng progress khi nhiều request cập nhật vị trí xem đồng thời.
- Không dùng `Discard::Model` — progress không cần soft delete; khi enrollment/lesson bị xoá thì progress đi theo (`dependent: :destroy`).
