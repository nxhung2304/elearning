## Status
- Review: Draft

## Metadata
- **Title:** Progress bar trên course page
- **Phase:** 1 - MVP
- **Issue:** #61
- **Story ref:** `specs/story.md` — Week 5-6 | Enrollment + Progress

## Description

Hiển thị tiến độ học của học viên trên `courses#show`, dựa trên `CourseProgress` (đã có model + `UpdateCourseProgressJob` từ issue #59/#28). Chỉ hiện với học viên đã enroll. Cập nhật real-time bằng Turbo Stream khi job chạy xong (không cần reload trang).

## Acceptance Criteria

- [ ] Học viên đã enroll thấy block progress bar trên `courses#show`, giữa info card và curriculum.
- [ ] Giáo viên / người không enroll không thấy block này.
- [ ] Bar hiện đúng `%` từ `course_progress.progress_percentage`, text "N/M bài đã hoàn thành" (N = `completed_lessons_count`, M = `enrollment.lesson_progresses.count`).
- [ ] Khi `completed_at` present, hiện badge "Hoàn thành" cạnh title.
- [ ] Sau khi học viên hoàn thành 1 bài học (trigger `UpdateCourseProgressJob`), bar tự cập nhật trên trang course đang mở, không cần reload (Turbo Stream).
- [ ] Style đúng convention `specs/design.md`: surface elevation (`bg-white shadow-sm ring-1 ring-slate-900/5 rounded-2xl`), emerald = primary/fill color.

## Implementation Checklist

- [ ] `app/views/courses/_progress_bar.html.erb` — partial nhận `course_progress:` (hoặc `enrollment:`), render header "Tiến độ" + `%`, bar (track `bg-slate-100` + fill `bg-emerald-600`, `rounded-full`, `transition-all`, width theo `progress_percentage`), text "N/M bài đã hoàn thành".
- [ ] `app/views/courses/show.html.erb` — chèn `render "courses/progress_bar", course_progress: @enrollment.course_progress` khi `enrolled`, giữa info card và `render "courses/curriculum"`; thêm `<%= turbo_stream_from @enrollment %>` khi `enrolled`.
- [ ] `app/models/course_progress.rb` — thêm `after_update_commit :broadcast_progress_update`, `broadcast_replace_to(enrollment, target: "course_progress", partial: "courses/progress_bar", locals: { course_progress: self })`.
- [ ] Badge "Hoàn thành" trong header khu vực title, dùng `shared/_status_badge` hoặc badge style tương tự, điều kiện `course_progress.completed_at.present?`.
- [ ] i18n: thêm key label "Tiến độ", "bài đã hoàn thành", "Hoàn thành" vào `config/locales/views/en.yml` (và vi nếu project có).
- [ ] Minitest: view/system test cho progress bar hiện/ẩn theo enrollment, đúng % và text; test broadcast (nếu có cách test Turbo Stream trong Minitest của project — kiểm tra convention hiện có trước khi viết).

## Key Decisions

1. **Chỉ hiện cho học viên đã enroll** (`enrolled = @enrollment.present?`) — giáo viên/quản lý không có `course_progress` cá nhân nên không hiện.
2. **Vị trí**: block riêng (surface elevation), giữa info card và curriculum trong `courses/show.html.erb` — không gộp vào `<dl>` info card hiện có vì khác pattern key-value.
3. **Real-time qua Turbo Stream**: broadcast từ `CourseProgress#after_update_commit` (không phải từ job) để không phụ thuộc nơi update — `broadcast_replace_to(enrollment, target: "course_progress", partial: "courses/progress_bar")`. View subscribe bằng `turbo_stream_from @enrollment` (stream signed riêng theo enrollment, không leak sang học viên khác).
4. **Mẫu số M giữ nguyên logic job đã merge**: `M = enrollment.lesson_progresses.count` (số bài học viên đã từng mở/tương tác, không phải tổng số bài của course — vì `LessonProgress` được tạo lazy qua `find_or_initialize_by` khi học viên mở bài). Không sửa `UpdateCourseProgressJob#calculate_percentage` trong issue này — giữ nguyên business logic, chỉ dùng dữ liệu có sẵn cho UI.
5. **Bar style**: custom Tailwind (2 div lồng nhau: track `h-2 w-full rounded-full bg-slate-100`, fill `h-2 rounded-full bg-emerald-600` với `style="width: {percentage}%"` + `transition-all`) — không dùng DaisyUI `progress` component để giữ nhất quán với helper/utility riêng của app (design.md §1, §4-5).
6. **Label**: header row `flex items-center justify-between` — label trái "Tiến độ", `{percentage.round}%` phải (emerald khi >0); dưới bar text-xs text-slate-400 "N/M bài đã hoàn thành".

## Decision Log
- 2026-09-27: Chốt scope + key decisions (visibility, vị trí, real-time Turbo Stream, mẫu số M, bar style, label) từ phiên feature-discuss — see Key Decisions above.
