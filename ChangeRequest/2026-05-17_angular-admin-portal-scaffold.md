# Angular Admin Portal — Initial Scaffold

- **Date:** 2026-05-17
- **Author:** Claude (Opus 4.7)
- **Status:** in-progress

## 1. Goal

Stand up a deployable Angular SSR project — in a new top-level `admin-portal/`
folder — wired to the existing `saf-uniforms` Firebase project (Firestore,
Storage, Auth, Functions) and deployable to **Firebase App Hosting**.

This change introduces only the bare scaffold. The Claude Design
implementation (10+ screens, dark-mode design tokens, Monaco JSON editor,
GLB previews, AI-assisted PDF extraction per
`SAF_Uniforms_Admin_Portal_Design_Brief.docx`) lands in a follow-up plan
once the foundation is verified end-to-end.

The portal replaces the current operator CLI scripts
(`tool/seed_firestore.dart`, `tool/upload_*.py`) and Firebase Console
manual edits with a real UI for the 2–3 named admin accounts.

## 2. Scope

**In scope:**
- New `admin-portal/` Angular 18+ SSR project (standalone components,
  routing, SCSS, strict TypeScript).
- AngularFire wiring for Firestore + Storage + Auth + Functions
  (region `asia-southeast1`).
- Three verification surfaces (Firestore stream, Storage list, Auth state).
- Placeholder login page.
- `apphosting.yaml` (Cloud Run runtime config).
- Root `.gitignore` additions for Angular build artefacts.
- Firebase App Hosting backend (`saf-uniforms-admin`) connected to GitHub.

**Out of scope:**
- Claude Design tokens, Tailwind / Angular Material UI styling.
- Monaco JSON editor.
- `@google/model-viewer` GLB preview.
- PDF AI extraction (`pdfjs-dist` + Claude API).
- Real admin screens (Accessory Library, Dress Requirements, 3D Models,
  Branch Config, Logic Rules, App Users, Admin Accounts, Settings).
- Role-based access control beyond the email/password sign-in.
- Cloud Functions changes — existing `functions/` directory is untouched.

## 3. Affected areas

**Created:**
- `admin-portal/` — entire Angular project (scaffolded by Angular CLI).
- `admin-portal/apphosting.yaml` — Cloud Run runtime config.
- `admin-portal/src/environments/environment.ts` + `environment.prod.ts`.
- `admin-portal/src/app/core/firebase/verification.service.ts`.
- `admin-portal/src/app/pages/verification/verification.component.ts`.
- `admin-portal/src/app/pages/login/login.component.ts`.
- `.firebaserc` at the repo root (written by `firebase init apphosting`).
- This ChangeRequest file.

**Modified:**
- `admin-portal/src/app/app.config.ts` — AngularFire providers.
- `admin-portal/src/app/app.routes.ts` — two lazy routes (`/`, `/login`).
- `admin-portal/src/app/app.component.ts` — `<router-outlet />` only.
- `admin-portal/angular.json` — `fileReplacements` for production env.
- `firebase.json` — `apphosting` block (written by CLI).
- `.gitignore` (root) — Angular exclusions.
- `CLAUDE.md` — top-level layout + Backend section update.

## 4. Step-by-step plan

1. Pre-flight: confirm Node ≥ 20, Firebase CLI logged in as
   `sukalkar.datta@gmail.com`.
2. `npx -y @angular/cli@latest new admin-portal --ssr --routing --style=scss --skip-git --package-manager=npm --defaults`.
3. `cd admin-portal && npm i firebase @angular/fire`.
4. Create `src/environments/environment.ts` + `environment.prod.ts` with
   the Firebase Web config placeholders (`apiKey`, `appId` filled in by
   the operator after registering the Web app in Firebase Console).
5. Wire `app.config.ts` with AngularFire's modular providers
   (`provideFirebaseApp`, `provideFirestore`, `provideStorage`,
   `provideAuth`, `provideFunctions(undefined, 'asia-southeast1')`).
6. Implement `VerificationService` (Firestore count, Storage list, Auth state).
7. Implement `VerificationComponent` + `LoginComponent` (skeleton only,
   no styling).
8. Update `app.routes.ts` with the two lazy-loaded routes.
9. Write `apphosting.yaml` with minimal Cloud Run runtime config
   (cpu 1, 512MiB, maxInstances 3).
10. Append Angular exclusions to root `.gitignore`.
11. Update `CLAUDE.md` (top-level layout + §5.5 Backend note).
12. **Operator step (interactive):** in Firebase Console, register a new
    Web app on the `saf-uniforms` project and paste the config into
    `environment.ts` / `environment.prod.ts`.
13. **Operator step (interactive):** `firebase init apphosting` from
    repo root, select project `saf-uniforms`, region `asia-southeast1`,
    backend id `saf-uniforms-admin`, root directory `admin-portal`,
    link the GitHub repo, live branch `main`.

## 5. Risks & rollback

| Risk | Mitigation |
| ---- | ---------- |
| Firebase web config requires manual Web app registration (mobile-only today) | Step 12 — clearly documented operator action |
| `firebase init apphosting` needs Cloud billing on the project | CLI surfaces the prompt; operator-driven step |
| Node 25 (current local) is ahead of Angular's officially-tested matrix (Node 20–22); engine warnings possible | Use latest Angular CLI; downgrade to `nvm use 20` if a build break appears |
| AngularFire SSR can double-fetch on server + client without hydration | `provideClientHydration()` is included from the start |
| GitHub Action default Node may be < 20 | App Hosting auto-detects Angular and uses Node 20 |

**Rollback:** delete the `admin-portal/` folder, revert the root
`firebase.json` and `.gitignore` diffs, delete the `saf-uniforms-admin`
App Hosting backend in the Firebase Console, and disconnect the GitHub
repo. Mobile app + Cloud Functions + Firestore rules untouched, no
rollback needed there.

## 6. Verification

1. `cd admin-portal && npm install && npm run build` — clean compile.
2. `npm start` → `http://localhost:4200/` displays:
   - "Firestore: <N> accessories" — N should match the live
     `accessory_library` count (currently 82 per CLAUDE.md §5.5).
   - "Storage: <up to 5 paths under models/>".
   - "Auth: not signed in".
3. Navigate to `/login`, submit dummy credentials → expect a Firebase
   `auth/invalid-credential` error rendered on the page (proves Auth is
   reachable).
4. After `firebase init apphosting`: push the branch and confirm the
   live App Hosting URL renders the same three verification lines.
5. Flip this file's `Status:` to `verified` once steps 1–4 pass.

`flutter analyze`, `flutter test`, and Cloud Functions tests are **not**
re-run because none of those areas are modified.

## 7. CLAUDE.md updates required

- **§2 Top-level layout** — add a row for `admin-portal/` describing the
  Angular 18 SSR portal and its Firebase App Hosting deployment.
- **§5.5 Backend — Firebase** — note that `apphosting` is now a third
  deploy target alongside `functions` and `firestore/storage` rules,
  and that a Web app must be registered in the Firebase Console for the
  portal's web SDK config.
