---
tags:
  - elearning
  - erd
  - diagram
  - phase-1
---

# ERD Diagram — Phase 1

> 📎 [[20-Projects/elearning/erd|ERD Text]] · [[20-Projects/elearning/story|Story]] · [[20-Projects/elearning/erd-diagram-phase2|Phase 2 →]]

```mermaid
erDiagram
    users {
        bigint id PK
        string email
        integer status
        datetime last_sign_in_at
        integer sign_in_count
        datetime discarded_at
    }

    roles {
        bigint id PK
        string name
        string code
    }

    user_roles {
        bigint id PK
        bigint user_id FK
        bigint role_id FK
    }

    profiles {
        bigint id PK
        bigint user_id FK
        string full_name
        string avatar_url
        text bio
        string phone
        datetime discarded_at
    }

    course_categories {
        bigint id PK
        string name
        string slug
        bigint parent_id FK
        integer position
        datetime discarded_at
    }

    courses {
        bigint id PK
        bigint teacher_id FK
        bigint category_id FK
        string title
        string slug
        text description
        string thumbnail_url
        integer level
        integer language
        decimal price
        integer total_lessons
        integer status
        datetime published_at
        datetime discarded_at
    }

    sections {
        bigint id PK
        bigint course_id FK
        string title
        integer position
        datetime discarded_at
    }

    lessons {
        bigint id PK
        bigint section_id FK
        string title
        integer lesson_type
        text content
        string video_url
        integer duration_seconds
        integer position
        boolean is_preview
        boolean is_published
        datetime published_at
        datetime discarded_at
    }

    lesson_resources {
        bigint id PK
        bigint lesson_id FK
        string file_name
        string file_url
        datetime discarded_at
    }

    enrollments {
        bigint id PK
        bigint user_id FK
        bigint course_id FK
        integer status
        datetime enrolled_at
        datetime expired_at
        datetime discarded_at
    }

    lesson_progresses {
        bigint id PK
        bigint enrollment_id FK
        bigint lesson_id FK
        boolean completed
        datetime completed_at
        integer total_watched_seconds
        integer current_position_seconds
    }

    course_progresses {
        bigint id PK
        bigint enrollment_id FK
        decimal progress_percentage
        integer completed_lessons_count
        datetime completed_at
    }

    event_logs {
        bigint id PK
        bigint user_id FK
        string event_type
        jsonb metadata
        datetime created_at
    }

    users ||--|{ user_roles : "has"
    roles ||--|{ user_roles : "has"
    users ||--o| profiles : "has one"
    course_categories ||--o{ course_categories : "parent of"
    course_categories ||--o{ courses : "categorizes"
    users ||--o{ courses : "teaches"
    courses ||--|{ sections : "has"
    sections ||--|{ lessons : "has"
    lessons ||--o{ lesson_resources : "has"
    users ||--o{ enrollments : "enrolls"
    courses ||--o{ enrollments : "has"
    enrollments ||--|{ lesson_progresses : "tracks"
    lessons ||--o{ lesson_progresses : "tracked by"
    enrollments ||--|| course_progresses : "has one"
    users ||--o{ event_logs : "logs"
```
