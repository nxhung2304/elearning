## Status
- Review: pending

## Metadata
- **Title:** Thêm devise-jwt
- **Phase:** 5 - API (Mobile)
- **Story ref:** `specs/story.md` — Week 22-23 | API Setup + Auth + Courses

## Description

Thêm gem `devise-jwt` và cấu hình JWT authentication cho `User`, dùng revocation strategy `Denylist` dựa trên bảng `jwt_denylists` đã tạo ở issue #62 (mỗi token có `jti` riêng, revoke theo từng device/session — không dùng `JTIMatcher` vì strategy đó revoke toàn bộ token của user cùng lúc, không phù hợp mobile nhiều thiết bị). Sau issue này, request tới API có thể xác thực bằng JWT (chưa có endpoint sign_in/sign_up/sign_out — thuộc issue kế tiếp), token tự động revoke khi hết hạn/logout.

## Acceptance Criteria

- [ ] Gem `devise-jwt` có trong `Gemfile.lock`, cấu hình `secret` lấy từ `ENV["DEVISE_JWT_SECRET_KEY"]` (không hardcode).
- [ ] `User` model khai báo `:jwt_authenticatable` với `jwt_revocation_strategy: JwtDenylist`.
- [ ] `JwtDenylist` include `Devise::JWT::RevocationStrategies::Denylist`.
- [ ] JWT request/response config (`dispatch_requests`, `revocation_requests`) khai báo đúng path sẽ dùng ở issue API Auth kế tiếp (`POST /api/v1/auth/sign_in`, `DELETE /api/v1/auth/sign_out`) — dù controller/endpoint đó chưa tồn tại, config phải sẵn sàng để nối tiếp.
- [ ] Token sinh ra từ `Warden::JWTAuth` decode được, chứa `jti` khớp với user, `exp` hợp lệ theo `expiration_time` cấu hình.
- [ ] Minitest: test JWT encode/decode roundtrip cho 1 user (test ở mức model/config, không cần endpoint thật).

## Implementation Checklist

- [ ] Thêm `gem "devise-jwt"` vào `Gemfile`, `bundle install`.
- [ ] `config/initializers/devise.rb` — thêm block `config.jwt do |jwt|` với `jwt.secret = ENV.fetch("DEVISE_JWT_SECRET_KEY")`, `jwt.dispatch_requests = [ [ "POST", %r{^/api/v1/auth/sign_in$} ] ]`, `jwt.revocation_requests = [ [ "DELETE", %r{^/api/v1/auth/sign_out$} ] ]`, `jwt.expiration_time = 1.day.to_i` (hoặc giá trị phù hợp — xem Key Decisions).
- [ ] Thêm `DEVISE_JWT_SECRET_KEY` vào `.envrc` (local) và `.envrc.example` (placeholder) — không commit giá trị thật; CI cần set biến này tương tự `CORS_ALLOWED_ORIGINS`.
- [ ] `app/models/user.rb` — thêm `:jwt_authenticatable, jwt_revocation_strategy: JwtDenylist` vào dòng `devise :database_authenticatable, ...` hiện có.
- [ ] `app/models/jwt_denylist.rb` — include `Devise::JWT::RevocationStrategies::Denylist`, `self.table_name = "jwt_denylists"` nếu tên bảng không khớp convention Devise mặc định.
- [ ] Minitest: `test/models/jwt_denylist_test.rb` hoặc thêm vào `user_test.rb` — verify `Warden::JWTAuth::UserEncoder` encode/decode trả đúng user.

## Flow Diagram

```
User model
    devise :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist
        → sign_in thành công → Warden::JWTAuth encode { jti, sub, exp } → trả JWT trong header Authorization
        → request kèm JWT → decode → tìm user theo `sub` → nếu `jti` nằm trong `jwt_denylists` → reject
        → sign_out / token hết hạn → JwtDenylist.create(jti:, exp:) → token không dùng lại được
```

## Key Decisions

1. **`expiration_time`**: chọn `1.day` làm mặc định cho MVP mobile — có thể điều chỉnh khi có yêu cầu cụ thể về refresh token (chưa nằm trong scope Phase 5 theo `story.md`).
2. **`dispatch_requests`/`revocation_requests` trỏ tới path chưa tồn tại**: chấp nhận được vì `devise-jwt` chỉ match path bằng regex khi request thực sự tới — không lỗi nếu route chưa mount; path này sẽ khớp với endpoint tạo ở issue "API: Auth (sign_in, sign_up, sign_out)" ngay sau.
3. **`DEVISE_JWT_SECRET_KEY` qua `.envrc`, không dùng Rails credentials**: nhất quán với cách project đang quản lý secret khác (vd. `CORS_ALLOWED_ORIGINS`) qua direnv/ENV thay vì `config/master.key`.
