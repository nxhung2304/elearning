# Design System

> Single source of truth cho UI/UX của app. Mọi view mới bám theo file này.
> CLAUDE.md chỉ giữ pointer — chi tiết ở đây.

Cảm hứng **Google Material Design 3**, hiện thực bằng **Tailwind utility classes**. Phần cuối (`Known drift`) liệt kê chỗ code hiện tại đang lệch chuẩn — sửa dần, không phải trạng thái mong muốn.

## 1. Tech & constraints

- **Tailwind CSS v4** qua CLI standalone (Propshaft + Importmap) — **không có Node/webpack build**. Source: `app/assets/tailwind/application.css`, build ra `app/assets/builds/tailwind.css`.
- **DaisyUI** (`@plugin "daisyui"`) — plugin CSS-only cho Tailwind (không kéo theo JS). Có thể dùng component class của DaisyUI khi phù hợp, nhưng **ưu tiên helper/utility của app** cho button/surface/input để đồng nhất.
- **TomSelect** — enhance `<select>` (search/multi), nạp qua importmap. Style wrapper đã override trong `application.css` (`.ts-control`, `.ts-dropdown`).
- Class động sinh từ Ruby (vd status badge) phải nằm trong safelist: `@source inline(...)` trong `application.css`. Thêm màu mới → cập nhật safelist, nếu không Tailwind purge mất.

## 2. Color roles

| Role | Màu | Dùng cho |
|---|---|---|
| Primary / success | `emerald` | CTA chính, link nhấn, trạng thái tích cực, focus ring |
| Danger / destructive | `red` | Xoá, cảnh báo, huỷ enroll |
| Neutral | `slate` | Text, surface, viền phụ |
| Accent (lesson type) | `blue` / `amber` / `purple` | video / text / mixed badge |

- Emerald là màu nhấn **duy nhất** cho hành động — không trộn slate-900 làm nút primary.
- Focus ring của input = **emerald** (không slate, không blue) — xem §6.

## 3. Layout & typography

- **Page wrapper**: `<section class="mx-auto max-w-3xl px-6 py-8">` cho trang detail/form; `max-w-6xl` cho trang index/bảng rộng.
- **Page title**: `text-2xl font-bold text-slate-900`. Header row: `mb-6 flex items-center justify-between` (title trái, action phải).
- **Breadcrumbs**: dùng helper `add_breadcrumb(label, path = nil)` ở đầu view; render qua `breadcrumbs`. Không hardcode breadcrumb markup trong view.
- **Tabs**: dùng helper `tab_link_to(label, path, active:)` (border-bottom emerald khi active). Xem `courses/_tabs.html.erb`.
- Transition luôn subtle: `transition-colors` / `transition-shadow`. Elevation & color shift khi hover, không skeuomorphic.

## 4. Surfaces

**Chuẩn: elevation, không border.**

```html
<div class="bg-white shadow-sm ring-1 ring-slate-900/5 rounded-2xl">…</div>
```

- Card, list, panel dùng ring + shadow thay vì `border`.
- Chia dòng trong surface: `divide-y divide-slate-100`.
- (Bảng index hiện đang dùng `border border-slate-200 rounded-xl` — xem Known drift, mục tiêu là chuyển về elevation.)

## 5. Buttons

**Luôn dùng helper `button_classes(variant)`** (`ApplicationHelper`) — không inline class string cho button.

| Variant | Kiểu | Dùng cho |
|---|---|---|
| `:primary` | Filled pill emerald, shadow deepen on hover | CTA chính |
| `:danger` | Filled pill red | Hành động phá huỷ chính |
| `:primary_outlined` | Outline pill emerald | Action phụ (Cancel, secondary) |
| `:danger_outlined` | Outline pill red | Huỷ/archive phụ |
| `:icon` | Ghost tròn, hover nền slate | Icon-only trung tính |
| `:icon_primary` | Ghost tròn, hover nền emerald | Icon-only tích cực (download…) |
| `:icon_danger` | Ghost tròn, hover nền red | Icon-only xoá |
| `:icon_filled` | Filled tròn emerald | Icon-only nhấn mạnh (submit upload…) |

- Icon button luôn kèm `title` + `<span class="sr-only">` cho accessibility.
- Nút icon xoá/sửa trong list: cân nhắc chỉ hiện khi `group-hover` để đỡ rối.

## 6. Inputs & forms

**Chuẩn input (Material outlined):**

```html
class="rounded-md border border-slate-300 px-3 py-2 text-sm
       focus:border-emerald-600 focus:outline-none focus:ring-1 focus:ring-emerald-600"
```

- Search field: dùng class component `.search-field` (định nghĩa trong `application.css`). **Lưu ý**: `.search-field` hiện focus ring màu slate-900 — cần đồng bộ về emerald (Known drift).
- Search/filter index: dùng `search_form_for @q` (Ransack) trong khối `flex gap-2`, submit là button phụ.
- Select có search/nhiều option: TomSelect. Status select tái dùng partial `shared/_status_select_field`.
- Label: `text-xs font-medium text-slate-500 mb-1`.

## 7. Icons

Inline SVG, style **Material Symbols / Icons outline**:

```html
<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="…" />
</svg>
```

- `stroke="currentColor"` để ăn theo màu text, `viewBox="0 0 24 24"`, `stroke-width="2"`, bo tròn line cap/join.
- Không dùng emoji trong markup thật; emoji chỉ để mô tả trong spec/wireframe.

## 8. Shared components & helpers

| Thứ | Vị trí | Công dụng |
|---|---|---|
| `render "shared/status_badge", status:` | `app/views/shared/_status_badge.html.erb` | Badge trạng thái pill; màu qua `status_badge_color` |
| `status_badge_color(status)` | `ApplicationHelper` | Map status → class màu |
| `shared/_status_select_field` | partial | Select trạng thái cho search form |
| `button_classes(variant)` | `ApplicationHelper` | §5 |
| `tab_link_to / title_for` | `ApplicationHelper` | Tab nav / tiêu đề số nhiều-ít |
| `add_breadcrumb / breadcrumbs` | `ApplicationHelper` | Breadcrumb |
| `pagy_nav(@pagy)` | Pagy | Phân trang, chỉ render khi `@pagy.pages > 1` |

## 9. Known drift (cần reconcile — KHÔNG phải chuẩn)

Đây là chỗ code hiện tại lệch so với §1–§8. Sửa dần ở issue riêng, đừng nhân bản pattern này ở view mới.

1. **Surface border vs elevation** — các bảng index (`courses/show` sections table, `sections/index`, `lessons/_table`, `lessons/index`, `my/courses/index`) dùng `rounded-xl border border-slate-200`. Chuẩn §4 là elevation (ring+shadow). `lessons/show` đã đúng chuẩn.
2. **Focus color không đồng nhất** — `.search-field` và input search dùng `focus:ring-slate-900`; TomSelect focus ra `blue`. Chuẩn §6 là emerald.
3. **Button inline ad-hoc** — "New Lesson" (`lessons/index`) dùng `bg-slate-900`; "New Section"/"New Lesson" (`courses/show`, `sections/show`) dùng `bg-emerald-600 px-3 py-1.5 text-xs` inline; submit search dùng `bg-slate-100`. Chuẩn §5 là gọi `button_classes`.
4. **status_badge_color dùng sai họ màu** — đang `green/gray/red`, chuẩn §2 là `emerald/slate/red`. Và chỉ map `active/inactive/deleted`, thiếu `completed/expired/revoked/draft/published/archived`.
5. **Scaffold `<dl>` dump attribute** — `courses/show`, `sections/show`, `lessons/show` đổ cả `position/created_at/updated_at/is_published` ra màn học. Xem issue `24-redesign-course-curriculum-ux.md` để dọn về learner-facing.
6. **"no UI framework" cũ trong CLAUDE.md** — thực tế có DaisyUI + TomSelect; §1 đã đính chính (đúng là không có Node build, nhưng có CSS plugin + JS enhance).
