---
GitHub Issue: #6
Status: PENDING
Reviewed against: current branch implementation
---

## Summary

The spec is thorough and well-structured. The routes and most controller logic are already implemented, but several acceptance criteria are missing from the implementation: the `me` action is absent, `set_user` has no `RecordNotFound` rescue, the destroy self-guard is missing, redirect targets are wrong (index instead of show), and the test suite cove**r**s only ~30% of the required cases. The i18n keys referenced in the spec also do not exist yet.

---

## Well-Defined

- Enum-based logical delete (`status_deleted!`) is clearly specified and correctly implemented in the model.
- Strong params list is explicit and safe — `encrypted_password` exclusion is called out.
- Password-stripping strategy on update is unambiguous.
- Index scope (show ALL regardless of status) is explicitly justified with a future cancancan note.
- Factory already exists with all required traits.
- `Pagy::Backend` / `Pagy::Frontend` placement is confirmed — both are already wired in `ApplicationController` and `ApplicationHelper`.
- Routes are correctly ordered (`users/me` declared before `resources :users`).

---

## Issues Found

### 1. `me` action is missing from controller

> `GET /users/me → redirect_to user_path(current_user)`

**Problem:** The route `get "users/me"` exists in `config/routes.rb`, but `UsersController` has no `me` action. Any request to `/users/me` will raise `AbstractController::ActionNotFound`.

**Suggest:** Add the action:
```ruby
def me
  redirect_to user_path(current_user)
end
```

---

### 2. `set_user` does not rescue `RecordNotFound`

> `User.find(params[:id]) ──(RecordNotFound)──→ redirect index, flash :alert`

**Problem:** Current `set_user` is a bare `User.find(params[:id])` with no rescue. An unknown id raises an unhandled 500, not a redirect with flash.

**Suggest:**
```ruby
def set_user
  @user = User.find(params[:id])
rescue ActiveRecord::RecordNotFound
  redirect_to users_path, alert: t("errors.not_found")
end
```
Also add `errors.not_found` to `config/locales/en.yml`.

---

### 3. Destroy does not guard against deleting self

> `DELETE /users/:id where :id is current_user → redirects with alert, status unchanged`

**Problem:** Current `destroy` calls `@user.status_deleted!` unconditionally — a user can soft-delete themselves, breaking their own session.

**Suggest:**
```ruby
def destroy
  if @user == current_user
    redirect_to users_path, alert: t("users.destroy.cannot_delete_self") and return
  end
  @user.status_deleted!
  redirect_to users_path, notice: t("controller.destroyed", text: email_user_message)
end
```
Add `users.destroy.cannot_delete_self` to `config/locales/en.yml`.

---

### 4. Create and update redirect to index, not show

> `save OK → redirect_to @user, notice: t(".success")`

**Problem:** Both `create` and `update` currently redirect to `users_url` (index). The spec requires redirecting to `user_path(@user)` (the show page).

**Suggest:** Change `redirect_to users_url` → `redirect_to @user` in both actions.

---

### 5. Missing i18n keys

> `errors.not_found` and `users.destroy.cannot_delete_self` do not exist yet

**Problem:** The spec explicitly lists these as keys to add. Both are referenced in controller logic that needs to be implemented (items 2 & 3 above). Without them, calls to `t(...)` will render `[missing "en.errors.not_found" translation]`.

**Suggest:** Add to `config/locales/en.yml`:
```yaml
errors:
  not_found: "Record not found."

users:
  destroy:
    cannot_delete_self: "You cannot delete your own account."
```

---

### 6. Test suite covers ~30% of required cases

**Problem:** The current `test/controllers/users_controller_test.rb` is missing the following required test cases:

| Category | Missing tests |
|---|---|
| Happy path | `me` redirect, `show` for another user, `update` happy path |
| Unauthenticated | All 7 actions (index, show, new, create, edit, update, destroy) |
| Record not found | `show`, `update`, `destroy` with unknown id |
| Duplicate email | `create`, `update` with existing email |
| Self-delete guard | `cannot delete self` |
| Missing params | `update with blank email` |

The `@other` user fixture (second user for targeting show/edit/destroy) is also missing from `setup`.

---

### 7. `require "pry-rails"` in test file

**Problem:** Line 2 of `users_controller_test.rb` has `require "pry-rails"` — a debug artifact that should not be in a committed test file.

**Suggest:** Remove the line.

---

### 8. Password stripping logic has a subtle bug

> `params = params.except(:password_confirmation) if params[:password_confirmation].blank?`

**Problem:** The current `update_params` logic strips `password_confirmation` independently of `password`. If `password` is provided but `password_confirmation` is blank, only `password_confirmation` gets stripped, leaving an incomplete password pair. The spec's intent is: strip both password fields when `password` itself is blank.

**Suggest:** Use `reject` over both keys together:
```ruby
def update_params
  user_params.reject { |k, v| /password/.match?(k) && v.blank? }
end
```

---

## Score (6/10)

| Area | Status | Notes |
|---|---|---|
| Acceptance Criteria | ❌ | 5/13 criteria not met (me action, RecordNotFound, self-delete guard, redirect target, i18n) |
| Implementation Checklist | ❌ | `set_user` rescue, `me` action, i18n keys, views not verified |
| Test Coverage | ❌ | ~8/26 required test cases present |
| Routes | ✅ | Correctly ordered, both `me` and `resources :users` present |
| Model / Factory | ✅ | Enum, `active_for_authentication?`, factory traits all correct |
| Pagy + Ransack | ✅ | Correctly wired in index action |

---

## Status

- [ ] READY
- [x] PENDING — needs the following before merging:
  1. Add `me` action
  2. Add `RecordNotFound` rescue in `set_user`
  3. Add self-delete guard in `destroy`
  4. Fix `create`/`update` redirect targets → `@user`
  5. Add missing i18n keys to `en.yml`
  6. Expand test suite to cover all required cases
  7. Fix password stripping logic in `update_params`
  8. Remove `require "pry-rails"` from test file
