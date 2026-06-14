## Status
- Review: pending

## Metadata
- **Title:** [CRUD] Section — Teacher CRUD nested under Course + Pagy
- **Phase:** Phase 1 — MVP (Web) · Week 3-4
- **GitHub Issue:** #15

---

## Description

Teacher CRUD cho Section, nested dưới Course (`/courses/:course_id/sections`). Model `Section` đã có sẵn — task này chỉ làm controller + views + authorization.

- Index: list sections của course hiện tại, Ransack search by title, Pagy
- Form: chỉ có field `title` — course xác định qua URL
- Show: title, course, position, timestamps

---

## Acceptance Criteria

- [ ] Teacher CRUD sections thuộc course của mình
- [ ] Teacher không truy cập được sections của course người khác (403)
- [ ] Index scoped theo course; Ransack search by title; Pagy
- [ ] Show: title, course, position, created_at, updated_at
- [ ] Unauthenticated → redirect login
- [ ] Minitest: happy path + edge cases

---

## Implementation Checklist

- [ ] `resources :courses do; resources :sections; end` trong `routes.rb`
- [ ] `SectionsController` — `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`
- [ ] CanCanCan nested: `load_and_authorize_resource :course` + `load_and_authorize_resource :section, through: :course`
- [ ] `ability.rb` — Teacher: `can :manage, Section, course_id: Course.kept.where(teacher_id: user.id).ids`
- [ ] Views: `index`, `show`, `_form` (title only), `new`, `edit`
- [ ] Ransack `title_cont` + Pagy trên index
- [ ] i18n keys trong `en.yml`
- [ ] `test/controllers/sections_controller_test.rb`
- [ ] `bin/rubocop` + `bin/rails test` — all green

---

## Navigation Flow

```
Course#show
    └── [Sections] link
            └── Section#index  (/courses/:id/sections)
                    ├── [New Section]  → Section#new  → Section#show
                    ├── [Edit]         → Section#edit → Section#show
                    └── [Delete]       → Section#index
```

---

## Wireframe

**Index** — `/courses/:id/sections`
```
← Back to Course: Rails Fundamentals

Sections                              [+ New Section]
────────────────────────────────────────────────────
[Search by title...]  [Search]

  Title                   Position   Actions
  ──────────────────────────────────────────
  Introduction            1          Show · Edit · Delete
  Setup & Installation    2          Show · Edit · Delete
  Core Concepts           3          Show · Edit · Delete

  < 1 2 3 >
```

**New / Edit Form**
```
← Back to Sections

New Section
───────────
Title  [                        ]

       [Save]
```

**Show**
```
← Back to Sections

Introduction
────────────────────
Course      Rails Fundamentals
Position    1
Created     21 Jun 2026
Updated     21 Jun 2026

                    [Edit]  [Delete]
```

---

## Key Decisions

- **Nested route** — Section không tồn tại độc lập, luôn thuộc về một Course → `/courses/:course_id/sections` tự nhiên hơn standalone.
- **CanCanCan `through: :course`** — tự động build `@course.sections.build(section_params)` trên `new`/`create`, không cần set course thủ công.
- **Ability dùng `.ids`** — `can :manage, Section, course_id: Course.kept.where(...).ids` vì CanCanCan không hỗ trợ hash condition qua join (`course: { teacher_id: }`) khi dùng `accessible_by`.
- **Không có course selector** — course đã implicit từ URL, form chỉ cần `title`.
- **`position` read-only** — managed bởi `positioned` gem (scoped to course). Không nhận qua params.
- **Ransack chỉ `title_cont`** — không cần `ransackable_associations` vì không join sang bảng khác.
- **Redirects** — create/update → `course_section_url(@course, @section)`; destroy → `course_sections_url(@course)`.
