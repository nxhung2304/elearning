# Code Review: feature/hung-#20-crud-profile → main

## Summary
This branch adds `ProfilesController` (edit/update), a profile form partial, a shared image upload component, and a Stimulus image-preview controller. The core flow is correct and the authorization boundary (singular resource + `current_user` scoped `set_profile`) is well-designed. A few bugs and missing tests need to be addressed before merge.

---

## Issues

### Critical

- `app/views/profiles/_form.html.erb:2–9` – The partial iterates with `profile.class.visible_columns` but the local variable `profile` is never passed when rendering (`render "form", profile: @profile` at `edit.html.erb:17` DOES pass it, but `simple_form_for` on line 1 uses `@profile` directly). The inconsistency is latent — the partial mixes the local `profile` (lines 2–4, 16) with the instance var `@profile` (lines 1, 11). When rendered from any other context that does not set `@profile`, line 1 and 11 will raise a `NoMethodError`. Normalize: accept only the local variable, remove the `@profile` reference, and derive the `simple_form_for` model from it.

- `app/models/ability.rb:13` – `authorize_resource` in `ProfilesController` maps `edit` → requires `can?(:edit, ...)` (or `:update` covers it only through CanCanCan's aliasing of `[:edit] => :update`). The current ability rules define `can :update, Profile, …` which CanCanCan aliases to cover `:edit`. This works, but the alias is implicit. More critically, the ability block for **student** (line 15) only grants `can :read, User, id: user.id` — students cannot `:read` arbitrary resources. CanCanCan's `authorize_resource` for `edit` checks `:read` by default (not `:update`) on new records. Because `set_profile` returns an unsaved record (`build_profile`) for a first-time visitor, `authorize_resource` will evaluate `can?(:read, @profile)` (the new, unsaved record) for the `edit` action — and a student has no `:read` on Profile at all. This means **a student visiting `/profile/edit` for the first time gets a 403**. Fix: add `can :read, Profile, user_id: user.id` to the student block (and verify teacher block already has `:read, :all`).

- `test/controllers/profiles_controller_test.rb:22` – `patch profile_path(@student)` passes a `User` object to a **singular resource** path helper. `profile_path` for a singular resource takes no argument; passing `@student` (a User) generates a wrong URL or raises a routing error. The correct call is `patch profile_path, params: { … }`. Same bug at line 45 for `@teacher`.

- `test/controllers/profiles_controller_test.rb:2` – `require "pry-rails"` is a debugging artifact committed by mistake. This must be removed before merge; it causes a `LoadError` in any environment where the gem is not in the `Gemfile`.

### Warning

- `app/views/profiles/edit.html.erb:10–14` – A **Delete** button is rendered on the edit page, but the routes only declare `resource :profile, only: %i[edit update]` — there is no `destroy` route. Clicking "Delete" will return a 404. Either add `destroy` to the route and controller, or remove this button.

- `app/views/profiles/edit.html.erb:17–18` – The cancel link points to `users_path`. This is semantically wrong (the user is on their own profile, not a user-management page). It also leaks the users index page URL to non-admin roles that cannot access it. Use `root_path` or a sensible fallback.

- `app/views/profiles/_form.html.erb:1` – `method: :put` is hardcoded. For a new, unsaved profile (`build_profile`), `simple_form_for` should use POST (it derives this automatically from `record.persisted?`). Forcing `:put` breaks the auto-routing for new records and sends a PUT even when the record doesn't exist yet. Remove the explicit `method:` and let `simple_form_for` derive it, or rely on the fact that `update` handles both save and update in this flow (but then the URL target also needs to be explicit).

- `app/views/shared/_image.html.erb:8` – `"Select image"` is a hardcoded English string with no I18n key. All other UI text goes through `t(...)`. Add an I18n key (`helpers.image.select`, for example) and use `t(...)` here.

- `test/controllers/profiles_controller_test.rb` – The issue spec explicitly requires a test for **"set_profile always resolves to current_user's profile (never another user's)"** (acceptance criterion and implementation checklist). That test is missing entirely. Add it: sign in as student A, create a profile for student B, GET `/profile/edit`, and assert `assigns(:profile).user_id == @student.id`.

- `test/controllers/profiles_controller_test.rb:30` – Context label is `"Teacher"` (capitalized) while the student context at line 7 uses `"student"` (lowercase). Keep naming consistent: use lowercase throughout.

### Suggestion

- `app/javascript/controllers/image_preview_controller.js:6–9` – `connect()` unconditionally removes `hidden` from the preview element as soon as the controller connects, even when no image is attached. The current workaround in `_image.html.erb` conditionally adds `"hidden"` via ERB, so this is fragile. Consider checking `this.previewTarget.src` is non-empty in `connect()` before removing the class.

- `app/javascript/controllers/image_preview_controller.js:13` – `update()` silently ignores the case where `file` is falsy (user cancels the file dialog). Consider resetting the preview and filename to the original server-side values in that branch for a better UX.

- `app/views/profiles/edit.html.erb:2` – `add_breadcrumb current_user.id` exposes the raw database integer ID in the breadcrumb trail. Consider using `current_user.email` or a display name instead.

- `app/helpers/profiles_helper.rb` – Empty helper file. Rails generates this automatically; if it's not needed now it's fine to keep, but it adds noise to the diff.

---

## Passed

- `ProfilesController` uses singular resource correctly; `set_profile` correctly scopes to `current_user` preventing horizontal privilege escalation.
- `authorize_resource` (not `load_and_authorize_resource`) is correctly chosen to avoid the singular-resource/no-`:id` conflict.
- `profile_params` correctly whitelists only `full_name`, `phone`, `bio`, `avatar` — no admin-only columns exposed.
- `Profile#visible_columns` correctly subtracts `user_id` from the base implementation — prevents leaking association ID in the form.
- Flash key `t("controller.updated", ...)` reuses an existing i18n key as required.
- `redirect_to edit_profile_path` after update is correct for singular resource (no ID in URL).
- `render :edit, status: :unprocessable_entity` on failure follows Rails 7+ form error convention.
- Ability tests for cross-user update denial (lines 65–79 in ability_test.rb) are present and correct.
- `has_one_attached :avatar` with `permit(:avatar)` in params is the right Active Storage approach (no `avatar_url` column).
- `config/locales/views/en.yml` has `profiles.edit.title` key — view uses `t('.title')` correctly.
- `RANSACK_DENYLIST` in `ApplicationRecord` correctly excludes `discarded_at` — Profile ransack surface is safe.
- Stimulus controller is registered correctly in `index.js`.
- `resource :profile, only: %i[edit update]` routing is correct for the singular self-service edit pattern.

---

## Rules applied

- No project rule files found at `.claude/code-rules/` or `specs/code-rules/`.
- Applied: CLAUDE.md conventions (RuboCop omakase, CanCanCan, Devise, Minitest/FactoryBot, Discard, Hotwire), Rails 8.1 security and authorization best practices, acceptance criteria from `specs/issues/9-crud-profile-student-teacher-edit-profile.md`.
