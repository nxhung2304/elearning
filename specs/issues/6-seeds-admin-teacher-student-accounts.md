## **Status:**
- Review: Approved
- PR: Todo

## Metadata
- **Title:** Seeds: admin, teacher, student accounts với đúng role
- **Phase:** Phase 1 — MVP (Web)
- **GitHub Issue:** #14

---

## Description
Setup initial roles (Admin, Teacher, Student) and create sample accounts for each role to facilitate development and testing. This ensures the system has a base set of data that matches the authorization logic (CanCanCan).

---

## Acceptance Criteria
- [ ] `Role` table contains 3 records with codes: `admin`, `teacher`, `student`.
- [ ] 3 `User` records created:
    - `admin@example.com` (Role: Admin)
    - `teacher@example.com` (Role: Teacher)
    - `student@example.com` (Role: Student)
- [ ] All users have password `password`.
- [ ] Running `rails db:seed` multiple times does not create duplicate roles or users (idempotency).
- [ ] Roles are correctly associated with users through `UserRole`.

---

## Implementation Checklist
- [ ] Define role data array in `db/seeds.rb`.
- [ ] Implement role creation using `find_or_create_by!`.
- [ ] Define user data for admin, teacher, and student.
- [ ] Implement user creation and role assignment.
- [ ] Add progress messages using `puts`.

---

## Step-by-step Guide

**Files to create/modify:**
- `db/seeds.rb` — Update to include roles and sample users.

**Key decisions:**
- Role codes MUST match exactly: `admin`, `teacher`, `student` (used in `Ability` class).
- Use `find_or_create_by!` to ensure the script can be run repeatedly without failure or duplication.

**Flow:**
```
[Start Seed]
      ↓
[Create Roles] → (admin, teacher, student)
      ↓
[Create Admin User] → [Assign Admin Role]
      ↓
[Create Teacher User] → [Assign Teacher Role]
      ↓
[Create Student User] → [Assign Student Role]
      ↓
[Finish Seed]
```

**Non-obvious snippets:**

```ruby
# db/seeds.rb

def create_roles
  # 1. Define role attributes (name, code)
  # 2. Loop through and use find_or_create_by!
end

def create_users(roles)
  # 1. Define user profiles (admin, teacher, student)
  # 2. For each profile:
  #    a. find_or_initialize_by email
  #    b. set name, password
  #    c. save!
  #    d. clear existing roles and add the target role
end

# Main execution block
# puts "Starting seeding..."
# roles = create_roles
# create_users(roles)
# puts "Seeding completed!"
```

---

## Notes
- Ensure `User`, `Role`, and `UserRole` models are properly defined before running.
- Password `password` is for development convenience only.
- The `Ability` class depends on these role codes.
