# Admin Portal — Claude Design Phase 1 (Foundation)

- **Date:** 2026-05-17
- **Author:** Claude (Opus 4.7)
- **Status:** executed

## 1. Goal

Deliver the foundation layer of the SAF Uniforms admin portal per the
Claude Design handoff: full design-token SCSS, ngx-translate i18n,
dark/light theme service, responsive shell (sidebar / topbar / mobile
bottom nav / more menu), 41-icon component, 14 core UI primitives, mock
data services mirroring the JSX `data.jsx` shapes, and **all 10 routes
present** with Login + Settings fully wired and the other 7 screens
shipping as stubs awaiting follow-up plans.

## 2. Scope

**In scope:**
- Design-token SCSS + full design CSS port (`styles/_tokens.scss`,
  `_base.scss`, `_design.scss`), light/dark via `[data-theme="..."]`.
- ngx-translate (English only today; structure ready for more), full
  `public/i18n/en.json`.
- ThemeService, ToastService, AuthService, AuthGuard.
- Mock data services + TypeScript interfaces for all 11 `data.jsx`
  collections.
- 41-icon `<app-icon>` component (inline SVGs).
- 14 UI primitives (Button, Chip, Card, Field, Input, Select, Toggle,
  PillToggle, Modal, Avatar, BranchDot, Eyebrow, MonoTag, EmptyState)
  plus a shared PageStub component.
- Shell layout: Shell + TopBar + Sidebar + MobileNav + ToastHost.
- 10 routes (Login fully wired, Dashboard / Dress / Accessories /
  Models / Branches / Logic / Users / Admins as stubs, Settings fully
  wired except destructive actions).
- Responsive breakpoints 480 / 720 / 760 / 980 / 1180 px.

**Out of scope:**
- Real content for the 7 stub screens (Dashboard widgets, Dress wizard,
  PDF AI extraction, Accessory table, 3D Models GLB viewer, Branch
  Config editor, Logic Rules + Monaco JSON editor, App Users table,
  Admin Accounts table).
- Real Firestore writes from any screen.
- Chinese (zh) translations.
- Destructive Settings actions (re-seed, clear cache) — UI shells only.

## 3. Affected areas

**Created:** `admin-portal/src/styles/_*.scss`,
`admin-portal/public/i18n/en.json`,
`admin-portal/src/app/core/{theme,i18n,toast,auth,data}/`,
`admin-portal/src/app/shared/icon/`,
`admin-portal/src/app/shared/ui/{button,chip,card,field,input,select,toggle,pill-toggle,modal,avatar,branch-dot,eyebrow,mono-tag,empty-state,page-stub}/`,
`admin-portal/src/app/layout/{shell,topbar,sidebar,mobile-nav,toast-host}/`,
`admin-portal/src/app/pages/{dashboard,dress,accessories,models,branches,logic,users,admins,settings}/`,
this ChangeRequest file.

**Modified:** `admin-portal/package.json`,
`admin-portal/src/styles.scss`, `src/index.html`,
`admin-portal/src/app/app.config.ts`, `app.routes.ts`, `app.html`,
`admin-portal/src/app/pages/login/login.component.ts`, root `CLAUDE.md`.

**Deleted:** `admin-portal/src/app/pages/verification/`,
`admin-portal/src/app/core/firebase/verification.service.ts`.

## 4. Step-by-step plan

See `/Users/meet/.claude/plans/i-have-the-claude-kind-token.md` for the
detailed 15-step plan. Summary:

1. Install `@ngx-translate/core` + `@ngx-translate/http-loader`.
2. Port design CSS to `_tokens.scss` + `_base.scss` + `_design.scss`.
3. Configure ngx-translate with `provideHttpClient` and the HTTP loader.
4. Build ThemeService / ToastService / AuthService / AuthGuard /
   MockDataService.
5. Recreate the 41 inline SVG icons in a single `<app-icon>` component.
6. Build the 14 UI primitives + PageStub.
7. Build the shell + topbar + sidebar + mobile-nav + toast-host.
8. Rewrite `app.routes.ts` to wire all 10 routes under the shell.
9. Stub 7 pages via PageStub.
10. Rewrite Login per the design and implement Settings.
11. Delete the verification page + service.
12. Update CLAUDE.md.

## 5. Risks & rollback

| Risk | Mitigation |
| ---- | ---------- |
| ngx-translate HTTP loader path mismatch under Angular 20 `public/` convention | The loader uses `/i18n/` prefix; `public/i18n/en.json` resolves correctly at build + runtime |
| `localStorage` access at SSR | ThemeService gates on `isPlatformBrowser(PLATFORM_ID)` |
| Auth guard race on first load | Guard awaits `authState` first emit |
| Bundle size | Budget already raised to 1 MB warn / 2 MB error; lazy routes keep initial bundle small |

**Rollback:** delete the new files, restore the verification component,
revert `package.json`, `app.routes.ts`, `app.html`, `app.config.ts`,
`styles.scss`, `index.html`. Mobile app, Cloud Functions, Firestore /
Storage rules are untouched.

## 6. Verification

1. `cd admin-portal && npm install && npm run build` exits 0.
2. `npm start` → `http://localhost:4200/`:
   - Lands on `/login` when signed out.
   - Sign in with the Firebase Console-created admin → `/dashboard`.
   - Sidebar renders, all 8 main items + Settings; nav between all 10
     routes works.
   - Resize < 720 px → bottom nav appears, sidebar hides; "More" opens
     the overflow modal.
   - `/settings` cycles Dark / Light / System; refresh persists.
   - Sign out clears state and returns to `/login`.

## 7. CLAUDE.md updates required

- **§2 Top-level layout** — extend the `admin-portal/` blurb with the
  i18n / theme / 10-route facts.
- **§5.5 Backend — Firebase** — note that admin portal routes are all
  client-rendered (no SSR per request); data services are mock-backed
  today and become AngularFire-backed in follow-up plans.
