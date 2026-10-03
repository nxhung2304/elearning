## Status
- Review: Approved - Merged

## Metadata
- **Title:** Migration: tạo `jwt_denylists`
- **Phase:** 5 - API (Mobile)
- **Story ref:** `specs/story.md` — Week 22-23 | API Setup + Auth + Courses
- **Github issue**: https://github.com/nxhung2304/elearning/issues/62

## Description

Chuẩn bị schema cho `devise-jwt` (revocation strategy `Denylist`, sẽ setup ở task kế tiếp): tạo bảng `jwt_denylists` để lưu token đã revoke (logout/expire), mỗi token (device/session) có `jti` riêng nên revoke 1 device không ảnh hưởng device khác — phù hợp mobile (nhiều thiết bị đăng nhập cùng lúc). Không cần thêm cột vào `users` vì strategy `Denylist` không dựa trên `jti` lưu ở `users` (khác với `JTIMatcher`). Chưa thêm gem/config `devise-jwt` trong issue này — chỉ migration + model.

## Acceptance Criteria

- [ ] Bảng `jwt_denylists` tồn tại với cột `jti` (string, unique index) và `exp` (datetime).
- [ ] `db/schema.rb` cập nhật đúng sau khi migrate.
- [ ] `JwtDenylist` model tồn tại, không có test riêng cho business logic (model rỗng, chỉ khai báo ở đây — logic revoke sẽ gắn ở task devise-jwt kế tiếp).

## Implementation Checklist

- [ ] `make gen-migration NAME=CreateJwtDenylists FIELDS="jti:string:uniq exp:datetime"` — tạo bảng `jwt_denylists` (không cần `timestamps` nếu theo convention mặc định của `devise-jwt`, nhưng giữ `created_at`/`updated_at` để nhất quán với các model khác trong app — xem Key Decisions).
- [ ] `bin/rails db:migrate` rồi kiểm tra `db/schema.rb`.
- [ ] Tạo `app/models/jwt_denylist.rb` (class rỗng, chưa include `Devise::JWT::RevocationStrategies::Denylist` — sẽ thêm ở task setup `devise-jwt`).
- [ ] Annotate schema comment cho `JwtDenylist` bằng `annotaterb` (theo convention project — không sửa tay header).

## Flow Diagram

```
Migration: CreateJwtDenylists
    → create_table :jwt_denylists
        ├── jti:string (unique index)
        └── exp:datetime
```

## Key Decisions

1. **Chọn `Denylist` thay vì `JTIMatcher`**: `JTIMatcher` lưu 1 `jti` dùng chung trên `users`, rotate sẽ revoke toàn bộ token của user (mọi device) cùng lúc, không tách được theo session. Mobile e-learning cần đăng nhập nhiều thiết bị + khả năng "logout thiết bị này" sau này → `Denylist` (per-token revoke) phù hợp hơn, nên không cần thêm cột `jti` vào `users`.
2. **`jwt_denylists` giữ `timestamps`**: convention mặc định của gem `devise-jwt` không yêu cầu timestamps, nhưng project này dùng `annotaterb` + có `timestamps` ở hầu hết model khác — giữ nhất quán, không ảnh hưởng revocation logic.
3. **Chưa include `Denylist` strategy ở model**: tách riêng để migration issue này chỉ lo schema, business logic (`:jwt_authenticatable`, revocation strategy) thuộc task "Thêm devise-jwt" kế tiếp trong `story.md`.
