# ERD

> 📎 [[20-Projects/elearning/Roadmap|Roadmap]] · [[20-Projects/elearning/story|Story]] · [[20-Projects/elearning/architecture|Architecture]]

> **Soft delete convention**: Tất cả model chính có `discarded_at :datetime` (Discard gem)
> Default scope là `.kept` — query tự động bỏ qua records đã discard

---

# Phase 1 — MVP Tables

```
users
- id
- email
- encrypted_password
- status
    - active
    - inactive
    - suspended
    - deleted
- last_sign_in_at             # Devise managed
- sign_in_count               # Devise managed
- discarded_at                # soft delete

roles
- id
- name
- code                        # student | teacher | admin

user_roles
- id
- user_id
- role_id

profiles
- id
- user_id
- full_name                    # not null
- avatar_url
- bio
- phone
- discarded_at

course_categories
- id
- name
- slug
- parent_id                   # nullable — nested category
- discarded_at

courses
- id
- teacher_id
- category_id
- title
- slug
- description
- thumbnail_url               # ActiveStorage local
- level                       # beginner | intermediate | advanced
- language                    # vi | en
- price
- total_lessons               # denormalized, updated qua job
- status
    - draft
    - published
    - archived
- published_at
- discarded_at

sections
- id
- course_id
- title
- position
- discarded_at

lessons
- id
- section_id
- title
- lesson_type                 # video | text | mixed
- content
- video_url                   # ActiveStorage local
- duration_seconds
- position
- is_preview
- is_published
- published_at
- discarded_at

lesson_resources
- id
- lesson_id
- file_name
- file_url                    # ActiveStorage local
- discarded_at

enrollments
- id
- user_id
- course_id
- status
    - active
    - completed
    - expired
    - revoked
- enrolled_at
- expired_at
- discarded_at
# payment_id KHÔNG có ở Phase 1 — thêm vào migration Phase 2

lesson_progresses
- id
- enrollment_id
- lesson_id
- completed
- completed_at
- total_watched_seconds
- current_position_seconds

course_progresses
- id
- enrollment_id
- progress_percentage
- completed_lessons_count
- completed_at

event_logs
- id
- user_id
- event_type
- metadata
- created_at
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
