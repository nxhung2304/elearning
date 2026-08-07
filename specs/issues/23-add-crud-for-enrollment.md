## Content
[CRUD] Enrollment — Student enroll, danh sách khóa đã enroll (Pagy)

## Scope

- Actor: **student only**, self-enroll (`current_user`). No admin/teacher "enroll on behalf of" action.
- Actions: `create` (enroll), `index` (My Enrollments), `show`, `destroy` (cancel).
- Teacher-facing "who's enrolled in my course" view is a **separate future issue** — not built here.
- `expired` status is **deferred** — no job or manual action sets it in this issue; enum value stays reachable in the model only.
- `completed` status is likewise out of scope — set later by the Week 5-6 progress work (`CourseProgress`/`UpdateCourseProgressJob`, roadmap lines 49-53).

## Key decisions

1. **Cancel = discard + status: revoked.** Student-initiated cancel calls `enrollment.discard` with `discarded_by_course: false` (vs `true` for the existing course-archive cascade in `Course#discard_enrollments`) **and** sets `status: :revoked`. This disambiguates "why was this enrollment ended" — course cascade vs. student's own action — using both signals together instead of leaving `status` and `discarded_at` unrelated.
2. **Re-enroll reuses the discarded row.** The unique index on `[user_id, course_id]` (`db/migrate/20260719064715_create_enrollments.rb`) is **not partial** and the model's `validates :user_id, uniqueness: { scope: :course_id }` doesn't exclude discarded rows either — a second `Enrollment.create` for the same user+course always fails uniqueness. So `EnrollmentsController#create` must: look up an existing (possibly discarded) `Enrollment` for `current_user` + `@course` first; if found, `undiscard` it and reset `status: :active, enrolled_at: Time.current, discarded_by_course: false`; if not found, create a new row.
3. **Index uses the default `.kept` scope** (`IndexableResource#set_collection` already calls `.kept` when the model responds to it) — cancelled/revoked enrollments disappear from "My Enrollments" once discarded, consistent with how `courses`/`sections` index already behaves. No override needed.
4. **Create failure redirects, doesn't render.** There's no dedicated `new` enrollment form (the Enroll button submits directly from `courses#show`), so on validation failure `create` redirects to `course_path(@course)` with `flash[:alert]`, rather than attempting to render a nonexistent form view.
5. **Ability rules** (`app/abilities/ability.rb`): resolves the existing `# TODO: change to enrollment course` comment by **not** changing the student's `Course` read rule — students keep `can :read, Course, status: :published` for the catalog/browse/enroll flow. Add: `can :create, Enrollment, user_id: user.id`, `can :read, Enrollment, user_id: user.id`, `can :destroy, Enrollment, user_id: user.id` for students. Admin's existing `can :manage, :all` already covers admin access; no separate rule needed.

## Flow diagram

```
Course#show (published, not yet enrolled)
  └─ [Enroll now] → POST /courses/:course_id/enrollment
        ├─ no prior Enrollment row       → create(status: active, enrolled_at: now)
        ├─ prior row, discarded/revoked  → undiscard + reset(status: active, enrolled_at: now, discarded_by_course: false)
        ├─ prior row, kept (already active/completed) → validation fails
        └─ on failure → redirect_to course_path(@course), flash[:alert]
        └─ on success → redirect_to course_path(@course), flash[:success]

Enrollments#index ("My Enrollments", current_user.enrollments, Pagy, .kept only)
  └─ [Show] → Enrollments#show
        └─ [Cancel enrollment] → DELETE /enrollments/:id
              → enrollment.update!(status: :revoked) + discard(discarded_by_course: false)
              → redirect_to enrollments_path, flash[:success]

Course#discard (teacher archives course) — existing cascade, unrelated trigger
  └─ discard_enrollments: enrollment.discard + discarded_by_course: true   (status untouched)
```

## Test data (factory traits needed)

```ruby
# test/factories/enrollments.rb — add trait for the cancel/re-enroll test cases
factory :enrollment do
  # ...existing default (status: active, kept)...

  trait :revoked do
    status { :revoked }
    discarded_at { Time.current }
    discarded_by_course { false }
  end
end
```

## Notes

- `expired` and `completed` statuses have no factory trait needed yet in this issue — no code path sets them here.
- Routes: nest `resource :enrollment, only: %i[create]` under `courses` in `config/routes.rb` (enroll button), plus top-level `resources :enrollments, only: %i[index show destroy]` (My Enrollments / cancel).
- Extend `status_badge_color` in `app/helpers/application_helper.rb` for `completed/expired/revoked` (currently only maps `active/inactive/deleted`).
- Wireframe (student self-enroll, My Enrollments index, show, cancel confirm) already drawn against the real app shell — see prior chat artifacts. Drop the "Expired → Re-enroll" example row since expiry is deferred.
