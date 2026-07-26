# Admin Portal — Remaining 7 Screens Roadmap

- **Date:** 2026-05-17
- **Author:** Claude (Opus 4.7)
- **Status:** executed (all 7 screens shipped in their own CRs — Users, Admins, Branches, Logic, Accessories, Models, Dress)

## Purpose

This is **planning only** — a single document scoping every remaining
admin-portal screen so we have visibility on what's ahead before
executing. Each section below becomes its own ChangeRequest +
implementation in execution order. The agreed phasing is **one screen
per plan**: Users → Admins → Branches → Logic → Accessories → Models →
Dress. The Dashboard (already executed) and Login + Settings (foundation)
are out of scope here.

All seven screens consume `MockDataService` for now — the eventual
swap to AngularFire-backed services is its own follow-up plan ("Real
Firestore wiring"). All screens use the existing
`src/styles/_design.scss` (1464 lines of Claude Design CSS) and the
14 UI primitives + `<app-icon>` from the foundation. No new SCSS work
is anticipated except per-screen local styles where the design uses
unique selectors.

Design source files (extracted to `/tmp/saf-handoff2/...` from the
user's handoff zip):

- `/tmp/saf-handoff2/saf-uniforms/project/src/admin/config-screens.jsx`
  → Users, Admins, Branches, Logic, (Settings — done)
- `/tmp/saf-handoff2/saf-uniforms/project/src/admin/accessories.jsx`
- `/tmp/saf-handoff2/saf-uniforms/project/src/admin/models.jsx`
- `/tmp/saf-handoff2/saf-uniforms/project/src/admin/dress.jsx`

---

## Screen 1 — App Users (`/users`) — Complexity: **S**

**Source:** `config-screens.jsx` → `UsersScreen` + `UserDrawer`

**Scope:**
- Page header (eyebrow + title + subtitle, no actions — read-only).
- Toolbar: search input (filter by uid / device / branch) + two
  `app-pill-toggle` filter groups (branch: All / Army / Navy / RSAF / DIS;
  profile complete: All / Complete / Incomplete).
- Table: 7 columns — UID (truncated, with copy icon), Device,
  Platform (iOS / Android chip), Branch (`<app-branch-dot>` + name),
  Profile (✓ / ✗ icon), Last Seen, chevron-right for drawer open.
- Per-row click → side drawer with read-only profile data + 3 stat
  cards (sessions, models generated, last activity).

**Data:** `MockDataService.appUsers()` (8 mock rows). Future Firestore
listener on `users/{uid}` collection.

**Components used:** PageHeader (inline), Input, PillToggle, Icon,
BranchDot, Chip, Avatar. New: a thin **Drawer** primitive (slide-in
right panel) — could also be a wide Modal variant.

**New i18n keys:** ~25 under `users.*` (column headers, filter labels,
drawer field labels, copy / share actions, empty state).

**Acceptance:** table renders 8 mock rows; search filters live;
clicking a row opens the drawer; theme switch (dark / light) keeps
contrast correct.

**Dependencies:** none.

---

## Screen 2 — Admin Accounts (`/admins`) — Complexity: **M**

**Source:** `config-screens.jsx` → `AdminAccountsScreen`

**Scope:**
- Page header with **Add Admin** button (gold primary).
- Info banner above the table: "Admin accounts are managed in Firebase
  Auth. Creating an admin here mints a Firebase user and adds them to
  the `admins` collection."
- Table: 8 columns — Avatar (super = gold gradient), Name, Email, Role
  (Super / Admin chip), Created, Last Login, Status toggle, kebab menu
  (Disable / Reset password / Delete).
- "Add Admin" modal: 3 fields — Full Name, Email, Role pill toggle.
  Submit raises a toast "Admin created" (mock; real Firebase Admin SDK
  call is a Cloud Function in a later plan).

**Data:** `MockDataService.admins()` (3 mock rows).

**Components used:** Button, Input, Field, Modal, PillToggle, Avatar,
Chip, Toggle, Icon. New: a small **KebabMenu** (popover with action
list) — implementable as a one-off here, generalised later if needed.

**New i18n keys:** ~30 under `admins.*` (columns, role labels, modal
fields, kebab actions, status descriptions).

**Acceptance:** table renders; "Add Admin" modal opens, validates,
closes on submit; status toggle flips visually; kebab menu opens with
3 actions (all UI-only — disable / reset / delete each fire toasts
"coming in follow-up plan").

**Dependencies:** none (Modal primitive already exists; KebabMenu is
small enough to inline).

---

## Screen 3 — Branch Config (`/branches`) — Complexity: **M**

**Source:** `config-screens.jsx` → `BranchConfigScreen` + `BranchCard` + `CfgSection`

**Scope:**
- Page header (no actions).
- 4-column responsive grid (collapses to 2 cols ≤ 980 px, 1 col ≤ 760 px).
- Each card represents one branch (Army / Navy / RSAF / DIS) with:
  - Header: branch dot + name + version chip.
  - 5 collapsible config sections via reusable `<app-cfg-section>`:
    1. **Collar Offset** — number input (cm) with suffix.
    2. **Ladies Medal Anchor** — Select (anchor name) + 2 number inputs
       (X / Y offset cm).
    3. **Sikh Turban Logic** — Toggle (enabled) + color input + Select
       (override mode).
    4. **Dress Codes Enabled** — multi-select pill toggles for No.1–No.5.
    5. (one reserved slot in the design — empty for now).
  - Footer: "last saved · …" mono tag + Save button.
- Local state per card: editing values are buffered; Save fires a toast
  (mock write — real Firestore write in a later plan).

**Data:** Hardcoded `BRANCH_DEFAULTS` object inlined in the component
(matches the design's source). The four `Branch[]` rows come from
`MockDataService.branches()` for the header dot + name.

**Components used:** Card, Field, Input, Select, Toggle, PillToggle,
Chip, BranchDot, MonoTag, Button. New: **CfgSection** (collapsible
section with eyebrow header + chevron + animated panel) — small one-off
component.

**New i18n keys:** ~40 under `branches.*` (5 section titles + ~6 field
labels each + suffixes / hints + 4 toolbar / save messages).

**Acceptance:** 4 cards render side-by-side; sections expand/collapse
smoothly; inputs accept values; Save button is disabled until any
input changes; theme switch preserves all colours.

**Dependencies:** none.

---

## Screen 4 — Logic Rules (`/logic`) — Complexity: **L**

**Source:** `config-screens.jsx` → `LogicRulesScreen` + `RuleCard` + `JsonEditor`

**Scope:**
- Page header with **Add Rule** primary button.
- Vertical stack of rule cards. Each card:
  - Header: rule id (mono) + Active/Inactive chip + version + edit
    toggle button (icon).
  - Body: description textarea (editable) + params view.
  - **Params view** has two modes:
    - **Form view** (default) — pretty-printed key/value grid.
    - **JSON editor** (toggled) — Monaco code editor with JSON syntax,
      auto-formatting, validation; fixed height ~280 px.
  - Footer: Delete (danger-ghost) + Save (primary) buttons.
- "Add Rule" modal: 3 fields — Rule ID input (validates against
  existing ids), description textarea, params JSON editor.

**Data:** `MockDataService.logicRules()` (4 mock rows).

**Components used:** Card, Button, Input, Field, Modal, Chip, IconBtn,
Toggle. New:
- **JsonEditor** — wraps Monaco. **New dependency:**
  `monaco-editor` + `ngx-monaco-editor-v2` (or a thinner alternative
  like `@codemirror/lang-json`).
- **CodeChip** — mono inline chip for rule ids.

**New i18n keys:** ~25 under `logic.*` (table-style labels, modal
fields, toggle labels, validation messages).

**Acceptance:** 4 rule cards render; toggling form ↔ JSON editor
works; valid JSON saves cleanly; invalid JSON shows the editor's
inline validation; "Add Rule" modal validates rule id uniqueness.

**Dependencies:** Monaco install. **Risk note:** Monaco adds ~2 MB to
the lazy chunk. Confirm bundle budget tolerates it before merging
(may need a per-route budget override in `angular.json`).

---

## Screen 5 — Accessory Library (`/accessories`) — Complexity: **L**

**Source:** `accessories.jsx` (422 lines)

**Scope:**
- Page header with **Add Accessory** primary button.
- Toolbar: search input + 3 filter pill groups (category, branch,
  gender) + sort-by select.
- Table (filterable, sortable): 8 columns — ID (mono, copy), Name,
  Category chip, Branch + dot, Gender, Image (✓/✗ thumbnail preview),
  GLB (✓/✗ + size if uploaded), Placeable, Legacy.
- Click row → side drawer with per-accessory detail:
  - Image preview + placement diagram side by side (or stacked on
    mobile).
  - Metadata fields (read-only).
  - 3 action buttons: Upload Image, Upload Placement, Upload GLB
    (UI-only; upload flow is a follow-up — would write to
    `gs://saf-uniforms.firebasestorage.app/accessories/{id}/...`).
- "Add Accessory" modal: ~10 fields driven by the Accessory shape +
  branch + category selects.

**Data:** `MockDataService.accessories()` (17 mock rows) +
`MockDataService.accessoryCategories()` (12 categories) +
`MockDataService.branches()` (for filter options + drawer).

**Components used:** Button, Input, Select, PillToggle, Field, Modal,
Chip, BranchDot, Icon. Reuses the Drawer pattern from Users (so do
Users first — Drawer becomes a shared primitive).

**New i18n keys:** ~50 under `accessories.*` (column headers, 12
category labels, filter labels, drawer fields, modal fields, upload
button labels).

**Acceptance:** all 17 rows render; search + 3 filters compose
correctly; click opens the drawer; "Add Accessory" modal validates.
Theme switch keeps row hover + chip contrast intact.

**Dependencies:** Drawer primitive (shared with Users — implement once,
reuse here).

---

## Screen 6 — 3D Models (`/models`) — Complexity: **L**

**Source:** `models.jsx` (267 lines)

**Scope:**
- Page header (no actions; per-tab actions live in each tab).
- **4-tab `<app-pill-toggle>` tab bar** at the top:
  - **Bodies** — 3 cards (male / female / female-maternity) with model
    preview placeholder + status chip (Artist Delivery / Placeholder) +
    file metadata + 3 buttons (Upload New, Download, View Full). Click
    "View Full" opens a large modal with `<model-viewer>` + a
    14-socket validation panel (check/x icons per socket).
  - **Uniforms** — 4×5 status matrix (branches × dress codes); each
    cell either shows file size + date + 2 buttons (Replace, Download)
    or shows "MISSING" + a Suggested filename + Upload button.
  - **Accessories** — full-width table (8 cols) listing every
    accessory with GLB status — uploaded / placeholder / missing.
  - **Placeholder** — info banner + large viewer frame + sidebar with
    file metadata (4 rows) + 2 action buttons.
- **`<model-viewer>` integration:** add the `<model-viewer>` web
  component via the `@google/model-viewer` npm package (loaded as a
  custom element via Angular `CUSTOM_ELEMENTS_SCHEMA` on the Models
  module/component). Bodies tab + Placeholder tab use it; tabs that
  don't render 3D just show placeholder thumbnails.

**Data:** Hardcoded `BODIES` + `UNIFORM_GRID` (matches design source) +
`MockDataService.accessories()` for the Accessories tab +
`MockDataService.sockets()` for the socket validation panel.

**Components used:** Button, Card, Chip, Modal, PillToggle, Icon,
BranchDot. New:
- **`<model-viewer>` element** (`@google/model-viewer` dep).
- **TabRouter** — internal tab state via Angular signals (no separate
  routes).
- **SocketValidationPanel** — list of socket names with check / cross
  icons.

**New i18n keys:** ~60 under `models.*` (tab labels, status labels,
column headers, upload suggestions, socket names if translated —
likely not, since socket ids are technical).

**Acceptance:** all 4 tabs render and switch; Bodies tab loads at
least one `male_apose.glb` from `gs://saf-uniforms.firebasestorage.app/models/bodies/`
in the viewer (auth-required Storage read; will need a tokened URL or
authenticated fetch). Socket panel shows checks for present sockets.

**Dependencies:** `@google/model-viewer` install. **Risk note:**
~150 KB extra lazy chunk; mitigated by route-level lazy loading.
Storage rules already allow auth-required reads on `models/**`
(per `storage.rules`), but we need to either (a) fetch via the
`Storage` SDK's `getDownloadURL` which mints a token, or (b) include
the user's ID token. `getDownloadURL` is simpler.

---

## Screen 7 — Dress Requirements (`/dress`, `/dress/add`, `/dress/:id`) — Complexity: **XL**

**Source:** `dress.jsx` (512 lines — the largest screen)

**Three routes, three sub-components:**

### 7a — `/dress` — Dress List
- Page header with **Add Dress** primary button.
- Two filter pill groups: dress code (All / No.1 / No.2 / No.3 / No.4 /
  No.5) + status (All / Live / Placeholder / Draft).
- Grid of dress cards (4 columns ≤ 1280; 3 ≤ 980; 2 ≤ 760; 1 ≤ 480).
- Each card: code pill (top-left) + status chip (top-right) + title +
  metadata row (overrides count, mandatory count, optional count) +
  branch dots row + kebab menu (Edit, Duplicate, Archive).
- Empty state when filters return zero.

### 7b — `/dress/add` — 3-Step Wizard
- **Step indicator bar** at top (Upload → Review → Finalise; ovals
  with connector lines, gold = active, gold-faint = completed).
- **Step 1 — PDF Drop & Metadata:**
  - Big drag-drop zone (`.pdf-dropzone`) with file-up icon, "Drop a
    PDF here or browse" copy, max 25 MB hint.
  - Below: dress code select + dress name input.
  - Continue button enables only when all 3 are filled.
- **Step 2 — AI Scan Overlay → Review:**
  - On step 1 Continue, **`ScanOverlay`** modal opens:
    - Animated progress ring (uses the existing `pulse` keyframe).
    - 4-step list with checkmarks revealing as the mock scan
      progresses: "Extracting pages", "Identifying categories",
      "Resolving rules", "Resolving branch overrides".
    - After ~6 s of mock animation, the modal closes and step 2
      renders.
  - **Review Pane:** split layout —
    - **Left:** PDF preview frame (placeholder mock-up of doctrine
      pages with grey lines).
    - **Right:** rule sections accordion:
      - Mandatory Rules (6 rows): category → logic → options.
      - Optional Rules (2 rows): same shape.
      - Branch Overrides (4 expandable subsections, one per branch):
        each shows the diff vs base.
  - Continue button at footer.
- **Step 3 — Finalise:**
  - Summary card: code, name, 5 stat rows (mandatory count, optional
    count, branch override count, image-count, glb-count).
  - Status toggle: Draft / Placeholder / Live (radio pill).
  - **Warning banner** when "Live" is selected: "Going Live publishes
    to mobile clients on next refresh."
  - Publish button (primary if live, ghost otherwise). Fires a toast
    "Dress requirement published" (mock — real Firestore write +
    `extractDressRequirementsFromPdf` Cloud Function in a follow-up
    plan).

### 7c — `/dress/:id` — Edit
- Reuses the step 2 Review Pane.
- Above it: a **change history accordion** (5 mock entries:
  who / when / field diff).

**Data:** `MockDataService.dresses()` (6 mock rows), `dressCodes()`,
`branches()`. Hardcoded `SAMPLE_RULES`, `SAMPLE_OPTIONAL`,
`SAMPLE_BRANCH_OVERRIDES` inline (matches the design source).

**Components used:** every primitive plus the new ones from earlier
screens (Drawer is not used; Modal is). New:
- **PdfDropzone** — drag-and-drop file input with disabled / hover /
  drop states.
- **StepIndicator** — generic step bar (used here, reusable if other
  wizards land later).
- **ScanOverlay** — animated mock-AI progress modal.
- **AccordionRow** — reusable expandable row (used in Branch Overrides
  + Change History — and could be shared with Branch Config's
  CfgSection if generalised; do that when CfgSection is built).

**New i18n keys:** ~80 under `dress.*` (existing `dress.eyebrow` /
`title` / `subtitle` already exist; add list filters, card metadata,
3 wizard step labels + bodies, AI scan step names, rule category
names — these may already partially exist in mobile-app's `app_en.arb`
for cross-app consistency).

**Acceptance:** list renders; clicking Add Dress opens the wizard;
all 3 steps flow correctly; mock AI scan animates and resolves; Save
fires a toast. `/dress/:id` for any of the 6 mock ids renders the
review pane.

**Dependencies:** **No third-party deps.** The mock AI scan is pure
CSS animation + setTimeout; no real PDF rendering needed at this
phase (the design itself uses a stylised placeholder, not a real PDF
viewer).

---

## Master cost estimate

| Screen | Complexity | Components | i18n keys | New deps | Est hours |
|---|---|---|---|---|---|
| Users | S | 1 new (Drawer) | ~25 | – | 2 |
| Admins | M | 1 new (KebabMenu) | ~30 | – | 3 |
| Branches | M | 1 new (CfgSection) | ~40 | – | 3 |
| Logic | L | 2 new (JsonEditor, CodeChip) | ~25 | Monaco | 5 |
| Accessories | L | – (reuses Drawer) | ~50 | – | 4 |
| Models | L | 3 new (TabRouter, ModelViewer, SocketPanel) | ~60 | @google/model-viewer | 5 |
| Dress | XL | 4 new (PdfDropzone, StepIndicator, ScanOverlay, AccordionRow) | ~80 | – | 8 |
| **Total** | — | **12 new components** | **~310 keys** | **2 deps** | **~30 hours** |

Each screen also touches `CLAUDE.md` § 2 to flip the route from "stub"
to "designed", and (per CLAUDE.md policy 1.5) needs a `flutter analyze`
/ admin-portal build verification pass.

---

## Execution order rationale

1. **Users (S)** — simplest. Lets us build the **Drawer** primitive
   that Accessories will reuse.
2. **Admins (M)** — adds the **KebabMenu** + "Add X" modal pattern
   that Dress (Add Dress) will partly reuse.
3. **Branches (M)** — introduces **CfgSection** (collapsible card
   section). Dress's branch override accordion may be generalised
   from this.
4. **Logic (L)** — Monaco install + JsonEditor. Self-contained.
5. **Accessories (L)** — heavy table + drawer reuse. Validates the
   Drawer abstraction in real use.
6. **Models (L)** — `<model-viewer>` install. Most "physically new"
   work since it touches Storage reads + 3D rendering.
7. **Dress (XL)** — last because it composes patterns from all the
   prior screens (cards, modal wizard, animations, accordion,
   drawer-adjacent layouts).

This order minimises rework: every "shared primitive" is built when
it first appears, then reused.

---

## What's NOT in this roadmap (deliberately)

- **Real Firestore reads/writes.** Every screen uses
  `MockDataService` initially. After all 7 are in place, a single
  "Real Firestore wiring" plan replaces the mock returns with
  AngularFire-backed observables — typically a one-file change per
  service, no component-level changes.
- **Cloud Functions for write paths** — `markAdminCreated`,
  `extractDressRequirementsFromPdf` (Claude API), and the Storage
  upload callables — each is its own plan, scheduled after the
  Firestore-wiring plan.
- **Chinese (zh) translations** — drop-in second locale JSON; planned
  as the very last item.
- **Full PDF rendering** in the Dress wizard — the design's review
  pane is a stylised mock-up, not a real PDF viewer. If real PDF
  rendering is needed, it'd be a separate plan adding
  `ngx-extended-pdf-viewer` (~1.5 MB) and a Cloud Function for AI
  extraction.

---

## Next step

Per the agreed phasing, the next ChangeRequest to write + execute is:

> `ChangeRequest/2026-05-17_admin-portal-users.md` — App Users screen.

I'll write that detailed plan, then implement it, then return for the
next one. Tell me to start when ready (or correct course if you'd like
to change order, batch screens, or adjust scope).
