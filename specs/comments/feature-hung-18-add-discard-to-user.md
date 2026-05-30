# Code Review: `feature/hung-#18-add-discard-to-user` → `main`

## Summary

Adds `discarded_at` column + `Discard::Model` include to the User model. Migration and schema update are correct. The test suite has one logically broken test case and one spec-file that must not be committed.

---

## Issues

### Critical

- **`specs/issues/8-fix-user-add-discard.md` is staged** — `CLAUDE.md` explicitly states "Không commit files trong `specs/`", and `.gitignore` excludes the whole `specs/` directory. This file should be unstaged before committing.

  ```bash
  git restore --staged specs/issues/8-fix-user-add-discard.md
  ```

### Warning

- **`test/models/user_test.rb:95-98` — undiscard test is a tautology.** The setup creates a fresh user (`discarded_at = nil`), and the test immediately calls `@user.undiscard` without first discarding. The `assert_nil @user.discarded_at` assertion passes trivially — it never actually tests undiscard behavior. Fix:

  ```ruby
  should "after undiscard: clear discarded_at" do
    @user.discard
    @user.undiscard

    assert_nil @user.discarded_at
    assert User.kept.include?(@user)
  end
  ```

- **`test/models/user_test.rb:82-83` — double blank line.** Ruby / Omakase style uses a single blank line between test groups. Two consecutive blank lines before the `context "discard"` block violates the project's RuboCop config (`rubocop-rails-omakase`).

- **Missing acceptance criteria coverage.** The issue spec lists `User.discarded` as required behavior but has no test for it. Add:

  ```ruby
  should "after discard a user: include user in discarded scope" do
    @user.discard
    assert User.discarded.include?(@user)
  end
  ```

### Suggestion

- **`app/models/user.rb:25` — `include Discard::Model` placed before `devise`.** The issue spec says "place it right after Devise declarations". Current order reverses that. It works either way at runtime, but the spec-intended order (`devise` → `include Discard::Model`) is more consistent with how the project's other models are structured (external gem config first, then extensions).

---

## Passed

- Migration correctly adds `discarded_at :datetime` (nullable, indexed) — right column type for the `discard` gem.
- No custom scope added manually — correctly relies on Discard's built-in default scope.
- `annotaterb` schema comments updated across all relevant files (`user.rb`, `factories/users.rb`, `user_test.rb`).
- No hardcoded secrets.
- Migration version matches `schema.rb` version bump.

## Rules applied

- Global: `core.md` (SRP, no over-engineering), `clean-code.md` §Naming, `code-style.md` §Blank Lines
- Project: `CLAUDE.md` (specs/ gitignore rule, Minitest conventions, RuboCop Omakase)
