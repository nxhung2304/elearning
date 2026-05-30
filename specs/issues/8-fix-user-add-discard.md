## **Status:**
- Review: Approved
- PR: Merged ✅ 2026-05-30

## Metadata
- **Title:** [Fix] User — thêm discard
- **Phase:** Phase 1 — MVP (Web) / Week 1-2 Setup + Auth
- **GitHub Issue:** #18

---

## Description

User model hiện chưa có `discarded_at` column và chưa `include Discard::Model`. Cần thêm migration, include concern, và cập nhật test để soft-delete hoạt động đúng. Gem `discard` đã có trong Gemfile.

---

## Acceptance Criteria
- [x] Migration tạo `discarded_at` column trên `users` table
- [x] `User` model có `include Discard::Model`
- [x] Default scope của Discard tự động filter `.kept` (không cần thêm scope thủ công)
- [x] `user.discard` set `discarded_at`, `user.undiscard` clear nó
- [x] `User.kept` trả về users chưa bị discard
- [x] `User.discarded` trả về users đã bị discard
- [x] Annotate comment trong model file được cập nhật
- [x] Minitest pass

---

## Implementation Checklist
- [x] Tạo migration `AddDiscardedAtToUsers`
- [x] Thêm `include Discard::Model` vào `app/models/user.rb`
- [x] Chạy `bin/rails db:migrate`
- [x] Chạy `annotaterb` để cập nhật schema comment trong model
- [x] Thêm test cases cho discard behavior vào `test/models/user_test.rb`
- [x] Chạy `bin/rails test test/models/user_test.rb` — tất cả pass
- [x] Chạy `bin/rubocop` — không có warning

---

## Step-by-step Guide

**Files to create/modify:**
- `db/migrate/<timestamp>_add_discarded_at_to_users.rb` — thêm `discarded_at` column
- `app/models/user.rb` — thêm `include Discard::Model`
- `test/models/user_test.rb` — thêm test cho soft-delete behavior

**Key decisions:**
- `discarded_at` là `datetime`, nullable, default: nil — Discard yêu cầu đúng kiểu này
- Discard tự thêm default scope `where(discarded_at: nil)` — KHÔNG thêm scope thủ công
- Không dùng `dependent: :destroy` ở chỗ nào liên quan tới soft-delete; dùng `dependent: :discard` nếu cần cascade (Phase sau)
- Thứ tự `include` trong model: đặt `include Discard::Model` ngay sau Devise declarations

**Flow:**
```
user.discard
    → set discarded_at = Time.current
    → User.kept  → excludes this user (default scope)
    → User.discarded → includes this user

user.undiscard
    → clear discarded_at = nil
    → User.kept  → includes this user again

User.with_discarded → bypass default scope (all records)
```

**Non-obvious snippets:**
```ruby
# db/migrate/<timestamp>_add_discarded_at_to_users.rb
class AddDiscardedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    # 1. Add discarded_at datetime column, nullable, with index for query performance
  end
end

# app/models/user.rb  (chỉ thêm dòng include, không xóa gì)
class User < ApplicationRecord
  # 1. Include Discard::Model right after devise declaration
  # 2. Keep all existing devise, enum, associations, validations unchanged
end

# test/models/user_test.rb
test "discard sets discarded_at" do
  # 1. Create a persisted user
  # 2. Call user.discard
  # 3. Assert user.discarded_at is not nil
  # 4. Assert User.kept does not include user
end

test "undiscard clears discarded_at" do
  # 1. Create and discard a persisted user
  # 2. Call user.undiscard
  # 3. Assert user.discarded_at is nil
  # 4. Assert User.kept includes user
end

test "kept scope excludes discarded users" do
  # 1. Create two users
  # 2. Discard one
  # 3. Assert User.kept.count does not include discarded user
end
```

---

## Notes
- `discard` gem đã có trong Gemfile — không cần `bundle add`
- Sau khi migrate, chạy `bundle exec annotaterb models` để cập nhật schema header trong `user.rb`
- Các model khác (Profile, Course, v.v.) sẽ thêm discard riêng trong issue tương ứng — không thêm ở đây
