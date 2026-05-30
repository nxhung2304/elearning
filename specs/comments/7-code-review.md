# Code Review: Issue #7 — Model Profile

## Context
- Issue: #7 / GitHub #16 — `[Model] Profile — validations, associations, i18n (en)`
- Files reviewed: `test/models/profile_test.rb`, `app/models/profile.rb`, `test/factories/profiles.rb`

---

## Passed
- `should belong_to(:user)` — correct Shoulda matcher for the association
- `should validate_presence_of(:full_name)` — matches model validation
- `test "valid factory"` — ensures factory builds cleanly, good smoke test
- Factory uses `association :user` — auto-creates user correctly, no arguments needed
- Model includes `Discard::Model`, `has_one_attached :avatar`, `belongs_to :user`

---

## Issues

### 1. Missing test: `discarded_at` scoping (Required by spec)
**Severity: High** — Acceptance criteria item is still unchecked in the issue spec.

```
specs/issues/7-model-profile.md:
  - [ ] Minitest: `discarded_at` scoping — discarded profile is excluded from `.kept`
```

**Fix — add this test:**
```ruby
test "discarded profile is excluded from kept scope" do
  profile = create(:profile)
  profile.discard

  assert_not Profile.kept.include?(profile)
  assert Profile.discarded.include?(profile)
end
```

---

### 2. Missing shoulda-matcher for uniqueness
**Severity: Medium** — `validates :user_id, uniqueness: true` exists in the model but is not covered by Shoulda matchers.

`test/models/profile_test.rb:30-32` — `context "validations"` only tests `full_name` presence.

**Fix:**
```ruby
context "validations" do
  subject { create(:profile) }   # shoulda uniqueness needs a persisted record

  should validate_presence_of(:full_name)
  should validate_uniqueness_of(:user_id)
end
```

> Note: `validate_uniqueness_of` requires a persisted subject — add `subject { create(:profile) }` inside the context.

---

### 3. Redundant `profile.save` in without-user test
**Severity: Low** — `test/models/profile_test.rb:42`

```ruby
profile.save   # ← unnecessary; the assertion only calls profile.valid?
```

`profile.valid?` reruns validations independently. The `save` call adds a DB round-trip (that fails) and can obscure intent.

**Fix:**
```ruby
test "invalid profile without user_id" do
  profile = build(:profile)
  profile.user_id = nil

  assert_not profile.valid?
end
```

---

### 4. Convoluted duplicate-user test logic
**Severity: Medium** — `test/models/profile_test.rb:46-56`

```ruby
profile_two = create(:profile)   # creates with its own user
profile_two.user = user          # reassigns to a user that already has a profile
assert_not profile_two.valid?
```

`create(:profile)` persists `profile_two` to the DB with a different user. Then reassigning `.user = user` only changes the in-memory association without persisting. The test passes but it is misleading — the assertion checks in-memory validity, not a true save-duplicate scenario.

**Fix — clearer intent:**
```ruby
test "invalid duplicate profile for same user" do
  user = create(:user)
  create(:profile, user: user)

  duplicate = build(:profile, user: user)
  assert_not duplicate.valid?
end
```

---

## Rules Applied
- Minitest: prefer `build` over `create` when persistence is not needed — reduces DB overhead
- Shoulda Matchers: uniqueness matchers require a persisted subject (`create`, not `build`)
- Test completeness: all acceptance criteria items must map to at least one test case
- Test clarity: each test should exercise exactly one scenario with the minimal setup needed
