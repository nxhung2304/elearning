## Status
- Review: pending

## Metadata
- **Title:** API: Auth (sign_in, sign_up, sign_out)
- **Phase:** 5 - API (Mobile)
- **Story ref:** `specs/story.md` — Week 22-23 | API Setup + Auth + Courses
- **Github issue**: https://github.com/nxhung2304/elearning/issues/63

## Description

Thêm 3 endpoint Grape cho mobile client đăng ký/đăng nhập/đăng xuất, dùng JWT đã cấu hình ở issue #63 (`devise-jwt` + `JwtDenylist`). Logic đặt trực tiếp trong Grape endpoint (project chưa có Service layer để reuse — theo `story.md`), dùng Warden trực tiếp vì CanCanCan/Devise controller helper không tích hợp sẵn với Grape.

## Acceptance Criteria

- [ ] `POST /api/v1/auth/sign_up` tạo user mới (role mặc định `student`), trả JWT token + user info, `201`.
- [ ] `POST /api/v1/auth/sign_up` với email đã tồn tại / password không hợp lệ → `422` kèm message lỗi theo field.
- [ ] `POST /api/v1/auth/sign_in` với email/password đúng → trả JWT token trong response (header `Authorization` hoặc body — xem Key Decisions) + user info, `200`.
- [ ] `POST /api/v1/auth/sign_in` sai credential → `401` kèm message chung chung (không tiết lộ email tồn tại hay không).
- [ ] `DELETE /api/v1/auth/sign_out` với JWT hợp lệ trong header `Authorization` → revoke token (ghi vào `jwt_denylists`), `200`.
- [ ] `DELETE /api/v1/auth/sign_out` không có token / token đã revoke → `401`.
- [ ] User bị `status_suspended` hoặc `discarded` không sign_in được → `401`.
- [ ] Minitest: request test cho cả 3 endpoint, happy path + lỗi.

## Implementation Checklist

- [ ] `app/entities/user_entity.rb` — `BaseEntity` expose `id, email, name, status`; không expose `encrypted_password`.
- [ ] `app/grape/api/v1/auth.rb` — `Grape::API` mới, `resource :sign_up do post end`, `resource :sign_in do post end`, `resource :sign_out do delete end`.
- [ ] `sign_up`: `params do requires :email, :password, :name end`, tạo `User.new(...)`, default role `student` (tạo `UserRole` với `Role.find_by(code: Role::STUDENT)`), nếu `save` thành công → encode JWT bằng `Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)` lấy token, trả `{ token:, user: UserEntity.represent(user) }` status `201`; nếu fail → `error!({ errors: user.errors }, 422)`.
- [ ] `sign_in`: `params do requires :email, :password end`, `user = User.find_by(email: params[:email])`, check `user&.valid_password?(params[:password])` và `user.status_active?` và `!user.discarded?`, nếu hợp lệ → encode token tương tự sign_up, trả `200`; nếu không → `error!({ error: I18n.t("...") }, 401)`.
- [ ] `sign_out`: đọc token từ header `Authorization` (`Bearer <token>`), decode lấy `jti`/`exp`, `JwtDenylist.create!(jti:, exp:)`, trả `{ message: "..." }` `200`; nếu không decode được / thiếu header → `error!({ error: "..." }, 401)`.
- [ ] `app/grape/api/v1/base.rb` — `mount API::V1::Auth`.
- [ ] i18n: thêm message lỗi (invalid credentials, unauthorized) vào `config/locales/views/en.yml` theo convention hiện có của project (kiểm tra key pattern đã dùng ở các controller khác trước khi đặt tên key mới).
- [ ] Minitest: `test/requests/api/v1/auth_test.rb` (hoặc path tương ứng convention request test hiện có của project) — cover sign_up (success/duplicate email/invalid password), sign_in (success/wrong password/suspended/discarded), sign_out (success/missing token/already revoked).

## Flow Diagram

```
POST /api/v1/auth/sign_up
    → validate params (email, password, name)
    → User.new + default role student
    → save?
        ├── true  → encode JWT (Warden::JWTAuth::UserEncoder) → 201 { token, user }
        └── false → 422 { errors }

POST /api/v1/auth/sign_in
    → find_by(email)
    → valid_password? && status_active? && !discarded?
        ├── true  → encode JWT → 200 { token, user }
        └── false → 401 { error }

DELETE /api/v1/auth/sign_out
    → decode Authorization header
        ├── valid jti  → JwtDenylist.create(jti, exp) → 200
        └── invalid/missing → 401
```

## Key Decisions

1. **Không dùng `Warden::JWTAuth::Middleware` tự động cho sign_in/sign_up**: vì `dispatch_requests` của devise-jwt hook vào Rack middleware dựa trên response Warden, nhưng Grape không chạy qua Devise controller — nên encode token thủ công bằng `Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)` trong endpoint, trả token trực tiếp trong response body (JSON) thay vì chỉ dựa vào response header, để mobile client dễ lấy.
2. **Authorization thủ công, không qua CanCanCan middleware**: theo `story.md` đã note rõ — CanCanCan không tích hợp sẵn Grape, auth/authorization endpoint này tự check field (`status_active?`, `discarded?`) trực tiếp, các endpoint CRUD khác (issue sau) sẽ gọi `Ability.new(current_user).can?` riêng.
3. **Role mặc định khi sign_up là `student`**: API hiện chỉ phục vụ mobile học viên theo scope Phase 5 (`story.md` — API Setup + Auth + Courses); tạo giáo viên/admin qua API không nằm trong issue này.
4. **Message lỗi sign_in dùng chung chung** ("email hoặc mật khẩu không đúng") thay vì phân biệt "email không tồn tại" / "sai mật khẩu" — tránh lộ thông tin email đã đăng ký (security best practice, không phải yêu cầu mới phát sinh ngoài scope).
