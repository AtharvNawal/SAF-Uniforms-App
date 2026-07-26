# Admin Portal — Full Firestore + Storage Integration

**Status:** executing

**Date:** 2026-05-18  
**Author:** Claude (plan-first workflow)

---

## Goal

Replace `MockDataService` (11 static in-memory Observable streams) with real Firebase Firestore reads/writes (`FirestoreDataService`) and Firebase Storage listing (`StorageDataService`). All consumer signatures (`Observable<T>`) remain unchanged; the swap is transparent to page components.

## Scope

- New: `admin-portal/src/app/core/data/firestore-data.service.ts`
- New: `admin-portal/src/app/core/data/storage-data.service.ts`
- Delete: `admin-portal/src/app/core/data/mock-data.service.ts`
- Update: `admin-portal/src/app/core/data/models.ts` (new types, extend existing)
- Update: `firestore.rules` (isAdmin() helper + new collection rules)
- Update: 12 page component .ts files (service swap + write wiring)

## New Firestore Collections

### `admin_accounts/{uid}`
```
name, email, role ('super'|'admin'), initials, createdAt, lastLogin, active
```
Document ID = Firebase Auth UID.

### `activity_log/{autoId}`
```
who, uid, action, target, timestamp
```

### First Admin Seed (manual — Firebase Console)
1. Firebase Console → Authentication → copy UID of first super-admin
2. Firestore → Data → create `admin_accounts` collection
3. Create doc with ID = UID, fields: name, email, role='super', initials, createdAt=now, lastLogin=null, active=true

## Affected Sections of CLAUDE.md

- §5.5 Backend — Firebase: Add `admin_accounts/{uid}` and `activity_log/{id}` to Firestore collections list
- §admin-portal section: Update status to "Fully Firestore-wired; MockDataService removed"
- §firestore.rules description: Add `isAdmin()` helper and new collection rules

## Risks & Rollback

- **Live writes**: Logic and Branch saves write to live Firestore (mobile app reads in real-time). Incorrect values could affect mobile app display. Rollback: revert Firestore doc via Console.
- **N+1 reads for users**: `appUsers()` reads `profile/current` for each user. Acceptable at current scale.
- **isAdmin() billing**: 1 extra Firestore read per rule evaluation. Negligible for low-traffic admin portal.

## Verification

1. `cd admin-portal && npx ng build --configuration development` — zero errors
2. `npx ng serve` — sign in, navigate all 10 routes, verify real data displays
3. Edit a logic rule and save → verify Firestore Console shows the update
4. `firebase deploy --only firestore:rules` — deploy updated rules
5. Firebase Rules Playground: verify non-admin reads are denied, admin writes are allowed

## Status

- [ ] firestore.rules updated
- [ ] models.ts extended
- [ ] StorageDataService created
- [ ] FirestoreDataService created
- [ ] All 12 page components updated
- [ ] mock-data.service.ts deleted
- [ ] ng build clean
- [ ] Rules deployed
