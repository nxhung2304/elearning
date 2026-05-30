# Code Review: feature/hung-#20-crud-profile → main

## Summary
Profile edit/update feature for Student/Teacher is mostly well-structured, but has two critical correctness issues — `authorize_resource` ordering and a SimpleForm config regression — plus several smaller bugs in the test file and views.

---

## Issues

### Critical

- `app/controllers/profiles_controller.rb:2` — `authorize_resource` is declared **before** `before_action :set_profile`, so it fires while `@profile` is still `nil`. CanCanCan then checks `can?(:update, Profile)` (the class), not the scoped instance — bypassing the `user_id: user.id` condition. Move `before_action :set_profile` above `authorize_resource`, or reverse the declaration order.

- `config/initializers/simple_form.rb` — The entire custom DaisyUI/Tailwind wrapper configuration (`:default`, `:select`, `:textarea`, `:check_boxes`, `input_mappings`, `wrapper_mappings`) was replaced with the plain SimpleForm default template. `app/views/users/_form.html.erb:4` already uses `wrapper: :select` — after this reset, that wrapper no longer exists and will raise a runtime error. Restore the custom wrappers (or merge the needed changes into the existing config instead of replacing it).

### Warning

- `test/controllers/profiles_controller_test.rb:1` — `require "pry-rails"` is a debug artifact; must not be committed.

- `test/controllers/profiles_controller_test.rb:24,40` — `assert_equal` argument order is reversed. Minitest convention is `assert_equal(expected, actual)`. Both update tests have it as `assert_equal @student.profile.full_name, dummy_name` / `@teacher.profile.full_name, dummy_name` — swap the arguments.

- `app/javascript/controllers/image_preview_controller.js:6-8` — `connect()` unconditionally removes the `hidden` class from `previewTarget` whenever the element exists. When no image is attached, the server renders `<img src="" class="...hidden">`. On connect, `hidden` is removed, showing a broken blank image. Remove the `connect()` method entirely — the ERB template already handles initial visibility correctly.

- `app/views/profiles/_form.html.erb:2-8` — The acceptance criteria requires `full_name` to have `required: true` in the form. The generic `displayable_columns` loop renders all fields uniformly with no `required` flag. Add a special case: `f.input :full_name, required: true` (rendered directly or via a condition inside the loop).

- `app/views/shared/_image.html.erb:17` — `"No file chosen"` is a hardcoded English string. Add an i18n key (e.g., `helpers.image.no_file_chosen`) and reference it here.

- `test/controllers/profiles_controller_test.rb:4` — `include Devise::Test::IntegrationHelpers if defined?(Devise)` is redundant; `test_helper.rb:18` already includes it globally for all `ActionDispatch::IntegrationTest` subclasses. Remove this line.

### Suggestion

- `app/views/profiles/_form.html.erb:1` — `simple_form_for` uses `@profile` (instance variable) while the rest of the partial uses the `profile` local variable passed via `render "form", profile: @profile`. Be consistent — use the local: `simple_form_for profile, url: profile_path, ...`.

- `app/views/shared/_image.html.erb:13,17,21,22` — `resource.send(image)` is called 4 times. Extract to a local variable at the top of the partial: `<% attachment = resource.send(image) %>` then use `attachment` throughout.

- `app/views/shared/_image.html.erb:22` — Passing `""` (empty string) to `image_tag` when no image is attached will generate an `<img src="">` that triggers a browser network request. Use `nil` instead: `resource.send(image).attached? ? resource.send(image) : nil`.

---

## Passed

- `app/models/ability.rb` — `can :update, Profile, user_id: user.id` correctly scoped for both teacher and student roles.
- `app/models/profile.rb` — `displayable_columns` override cleanly excludes `user_id`.
- `app/models/application_record.rb` — Adding `discarded_at` to `RANSACK_DENYLIST` is correct.
- `config/routes.rb` — Singular `resource :profile` is the right choice; no `:id` in URL.
- `app/views/layouts/application.html.erb` — `if current_user.present?` guard on the sidebar is correct.
- `test/models/ability_test.rb` — Cross-user update blocking tests are well-scoped.
- `config/locales/` — i18n keys are properly structured.

---

## Rules applied

- Global: `core.md` (SRP, no logic outside spec), `clean-code.md` §Naming, `code-style.md` §Guard Clauses
- Security: CanCanCan authorization order, no hardcoded secrets
- Rails conventions: `assert_equal` argument order, before_action registration order, i18n for user-facing strings
