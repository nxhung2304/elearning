## Metadata
- Review: Approved
- **Title:** Add EventLog model
- **GitHub Issue:** #45
- **Phase:** Phase 1 — MVP (Web), Week 5-6 | Enrollment + Progress
- **Ref:** [ERD → event_logs](../erd.md#event_logs)

## Description

`EventLog` là append-only audit log ghi lại các hành động của user trong hệ thống (course events, user events, ...). Model cần association tới `User` và validate `event_type` chỉ nhận các giá trị đã định nghĩa trước (thay vì free-text), để tránh log rác và dễ query/filter theo loại sự kiện.

## Acceptance Criteria

- [ ] `EventLog belongs_to :user`
- [ ] `User has_many :event_logs` (ngược lại, cho phép truy vấn lịch sử event của 1 user)
- [ ] `event_type` bắt buộc (`presence: true`) và chỉ nhận giá trị nằm trong danh sách sự kiện đã định nghĩa (`inclusion`)
- [ ] `metadata` là nullable, nếu có giá trị phải là JSON object (Hash) — không chấp nhận array/string/number ở top-level
- [ ] Xoá `user` không cascade xoá `event_logs` (log lịch sử phải giữ lại — không dùng `dependent: :destroy`)
- [ ] i18n (en) cho các thông báo lỗi validation

## Implementation Checklist

- [ ] Thêm `belongs_to :user` vào `EventLog`
- [ ] Thêm `has_many :event_logs` vào `User` (không set `dependent: :destroy`/`:destroy_async`)
- [ ] Định nghĩa danh sách event type theo domain, dùng module hằng số riêng theo domain (`CourseEvent`, `UserEvent`, ...) thay vì 1 enum lớn, để mỗi domain tự quản lý event của mình
- [ ] Gộp toàn bộ hằng số các module trên thành `ALLOWED_EVENT_TYPES` dùng cho validation `inclusion`
- [ ] Custom validation kiểm tra `metadata` là Hash khi có giá trị
- [ ] i18n (en) cho `metadata.must_be_json` và các message validation khác
- [ ] FactoryBot factory cho `event_log` (event_type hợp lệ, metadata mẫu)
- [ ] Minitest: association tới `user`, validation `event_type` presence + inclusion (reject giá trị không nằm trong danh sách), validation `metadata` reject non-Hash, accept nil

## Flow Diagram

```
User action (create course, publish course, login, ...)
    → controller/service ghi EventLog.create!(user:, event_type:, metadata: {...})
        → validate event_type ∈ ALLOWED_EVENT_TYPES
        → validate metadata (nil hoặc Hash)
        → persist (append-only, không update/delete từ app)
```

## Key Decisions

- Event type dùng string constants theo module domain (`CourseEvent::CREATED`, `UserEvent::...`) thay vì Rails `enum`, vì `enum` cần khai báo tập giá trị cố định trên 1 model — event type ở đây trải rộng nhiều domain (course, user, ...) và sẽ mở rộng dần theo phase.
- `metadata` là `jsonb` tự do thay vì thêm cột riêng/association polymorphic cho từng loại đối tượng liên quan (course, lesson, ...) — giữ schema đơn giản, tránh phải migrate mỗi khi thêm loại event mới.
- Không set `dependent: :destroy` trên `has_many :event_logs` của `User` — log là dữ liệu audit, phải tồn tại độc lập với vòng đời user (kể cả khi discard/xoá user).
