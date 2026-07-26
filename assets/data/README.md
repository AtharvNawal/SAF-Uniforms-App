# `assets/data/` — frozen Firestore seed snapshot

These three JSON files are **not** consumed by the running app at runtime.
They are a one-shot seed snapshot for Firestore project `saf-uniforms`,
read only by `tool/seed_firestore.dart` (the operator-only Firebase Admin
SDK script).

## What lives here
- `branch_configs.v1.json` — initial `branch_configs` collection
- `accessory_library.v1.json` — initial `accessory_library` collection
- `dress_requirements.v1.json` — initial `dress_requirements` collection

## How the app actually gets this data
`lib/features/*/data/*_repository.dart` reads the corresponding Firestore
collection as a real-time stream. Editing the JSON files in this folder will
**not** change app behaviour — it only changes what the seed script would
push if it were re-run against a fresh project.

## Editing rules
1. To change live content, edit Firestore directly via the web admin portal
   (or the Firebase Console). Never edit these JSON files for runtime
   changes.
2. Only edit these files if you are creating a brand-new Firebase project
   or wiping an existing one and re-seeding from scratch.
3. If you do edit them, bump the `version` field at the top of the file
   (the admin portal uses `version` as a cache-busting hint).

## Re-seeding a fresh project
```bash
dart run tool/seed_firestore.dart <path/to/service-account.json>
```

The seeder uses Firebase Admin SDK credentials, which bypass Firestore
security rules entirely — strict `firestore.rules` can stay deployed
during the seed window. Idempotent (`SetOptions.merge()`), so running it
against an already-populated project is safe.

Get the service account JSON from Firebase Console → `saf-uniforms` →
Project settings → Service accounts → "Generate new private key". Save
it outside the repo (or in the gitignored `secrets/` directory).
