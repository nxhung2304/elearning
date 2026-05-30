# ERD

> 📎 [[20-Projects/elearning/Roadmap|Roadmap]] · [[20-Projects/elearning/story|Story]] · [[20-Projects/elearning/architecture|Architecture]]

> **Soft delete convention**: Tất cả model chính có `discarded_at :datetime` (Discard gem)
> Default scope là `.kept` — query tự động bỏ qua records đã discard

---

# Phase 1 — MVP Tables

### users
```
- id                          # bigint, PK
- email                       # string, not null, uniq, index
- encrypted_password          # string, not null (Devise managed)
- status                      # integer enum, not null, default: active
    - active
    - inactive
    - suspended
    - deleted
- last_sign_in_at             # datetime, nullable (Devise managed)
- sign_in_count               # integer, not null, default: 0 (Devise managed)
- discarded_at                # datetime, nullable — soft delete
```

### roles
```
- id                          # bigint, PK
- name                        # string, not null
- code                        # string, not null, uniq — student | teacher | admin
```

### user_roles
```
- id                          # bigint, PK
- user_id                     # bigint, not null, FK → users
- role_id                     # bigint, not null, FK → roles
# uniq index on [user_id, role_id]
```

### profiles
```
- id                          # bigint, PK
- user_id                     # bigint, not null, uniq, FK → users
- full_name                   # string, not null
- avatar_url                  # string, nullable
- bio                         # text, nullable
- phone                       # string, nullable
- discarded_at                # datetime, nullable — soft delete
```

### course_categories
```
- id                          # bigint, PK
- name                        # string, not null
- slug                        # string, not null, uniq, index
- parent_id                   # bigint, nullable, FK → course_categories (self-ref)
- position                    # integer, not null, default: 0 — sort order within siblings
- discarded_at                # datetime, nullable — soft delete
```

### courses
```
- id                          # bigint, PK
- teacher_id                  # bigint, not null, FK → users
- category_id                 # bigint, not null, FK → course_categories
- title                       # string, not null, uniq, index
- slug                        # string, not null, uniq, index — auto-generated from title
- description                 # text, not null
- thumbnail_url               # string, nullable — ActiveStorage local
- level                       # integer enum, not null: beginner | intermediate | advanced
- language                    # integer enum, not null: vi | en
- price                       # decimal(10,2), not null, default: 0
- total_lessons               # integer, not null, default: 0 — denormalized, updated qua job
- status                      # integer enum, not null, default: draft
    - draft
    - published
    - archived
- published_at                # datetime, nullable — set khi status → published
- discarded_at                # datetime, nullable — soft delete
```

### sections
```
- id                          # bigint, PK
- course_id                   # bigint, not null, FK → courses
- title                       # string, not null
- position                    # integer, not null, default: 0 (acts_as_list)
- discarded_at                # datetime, nullable — soft delete
```

### lessons
```
- id                          # bigint, PK
- section_id                  # bigint, not null, FK → sections
- title                       # string, not null
- lesson_type                 # integer enum, not null — video | text | mixed
- content                     # text, nullable (required if type = text | mixed)
- video_url                   # string, nullable — ActiveStorage local (required if type = video | mixed)
- duration_seconds            # integer, nullable (required if video_url present)
- position                    # integer, not null, default: 0 (acts_as_list)
- is_preview                  # boolean, not null, default: false
- is_published                # boolean, not null, default: false
- published_at                # datetime, nullable
- discarded_at                # datetime, nullable — soft delete
```

### lesson_resources
```
- id                          # bigint, PK
- lesson_id                   # bigint, not null, FK → lessons
- file_name                   # string, not null
- file_url                    # string, nullable — ActiveStorage local
- discarded_at                # datetime, nullable — soft delete
```

### enrollments
```
- id                          # bigint, PK
- user_id                     # bigint, not null, index, FK → users
- course_id                   # bigint, not null, index, FK → courses
- status                      # integer enum, not null
    - active
    - completed
    - expired
    - revoked
- enrolled_at                 # datetime, not null
- expired_at                  # datetime, nullable
- discarded_at                # datetime, nullable — soft delete
# uniq index on [user_id, course_id]
# payment_id KHÔNG có ở Phase 1 — thêm vào migration Phase 2
```

### lesson_progresses
```
- id                          # bigint, PK
- enrollment_id               # bigint, not null, FK → enrollments
- lesson_id                   # bigint, not null, FK → lessons
- completed                   # boolean, not null, default: false
- completed_at                # datetime, nullable (required if completed = true)
- total_watched_seconds       # integer, nullable
- current_position_seconds    # integer, nullable
```

### course_progresses
```
- id                          # bigint, PK
- enrollment_id               # bigint, not null, uniq, FK → enrollments (1-1)
- progress_percentage         # decimal, not null, default: 0
- completed_lessons_count     # integer, not null, default: 0
- completed_at                # datetime, nullable — set khi progress_percentage = 100
```

### event_logs
```
- id                          # bigint, PK
- user_id                     # bigint, not null, FK → users
- event_type                  # string, not null
- metadata                    # jsonb, nullable
- created_at                  # datetime, not null (no updated_at — append-only)
```

---

# Phase 2 — Thêm dần

```
# Migration: thêm payment_id vào enrollments
enrollments
+ payment_id                  # nullable FK → payments

payments
- id
- user_id
- amount
- currency
- provider
- status
    - pending
    - processing
    - paid
    - failed
    - refunded
    - cancelled
- paid_at

payment_transactions
- id
- payment_id
- transaction_code
- provider_response
- status
    - pending
    - success
    - failed
    - cancelled
    - timeout
    - refunded
- raw_payload

quizzes
- id
- lesson_id
- title
- passing_score
- discarded_at

quiz_questions
- id
- quiz_id
- question
- question_type
- position
- discarded_at

quiz_options
- id
- quiz_question_id
- content
- correct
- discarded_at

quiz_attempts
- id
- enrollment_id
- quiz_id
- score
- status
    - in_progress
    - submitted
    - passed
    - failed
- started_at
- submitted_at

quiz_answers
- id
- quiz_attempt_id
- quiz_question_id
- quiz_option_id
- answer_text
- correct

course_reviews
- id
- user_id
- course_id
- rating                      # 1-5
- comment
- discarded_at

tags
- id
- name
- slug
- discarded_at

course_tags
- id
- course_id
- tag_id
```

---

# Phase 3 — Thêm dần

```
certificates
- id
- enrollment_id
- certificate_code            # UUID hoặc custom format
- issued_at

wishlists
- id
- user_id
- course_id

notifications
- id
- user_id
- title
- body
- notification_type
- read_at
- discarded_at

admin_logs
- id
- admin_id
- action                      # ban_user | unpublish_course | ...
- target_type                 # polymorphic
- target_id
- metadata
- created_at
```

---

# Phase 5 — API (thêm khi lên Mobile)

```
# Migration: thêm jti vào users
users
+ jti                         # devise-jwt JTI matcher

jwt_denylists
- id
- jti
- exp                         # để cleanup cron job
```

---

# Relations

```
User
  include Discard::Model
  has_many :user_roles
  has_many :roles, through: :user_roles
  has_one  :profile
  has_many :courses             # as teacher
  has_many :enrollments
  has_many :payments            # Phase 2
  has_many :notifications       # Phase 3
  has_many :course_reviews      # Phase 2
  has_many :wishlists           # Phase 3

Role
  has_many :user_roles
  has_many :users, through: :user_roles

CourseCategory
  include Discard::Model
  belongs_to :parent, optional: true
  has_many   :children, class_name: 'CourseCategory', foreign_key: :parent_id
  has_many   :courses

Course
  include Discard::Model
  belongs_to :teacher (User)
  belongs_to :category (CourseCategory)
  has_many   :sections
  has_many   :lessons, through: :sections
  has_many   :enrollments
  has_many   :course_tags       # Phase 2
  has_many   :tags, through: :course_tags
  has_many   :course_reviews    # Phase 2
  has_many   :wishlists         # Phase 3

Section
  include Discard::Model
  belongs_to :course
  has_many   :lessons

Lesson
  include Discard::Model
  belongs_to :section
  has_many   :lesson_resources
  has_one    :quiz              # Phase 2

Enrollment
  include Discard::Model
  belongs_to :user
  belongs_to :course
  belongs_to :payment, optional: true   # Phase 2
  has_many   :lesson_progresses
  has_one    :course_progress
  has_many   :quiz_attempts     # Phase 2
  has_one    :certificate       # Phase 3

LessonProgress
  belongs_to :enrollment
  belongs_to :lesson

Quiz / QuizQuestion / QuizOption / QuizAttempt / QuizAnswer
  # Phase 2, Quiz/QuizQuestion/QuizOption include Discard::Model

Payment
  belongs_to :user
  has_many   :payment_transactions

Certificate
  belongs_to :enrollment
```

---

# Domain Boundaries

```
Identity
- users, profiles, roles, user_roles

Learning
- courses, course_categories, sections, lessons, lesson_resources
- enrollments, lesson_progresses, course_progresses

Quiz (Phase 2)
- quizzes, quiz_questions, quiz_options, quiz_attempts, quiz_answers

Payment (Phase 2)
- payments, payment_transactions

Social (Phase 2-3)
- course_reviews, wishlists, tags, course_tags

Infrastructure
- event_logs
- notifications, admin_logs (Phase 3)
- jwt_denylists (Phase 5)
```
