## Metadata
- Issue number: #51

## Status
- PR: Draft

## Content

[UI/UX] Redesign màn Course / Section / Lesson từ CRUD-scaffold sang **learner-facing curriculum**.

Hiện tại Section & Lesson đang render dưới dạng bảng quản trị (data grid): cột `position`, `created_at`, `updated_at`, nút `Show / Edit / Delete`, và `courses/show` + `sections/show` + `lessons/show` đổ **toàn bộ** attribute DB ra `<dl>`. Nhìn như trang admin, không phải trang học. Issue này gộp cấu trúc Section + Lesson thành **một trang curriculum dạng accordion** trong `courses/show` (giống Udemy/Coursera), tách rõ hành động quản trị (teacher) khỏi trải nghiệm xem/học (student).

## Scope

**In scope**
- `courses/show` (tab Overview): thay khối `<dl>` đổ hết attribute + bảng Sections bằng:
  - Header khóa học gọn: title, teacher, status badge, mô tả, meta hữu ích (level, language, price, số bài / tổng thời lượng). **Bỏ** `created_at` / `updated_at` khỏi màn student.
  - **Curriculum accordion**: mỗi Section là 1 nhóm gập/mở; bên trong là danh sách Lesson dạng dòng (icon theo `lesson_type` + title + thời lượng + trạng thái preview/khoá). Click Lesson → đi thẳng `lessons#show`.
- `lessons/show`: bố cục learner-first — nội dung/video lên đầu, không đổ attribute grid. Ẩn `position` / `is_published` / `created_at` / `updated_at` khỏi student.
- Ẩn toàn bộ action quản trị (New / Edit / Delete section & lesson) sau `can?(:manage, ...)` và gom vào icon-button / overflow menu thay vì bày kín màn.
- Empty state thân thiện khi Section/Lesson trống.

**Out of scope (giữ nguyên, không xoá)**
- Bảng CRUD `sections#index` và `lessons#index` **vẫn còn** làm màn quản trị sâu cho teacher, nhưng de-emphasize: chỉ vào từ menu "Manage" chứ không phải đường đi chính. Không redesign 2 màn này trong issue.
- Không tạo route/controller học tập riêng cho student (đó là hướng "tách 2 luồng" — không chọn). Curriculum accordion nằm ngay trong `courses/show` cho cả 2 vai trò, khác nhau ở chỗ hiện/ẩn action.

**Deferred (không làm ở issue này)**
- **Per-lesson completion / progress bar**: chưa có `CourseProgress` (roadmap Week 5-6). Nên **không** vẽ checkmark "đã học" hay % hoàn thành. Trạng thái lesson hiện chỉ gồm: `preview` (badge), `locked` (chưa enroll + không phải preview), `available`.
- Reorder lesson/section bằng drag-drop.

## Key decisions

1. **Accordion dùng native `<details>` / `<summary>`, không JS.** Khớp ethos "no Node/webpack", accessible sẵn, style được bằng Tailwind `open:` variant + `[&_svg]:open:rotate-180` cho chevron. Mở sẵn Section đầu tiên (`open` attribute trên section index 0). Nếu sau này cần "mở 1 / đóng còn lại" mới thêm Stimulus controller — chưa cần bây giờ.

2. **Một partial curriculum tái sử dụng.** Tạo `app/views/courses/_curriculum.html.erb` (nhận `course:`, `sections:`, `enrolled:`, `can_manage:`) + `app/views/lessons/_row.html.erb` (dòng lesson trong accordion, khác `_lesson.html.erb` cũ vốn là `<tr>` cho bảng). Giữ `_lesson.html.erb`/`_table.html.erb` cho màn teacher index.

3. **Lock/preview logic ở view, dựa dữ liệu sẵn có.** Không đổi schema:
   - Lesson hiện nếu `is_published` (teacher `can?(:manage)` thì thấy cả draft, gắn badge "Draft").
   - `enrolled = @course.enrollments.active.exists?(user: current_user)` (đã có `@enrollment` trong `CoursesController#show`).
   - Lesson **clickable** khi `enrolled || lesson.is_preview || can_manage`. Ngược lại render dạng khoá (icon 🔒, không phải link).

4. **Trạng thái quản trị gom vào overflow, không phá layout.** Với `can?(:manage, course)`:
   - Nút "New section" ở cuối accordion (icon `+`, subtle).
   - Mỗi section header có icon-button Edit + kebab (Delete / Add lesson).
   - Mỗi lesson row có Edit/Delete dạng icon chỉ hiện khi hover (`group-hover`).
   - Dùng `button_classes(:icon)` / `:icon_primary` / `:icon_danger` từ `ApplicationHelper`, đúng convention Material đã có.

5. **Tổng thời lượng & số bài tính ở helper, tránh N+1.** Preload trong controller:
   ```ruby
   # CoursesController#show
   @sections = @course.sections.kept.order(:position)
                       .includes(:lessons)
   ```
   Thêm helper `section_duration(section)` (sum `duration_seconds` các lesson kept & published, format `"h m"`), `section_lesson_count(section)`. Cân nhắc dùng `lessons.kept` đã load sẵn để không query lại.

6. **Ẩn attribute admin khỏi màn học, không xoá dữ liệu.** `courses/show`, `sections/show`, `lessons/show` bỏ hiển thị `position`, `created_at`, `updated_at`, `is_published` (student). Các field này vẫn xem được ở màn teacher index/edit.

## Flow diagram

```
courses#show (Overview tab)
 ├─ Header: title · teacher · status · level/language/price · N bài · tổng thời lượng
 └─ Curriculum (partial _curriculum)
     ▸ Section 1  "Giới thiệu"          3 bài · 25m      [✎] [⋮]  ← action chỉ khi can_manage
        ├─ ▶ Cài đặt môi trường   video · 8m            → lessons#show
        ├─ 📄 Bài đọc thêm        text            (preview badge)
        └─ 🔒 Deploy              video · 12m     (locked: chưa enroll, không preview)
     ▸ Section 2 ...
     [+ New section]  ← chỉ khi can_manage

lessons#show (learner-first)
 ├─ Breadcrumb: Course › Section › Lesson
 ├─ Nội dung chính: video player (video/mixed) hoặc content (text/mixed)
 ├─ Attachments (lesson_resources) — giữ như hiện tại
 ├─ Upload attachment form — chỉ khi can_manage
 └─ [Prev] [Back to curriculum] [Next]   ← điều hướng trong khoá (Next/Prev optional, xem Notes)
```

## Files (dự kiến)

| File | Việc |
|---|---|
| `app/views/courses/show.html.erb` | Bỏ `<dl>` full-attribute + bảng sections; render header gọn + `courses/curriculum` |
| `app/views/courses/_curriculum.html.erb` | **New** — accordion sections |
| `app/views/lessons/_row.html.erb` | **New** — dòng lesson trong accordion (icon type + duration + lock/preview) |
| `app/views/lessons/show.html.erb` | Bố cục learner-first, ẩn attribute admin |
| `app/views/sections/show.html.erb` | (optional) redirect/link về curriculum, hoặc để nguyên cho teacher |
| `app/controllers/courses_controller.rb` | `#show` preload `@sections` với `includes(:lessons)` |
| `app/helpers/application_helper.rb` (hoặc `courses_helper.rb`) | `section_duration`, `section_lesson_count`, `lesson_type_icon`, `lesson_locked?` |
| `config/locales/views/en.yml` | Key mới: curriculum labels, preview/locked, empty states |

## Notes

- **Icon theo `lesson_type`**: video = ▶ (play), text = 📄 (document), mixed = layers — inline SVG Material outline (`stroke="currentColor"`, `viewBox="0 0 24 24"`, `stroke-width="2"`), không dùng emoji trong markup thật (emoji ở đây chỉ để mô tả).
- **Ability**: xác nhận student có `can :read, Lesson` cho lesson published/preview của course đã enroll — kiểm tra `app/models/ability.rb` trước khi làm link. Nếu chưa có rule phù hợp thì phần lock logic ở view vẫn an toàn (chỉ ẩn link), nhưng cần đảm bảo `lessons#show` không cho truy cập lesson khoá bằng URL trực tiếp.
- **Next/Prev lesson**: tính bằng thứ tự phẳng (section.position, lesson.position). Optional — nếu tốn thời gian thì tách issue sau, ưu tiên accordion trước.
- **Duration format**: `duration_seconds` có thể `nil` (text lesson) → hiển thị "—". Section duration bỏ qua lesson `nil`.
- **Empty state**: section không có lesson → dòng "Chưa có bài học"; course không có section → card mời teacher "Thêm chương đầu tiên" (chỉ khi can_manage) / "Nội dung đang được cập nhật" (student).
- Giữ đúng UI convention: surface dùng `bg-white shadow-sm ring-1 ring-slate-900/5 rounded-2xl` thay border; emerald = primary, transition subtle.
- Wireframe accordion đã mô tả trong chat khi chốt hướng — bám theo mock đó.
