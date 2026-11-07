## **Status:**
- Review: Approved
- PR: Todo

## Metadata
- **Title:** API: Courses + Course categories (Home - Course list)
- **Phase:** 5 - API (Mobile) · Week 22-23
- **Depends on:** —
- **GitHub Issue:** #78

---

## Description
Thêm 2 endpoint Grape để mobile dựng màn Home / Course list: `GET /api/v1/courses` (list course đã publish, có filter + phân trang) và `GET /api/v1/course_categories` (dữ liệu cho chip category). Cả hai yêu cầu Bearer token như Auth API. Nguồn: handoff từ repo mobile (`elearning_mobile/specs/issues/home-course-list/handoff-backend.md`).

---

## Acceptance Criteria
- [x] `GET /api/v1/courses` chỉ trả course `published` + chưa discard, cho mọi role; 20 item/trang; sắp xếp `published_at` mới nhất trước, đồng hạng thì `id` giảm dần.
- [x] Mỗi item: `id, title, slug, level, price, total_lessons, category { id, name }, teacher { id, name }`; `price` là string; `teacher.name` có thể `null`.
- [x] Response courses có `meta { page, per_page, total_pages, total_count }`; lọc `kept` trước khi phân trang (trang nào cũng đủ 20 item, trừ trang cuối).
- [x] Filter theo kiểu Ransack của Rails (`q[...]`, giống các API khác của công ty): `q[category_id_eq]` (category cha gồm cả subtree, server tự mở rộng), `q[level_eq]` (số 0/1/2 ứng với beginner/intermediate/advanced), `q[title_i_cont]` (title chứa chuỗi, không phân biệt hoa thường); category không tồn tại hoặc filter không khớp → `data: []`, `200`. Course chỉ cho lọc theo 3 field này.
- [x] `page` vượt trang cuối → `data: []` kèm `meta`, `200` (không được ra 500).
- [x] `GET /api/v1/course_categories` trả list phẳng `{ id, name, parent_id }` gồm mọi category chưa discard, sắp theo `position`.
- [x] Lỗi dùng format chung `{ "errors": [{ "code", "message" }] }`: thiếu/hết hạn token → `401 unauthorized`; `q[level_eq]`/`page`/`q[category_id_eq]` sai → `422 invalid_params`.
- [x] Response mẫu lấy từ lần gọi thật (`curl` hoặc swagger) được dán vào mục Samples bên dưới.

---

## Implementation Checklist
- [x] `app/entities/` — entity cho course item (kèm category, teacher rút gọn) và category.
- [x] `app/grape/api/v1/courses.rb` — `authenticate!`, params (`page`, `q` với `level_eq` thuộc `Course.levels.values`, `category_id_eq`, `title_i_cont`), chỉ đưa filter đã khai báo (`declared(params)`) cho Ransack, mở rộng `category_id_eq` thành subtree (ancestry), query, phân trang, `meta`.
- [x] `app/grape/api/v1/course_categories.rb` — `authenticate!`, list category chưa discard.
- [x] `app/grape/api/v1/base.rb` — mount 2 endpoint mới.
- [x] Eager load `category`, `teacher` để tránh N+1.
- [x] `test/integration/api/v1/` — request test cho mọi Acceptance Criteria ở trên.
- [x] Chạy API thật, lấy response mẫu, dán vào mục Samples. (Chạy bằng `curl` trên database development.)
- [x] `bin/rubocop` và `bin/rails test` pass.
- Kết quả (chưa commit): 22 test mới (18 courses, 4 course_categories) pass; toàn bộ `bin/rails test` 344 runs, 0 failures; `bin/rubocop` không lỗi.

---

## Key Decisions
- **Không dùng `Ability` cho list này** — ability của teacher chặn đọc course của teacher khác, nhưng Home cần cùng một catalog published cho mọi role. Task "API: Authorization" trong story vẫn để riêng.
- **Không copy `IndexableResource`** — concern đó lọc `.kept` sau `pagy`, nên một trang có thể ít hơn 20 item.
- **Categories trả list phẳng, không trả tree** — mobile chỉ hiện chip root (`parent_id` null) và tự lọc; việc gộp subtree khi filter làm ở server.
- **Filter dùng `q` của Ransack** — thống nhất với cách mobile của công ty đang gọi các API Rails. Ransack không tự báo lỗi nên `level_eq`, `category_id_eq`, `page` phải kiểm tra ở Grape `params` để ra `422`. Chỉ cho lọc `title`, `level`, `category_id` để không lộ các cột khác (`status`, `price`, `teacher_id`...).
- **`price` là string** — Rails encode cột decimal thành string, giữ được độ chính xác; mobile parse thành decimal. Cần xác nhận lại bằng response mẫu thật.

---

## Out of Scope
- Thumbnail của course (model không có, không thêm).
- Course detail, Sections, Lessons API.
- Sort hoặc page size do client chọn.

---

## Notes
- Page vượt trang cuối: đã bật extra `overflow` trong `config/initializers/pagy.rb` (mặc định `:empty_page`, trả mảng rỗng); đã có test qua HTTP.
- `page` không hợp lệ (`abc`, `0`): đã chặn bằng khai báo `params` của Grape, trả `422 invalid_params`; có test.
- `q[level_eq]` với tên (`advanced`) bị Ransack ép về 0 (beginner) mà không báo lỗi; giá trị ngoài 0-2 (ví dụ 9) cũng không lỗi. Response trả `level` dạng tên (`beginner`) nhưng filter nhận số, cần ghi rõ cho mobile.
- Token hết hạn: không viết test riêng cho 2 endpoint này vì cơ chế xác thực dùng chung đã có test (`auth_test.rb`, sign_out với access token hết hạn); 2 endpoint có test thiếu token và token sai.
- Pagy `Backend` phải `include` trong `helpers` của Grape (đã làm ở `courses.rb`).

---

## Samples
Lấy bằng `curl` từ server development (database development, 2 course published). `authenticate!` được tắt tạm khi gọi các mẫu 200 và 422, riêng mẫu 401 gọi khi đang bật.

Chưa có: mẫu 401 token hết hạn (xem Notes). Mẫu có `price` = 0 dùng course id 150 tạo tạm trong database development.

**GET /api/v1/courses (có dữ liệu: một course `price` > 0, một course `price` = 0)** — 200
```json
{"data":[{"id":150,"title":"Free Intro to Web Development","slug":"free-intro-to-web-development","level":"intermediate","price":"0.0","total_lessons":5,"category":{"id":3,"name":"Web Development"},"teacher":{"id":2,"name":"Teacher User"}},{"id":1,"title":"Ruby on Rails for Beginners","slug":"ruby-on-rails-for-beginners","level":"beginner","price":"99.99","total_lessons":12,"category":{"id":1,"name":"Programming"},"teacher":{"id":2,"name":"Teacher User"}}],"meta":{"page":1,"per_page":20,"total_pages":1,"total_count":2}}
```

**GET /api/v1/courses?q[category_id_eq]=1 (category cha, gồm cả course ở category con id 3)** — 200: trả cả 2 course như trên.

**GET /api/v1/courses?q[level_eq]=1** — 200
```json
{"data":[{"id":150,"title":"Free Intro to Web Development","slug":"free-intro-to-web-development","level":"intermediate","price":"0.0","total_lessons":5,"category":{"id":3,"name":"Web Development"},"teacher":{"id":2,"name":"Teacher User"}}],"meta":{"page":1,"per_page":20,"total_pages":1,"total_count":1}}
```

**GET /api/v1/courses?q[title_i_cont]=nomatch (filter không khớp)** — 200
```json
{"data":[],"meta":{"page":1,"per_page":20,"total_pages":1,"total_count":0}}
```

**GET /api/v1/courses?q[category_id_eq]=999999 (category không tồn tại)** — 200
```json
{"data":[],"meta":{"page":1,"per_page":20,"total_pages":1,"total_count":0}}
```

**GET /api/v1/courses?page=999 (vượt trang cuối)** — 200
```json
{"data":[],"meta":{"page":999,"per_page":20,"total_pages":1,"total_count":1}}
```

**GET /api/v1/course_categories (category cha và con)** — 200
```json
{"data":[{"id":3,"name":"Web Development","parent_id":1},{"id":2,"name":"Mobile Development","parent_id":null},{"id":1,"name":"Programming","parent_id":null}]}
```

**GET /api/v1/courses và /api/v1/course_categories (thiếu token)** — 401
```json
{"errors":[{"code":"unauthorized","message":"Unauthorized"}]}
```

**GET /api/v1/courses?q[level_eq]=9** — 422
```json
{"errors":[{"code":"invalid_params","message":"q[level_eq] does not have a valid value"}]}
```

**GET /api/v1/courses?page=0** — 422
```json
{"errors":[{"code":"invalid_params","message":"page does not have a valid value"}]}
```
