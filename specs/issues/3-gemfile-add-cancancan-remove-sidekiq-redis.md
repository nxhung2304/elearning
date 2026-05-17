## **Status:**
- Review: Approved
- PR: Merged

## Metadata
- **Title:** Gemfile: thêm cancancan — bỏ sidekiq, redis
- **Phase:** 1 — MVP (Web) · Week 1-2 Setup + Auth
- **GitHub Issue:** #8

---

## Description

Add `cancancan` authorization gem and remove unused `sidekiq` + `redis` gems. Background jobs are handled by Solid Queue (DB-backed, no Redis needed). `ransack` is already present in the Gemfile — no change needed.

---

## Acceptance Criteria
- [ ] `cancancan` gem is present in `Gemfile` and `Gemfile.lock`
- [ ] `sidekiq` and `redis` gems are removed from `Gemfile` and `Gemfile.lock`
- [ ] `bundle install` runs without errors
- [ ] Existing tests still pass after dependency change

---

## Implementation Checklist
- [ ] Remove `gem "sidekiq"` from `Gemfile`
- [ ] Remove `gem "redis"` from `Gemfile`
- [ ] Add `gem "cancancan"` to `Gemfile`
- [ ] Run `bundle install`
- [ ] Run `bin/rails test` to verify no regressions

---

## Step-by-step Guide

**Files to create/modify:**
- `Gemfile` — add cancancan, remove sidekiq + redis
- `Gemfile.lock` — auto-updated by `bundle install`

**Key decisions:**
- Background jobs use Solid Queue (already configured) — sidekiq/redis have no consumers in this codebase.
- `ransack` is already in the Gemfile; do not add it again.
- Add `cancancan` at top-level (not scoped to a group) — it is needed in all environments.

**Flow:**
```
Gemfile edit
  → remove gem "sidekiq"
  → remove gem "redis"
  → add    gem "cancancan"
       ↓
bundle install
  → resolves cancancan + drops sidekiq/redis from lock
       ↓
bin/rails test
  → all existing tests green
```

**Non-obvious snippets:**
```ruby
# Gemfile — final state of relevant lines (no group, alphabetical order):
gem "cancancan"
gem "devise"
gem "discard"
# ... (sidekiq and redis lines deleted)
```

---

## Notes
- `cancancan` setup (generating `Ability`, defining rules) is a separate task: "Setup: CanCanCan + Ability class".
- After removing `redis`, confirm no initializer or config references it (`config/initializers/`, `config/cable.yml`, `config/queue.yml`). Action Cable uses Solid Cable, not Redis.
- Run `bundle audit` after to verify no new vulnerable gems are introduced.
