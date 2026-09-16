## Status
- Review: Pending

## Metadata
- **Title:** CourseProgress Model — progress_percentage, completed_lessons_count, associations, i18n (en)
- **Phase:** 1 - MVP (Week 5-6 | Enrollment + Progress)
- **Issue:** #57
- **Ref:** [ERD → course_progresses](../ERD.md#course_progresses)

## Description

`CourseProgress` là bản tổng hợp (denormalized, 1-1 với `Enrollment`) của toàn bộ `LessonProgress` thuộc một enrollment. Nó lưu `progress_percentage` và `completed_lessons_count` để render progress bar mà không phải tính lại từ `lesson_progresses` mỗi request, và đánh dấu `completed_at` khi course hoàn thành 100%. Việc tính toán được thực hiện bởi `UpdateCourseProgressJob` (task riêng) gọi vào `CourseProgress#recalculate!`.

## ERD

```
- id                          # bigint, PK
- enrollment_id               # bigint, not null, uniq, FK → enrollments (1-1)
- progress_percentage         # decimal, not null, default: 0
- completed_lessons_count     # integer, not null, default: 0
- completed_at                # datetime, nullable — set khi progress_percentage = 100
```

## Acceptance Criteria

- [ ] `CourseProgress belongs_to :enrollment`
- [ ] `Enrollment has_one :course_progress` (`dependent: :destroy`), tự động tạo record khi `Enrollment` được tạo
- [ ] `progress_percentage` decimal not null, default `0`, trong khoảng `0..100`
- [ ] `completed_lessons_count` integer not null, default `0`, `>= 0`
- [ ] `completed_at` nullable; được set khi `progress_percentage == 100`, reset về `nil` khi tụt xuống dưới 100%
- [ ] `CourseProgress#recalculate!` tính lại `completed_lessons_count` (từ `enrollment.lesson_progresses.completed.count`) và `progress_percentage` (`completed / course.total_lessons * 100`, làm tròn 2 chữ số; `0` nếu `total_lessons` = 0) rồi update
- [ ] `LessonProgress` có `scope :completed, -> { where(completed: true) }`
- [ ] i18n (en) cho model name + attributes (`progress_percentage`, `completed_lessons_count`, `completed_at`)

## Implementation Checklist

- [ ] Migration `create_course_progresses` — `enrollment` reference (not null, FK, unique index), `progress_percentage` decimal(5,2) not null default 0, `completed_lessons_count` integer not null default 0, `completed_at` datetime nullable
- [ ] `app/models/course_progress.rb` — `belongs_to :enrollment`, validations trên, `recalculate!` instance method
- [ ] `app/models/enrollment.rb` — thêm `has_one :course_progress, dependent: :destroy` + callback tạo `course_progress` khi enrollment được tạo
- [ ] `app/models/lesson_progress.rb` — thêm `scope :completed, -> { where(completed: true) }`
- [ ] i18n (en) — `course_progress` model name + attributes trong `config/locales/models/en.yml`
- [ ] FactoryBot factory `course_progress` (progress_percentage 0, completed_lessons_count 0; trait `:completed` set `progress_percentage: 100`, `completed_lessons_count` = course total_lessons, `completed_at`)
- [ ] Minitest: association `belongs_to :enrollment`, uniqueness `enrollment_id`, numericality `progress_percentage` trong `0..100`, `completed_lessons_count >= 0`, `recalculate!` tính đúng percentage/completed_lessons_count/completed_at (bao gồm case `total_lessons = 0` và case tụt xuống dưới 100% reset `completed_at`)

## Flow Diagram

```
LessonProgress#completed thay đổi (true/false)
    → enqueue UpdateCourseProgressJob(enrollment)
        → enrollment.course_progress.recalculate!
            → completed = enrollment.lesson_progresses.completed.count
            → total = enrollment.course.total_lessons
            → progress_percentage = total.positive? ? completed * 100.0 / total : 0
            → completed_at = Time.current nếu progress_percentage == 100, ngược lại nil
```

## Key Decisions

- `CourseProgress` được tạo cùng lúc với `Enrollment` (không lazy tạo trong job) — đảm bảo quan hệ 1-1 luôn tồn tại, tránh nil-check ở view/job khi hiển thị progress trước khi có lesson nào completed.
- Logic tính toán nằm trong `CourseProgress#recalculate!`, không nằm trong `UpdateCourseProgressJob` — job chỉ enqueue và gọi method, việc tính toán dễ unit test độc lập với job/queue.
- `LessonProgress` được bổ sung `scope :completed` thay vì query `where(completed: true)` inline trong `CourseProgress` — tái sử dụng được ở nơi khác (vd hiển thị danh sách lesson đã hoàn thành).
- `completed_at` reset về `nil` khi `progress_percentage` tụt xuống dưới 100% (vd teacher thêm lesson mới vào course đã hoàn thành) — phản ánh đúng trạng thái hiện tại, cùng pattern với `LessonProgress#completed_at`.
- Không dùng `Discard::Model` — progress không cần soft delete; khi enrollment bị xoá thì course_progress đi theo (`dependent: :destroy`).

## Decision Log
- 2026-09-12: Chốt thiết kế CourseProgress model (creation timing, calc ownership, query style, completed_at reset behavior) — see Key Decisions above.
