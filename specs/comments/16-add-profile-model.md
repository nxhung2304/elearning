# Code Review: feature/hung-#16-add-profile-model → main

## Summary

Profile model is well-structured overall — soft delete, Active Storage, and DB-level uniqueness are all in place. Two issues need addressing before merge: a `dependent: :destroy` that conflicts with the soft-delete contract, and dual avatar storage mechanisms in the same commit.

---

## Issues

### Critical

- `app/models/user.rb:24` — `has_one :profile, dependent: :destroy` violates the soft-delete contract. CLAUDE.md explicitly states: *"Do not use `dependent: :destroy` where soft-delete is expected."* Profile includes `Discard::Model`, so destroying the record bypasses the discard pattern entirely. Change to `dependent: :nullify` or simply omit `dependent:` and handle cleanup separately.

### Warning

- `app/models/profile.rb:25` + `db/migrate/20260519113432_create_profiles.rb:9` — Both `has_one_attached :avatar` (Active Storage) and `t.string :avatar_url` (raw URL column) exist simultaneously. These are two separate avatar storage mechanisms. Decide on one: if using Active Storage, drop the `avatar_url` column and remove it from the factory/locale; if using a URL column, remove `has_one_attached :avatar`.

- `test/factories/profiles.rb:27` — Factory sets `avatar_url` with a Faker URL. If Active Storage is the chosen path, this attribute will map to a DB column that should be dropped — the factory will then fail or generate misleading data.

### Suggestion

- `app/models/profile.rb:29` — `validates :user_id, presence: true` is redundant. `belongs_to :user` already validates presence of `user_id` by default in Rails 5+. Keep only `validates :user_id, uniqueness: true`.

---

## Passed

- DB-level `null: false` on `full_name` matches model validation.
- `UNIQUE` index on `user_id` enforced at DB level — correctly mirrors model uniqueness validation.
- `Discard::Model` included correctly; `discarded_at` column present in migration.
- Locale translations (`en.yml`) added for all profile attributes.
- Factory uses `Faker` for all fields — no hardcoded values.
- Test file covers associations, validations, and discard behaviour.
- No hardcoded secrets or sensitive data.

---

## Rules Applied

- Global: `core.md` (Single Responsibility, no over-engineering)
- Project: CLAUDE.md — soft-delete contract (`discard` gem usage)
- Rails: `belongs_to` implicit presence validation (Rails 5+)
