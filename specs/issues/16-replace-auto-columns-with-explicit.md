## Status
- Review: Approved

## Metadata
- **Title:** [Refactor] Remove auto-generated column helpers — hardcode fields in views
- **Phase:** Phase 1 — MVP (Web)
- **GitHub Issue:** #34

---

## Description

Xóa toàn bộ logic tự động sinh field list từ schema, thay bằng hardcode tường minh trong từng view. Labels dùng `Model.human_attribute_name(:field)`.

**Hiện tại (dynamic — cần xóa):**
```erb
<% Course.index_columns.each do |col| %>
  <th><%= Course.human_attribute_name(col) %></th>
<% end %>
```

**Sau refactor (manual — target):**
```erb
<th><%= Course.human_attribute_name(:title) %></th>
<th><%= Course.human_attribute_name(:category) %></th>
<th><%= Course.human_attribute_name(:status) %></th>
<th><%= Course.human_attribute_name(:price) %></th>
```

---

## Pattern chuẩn sau refactor

**Index table** — hardcode từng `<th>` và `<td>`:
```erb
<thead>
  <tr>
    <th ...><%= Model.human_attribute_name(:title) %></th>
    <th ...><%= Model.human_attribute_name(:status) %></th>
    <th ...></th><%# actions %>
  </tr>
</thead>
<tbody>
  <% @records.each do |record| %>
    <tr>
      <td ...><%= record.title %></td>
      <td ...><%= record.status %></td>
      <td ...><%# actions %></td>
    </tr>
  <% end %>
</tbody>
```

**Show page** — hardcode từng `<dt>/<dd>`:
```erb
<dl ...>
  <div ...>
    <dt ...><%= Model.human_attribute_name(:title) %></dt>
    <dd ...><%= @record.title %></dd>
  </div>
  <div ...>
    <dt ...><%= Model.human_attribute_name(:created_at) %></dt>
    <dd ...><%= @record.created_at&.strftime("%Y-%m-%d %H:%M") %></dd>
  </div>
</dl>
```

**Form** — hardcode từng `f.input`:
```erb
<%= f.input :title %>
<%= f.input :status, as: :select, collection: Course.statuses.keys, include_blank: false %>
<%= f.input :category_id, as: :select, collection: CourseCategory.kept.map { |c| [c.name, c.id] } %>
```

---

## Files cần thay đổi

### Views (11 files)

| File | Thay thế |
|---|---|
| `app/views/course_categories/index.html.erb` | `visible_columns.each` loop → hardcode `<th>/<td>` |
| `app/views/course_categories/show.html.erb` | `visible_columns.each` + `timestamp_columns.each` → hardcode `<dt>/<dd>` |
| `app/views/course_categories/_form.html.erb` | `visible_columns.each` loop → hardcode `f.input` |
| `app/views/courses/index.html.erb` | `index_columns.each` + `display_resource_columns` → hardcode `<th>/<td>` |
| `app/views/courses/show.html.erb` | `visible_columns.each` + `timestamp_columns.each` → hardcode `<dt>/<dd>` |
| `app/views/courses/_form.html.erb` | `form_columns.each` loop với heuristic `_id`/enum → hardcode `f.input` |
| `app/views/profiles/_form.html.erb` | `visible_columns.each` loop → hardcode `f.input` |
| `app/views/sections/index.html.erb` | `index_columns.each` + `display_resource_columns` → hardcode `<th>/<td>` |
| `app/views/users/index.html.erb` | `visible_columns.each` loop → hardcode `<th>/<td>` |
| `app/views/users/show.html.erb` | `visible_columns.each` + `timestamp_columns.each` → hardcode `<dt>/<dd>` |
| `app/views/users/_form.html.erb` | `visible_columns.each` loop → hardcode `f.input` |

### Helper (1 file)

`app/helpers/application_helper.rb` — xóa `display_resource_columns` và `display_columns_by_type` (chúng phụ thuộc vào `index_columns`).

### Models (3 files — xóa overrides)

| File | Xóa |
|---|---|
| `app/models/course_category.rb` | `visible_columns`, `form_columns`, `index_columns` overrides |
| `app/models/course.rb` | `visible_columns`, `form_columns`, `index_columns` overrides |
| `app/models/profile.rb` | `visible_columns`, `form_columns`, `index_columns` overrides |

### ApplicationRecord (1 file — xóa methods)

`app/models/application_record.rb` — xóa:
- `form_columns`
- `visible_columns`
- `index_columns`
- `timestamp_columns`

---

## Acceptance Criteria

- [ ] Không còn `index_columns`, `visible_columns`, `form_columns`, `timestamp_columns` ở bất kỳ đâu trong codebase
- [ ] Không còn `display_resource_columns` helper
- [ ] Tất cả views render đúng fields, đúng labels (dùng `human_attribute_name`)
- [ ] Sensitive fields không xuất hiện trên bất kỳ view nào
- [ ] `bin/rubocop` + `bin/rails test` — all green

---

## Implementation Checklist

- [ ] Xóa 4 methods khỏi `app/models/application_record.rb`
- [ ] Xóa overrides khỏi `course_category.rb`, `course.rb`, `profile.rb`
- [ ] Xóa `display_resource_columns` + `display_columns_by_type` khỏi `application_helper.rb`
- [ ] Rewrite `course_categories/index.html.erb`
- [ ] Rewrite `course_categories/show.html.erb`
- [ ] Rewrite `course_categories/_form.html.erb`
- [ ] Rewrite `courses/index.html.erb`
- [ ] Rewrite `courses/show.html.erb`
- [ ] Rewrite `courses/_form.html.erb`
- [ ] Rewrite `profiles/_form.html.erb`
- [ ] Rewrite `sections/index.html.erb`
- [ ] Rewrite `users/index.html.erb`
- [ ] Rewrite `users/show.html.erb`
- [ ] Rewrite `users/_form.html.erb`
- [ ] `bin/rubocop`
- [ ] `bin/rails test`

---

## Key Decisions

- **View là single source of truth**: không có field config ở model — view tự quyết định render gì.
- **`human_attribute_name` cho labels**: i18n-ready, không hardcode string.
- **Xóa `display_resource_columns`**: helper này wrap `index_columns` — khi loop biến mất, helper cũng không còn lý do tồn tại.
- **Không xóa `RANSACK_DENYLIST`**: vẫn dùng cho `ransackable_attributes` — không liên quan đến task này.
