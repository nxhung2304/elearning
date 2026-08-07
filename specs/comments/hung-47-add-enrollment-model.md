# Code Review: feature/hung-#47-add-enrollment-model → main

## Summary
Adds the `Enrollment` model (status enum, business-rule validations, discard cascade from `Course`) plus factory, tests, migration, and i18n. Implementation closely follows the existing `Section` cascade-discard pattern and matches `specs/issues/22-add-enrollment-model.md`. Found 3 RuboCop violations that will fail the Overcommit pre-commit hook, plus a couple of minor consistency suggestions.

## Issues

### Critical
- `app/models/enrollment.rb:40` – `inclusion: { in: [true, false] }` missing inner spaces → RuboCop (`Layout/SpaceInsideArrayLiteralBrackets`, omakase style requires `space`) fails; write `[ true, false ]`
- `test/models/enrollment_test.rb:46` – `in_array([true, false])` same bracket-spacing violation → `[ true, false ]`
- `db/migrate/20260719064715_create_enrollments.rb:15` – `t.index [:user_id, :course_id]` same bracket-spacing violation → `[ :user_id, :course_id ]`

  (Confirmed via `bundle exec rubocop`; run `bin/rubocop -a` to autocorrect all three before committing — CLAUDE.md requires `bin/rubocop` to pass since Overcommit fails on warnings.)

### Warning
None found.

### Suggestion
- `app/models/enrollment.rb:40` – `validates :discarded_by_course, inclusion: { in: [true, false] }` has no counterpart on `Section` (same column/pattern) → consider dropping for consistency, or add the same guard to `Section` if it's intentionally stricter for `Enrollment`
- `app/models/enrollment.rb:38` – option order `comparison: { greater_than: :enrolled_at }, presence: true, if: -> { expired? }` reads more naturally as `presence: true, comparison: { greater_than: :enrolled_at }, if: -> { expired? }` (presence before comparison)
- `app/models/course.rb:107-118` – `discard_enrollments`/`restore_enrollments` do 2 writes per enrollment (`discard` + `update!`) and an `update_all` covering rows that don't need it; this exactly mirrors the existing `discard_all_sections`/`restore_sections` pattern, so not a regression, but worth revisiting both together if enrollment volume per course grows large

## Passed
- No hardcoded secrets found
- Business rules (uniqueness scope, future-date guard, expired_at requirement/comparison) match `specs/issues/22-add-enrollment-model.md` acceptance criteria
- `User` discard intentionally does NOT cascade to enrollments, matching the spec ("giữ nguyên lịch sử học tập của user")
- Migration adds proper FKs, `null: false` where required, and both the unique compound index and `discarded_at` index
- Tests cover associations, uniqueness, presence, future-date rejection, and expired-state validations
- i18n additions are complete and consistent with existing entries

## Rules applied
- Global: core.md (Single Responsibility, no magic values), index.md → clean-code.md (naming/DRY), code-style.md (formatting) via targeted lookup
- Project: CLAUDE.md (RuboCop/Overcommit requirement, discard soft-delete convention, `annotaterb` schema headers left untouched)
- Verified with `bundle exec rubocop` against changed files
