# Firebase integration status

Project: `fitvisions-33e6d`. The existing Android `google-services.json` selects this project.

## Complete local integration

- Firebase Authentication: user/admin login, registration, real password-reset email for both entry points.
- Firestore: profiles, plans, measurements, image metadata, activity history, feedback with numeric ratings, subscription selection and pending payment requests.
- Measurements, feedback, uploads metadata and checkout actions save their activity history in the same Firestore batch.
- Subscription prices are read from the catalog and checked against it by rules. Clients cannot activate paid subscriptions, mark payments paid or store card information.
- The admin revenue total counts only trusted `status: paid` records. Old records without status are unverified and excluded.
- Images use authenticated `gs://` references when cloud mode is enabled. Local mode is explicitly labelled in the UI. The avatar reads `personalImagePath` (with a legacy fallback).

## Pending remote setup

The expanded Firestore rules were published to `fitvisions-33e6d` on 2026-09-28 after explicit user approval. Firebase confirmed success and displayed the active version as "Today • 1:42 AM". `firestore.auth.rules` is retained only as the earlier account-only version. Publication did not modify existing documents or enable billing.

Cloud Storage requires a Blaze billing plan and an initialized bucket. Billing was not changed. After the owner configures Storage and approves deployment of `storage.rules`, launch with:

```powershell
flutter run -d emulator-5554 --dart-define=FIREBASE_STORAGE_ENABLED=true
```

Without that flag, images stay on the device; Firestore stores metadata only. Old local paths do not migrate across devices. Users must reselect images after cloud mode is enabled. Images are limited to JPEG/PNG/WebP under 5 MB, private to the owner. Storage rules were tested locally, not deployed.

Payment processing is not implemented: only a pending request is saved, without card details or charges. A payment gateway and trusted server webhook are required for paid activation. Success notification emails require a configured mail backend. Password-history enforcement requires a controlled reset backend; Firebase's default external reset page remains in use. Avatar preview is an image overlay, not an AI try-on service.

## Verification

Run `flutter test` for Flutter regression tests. Run isolated security tests (synthetic identities; no production data):

```powershell
npm --prefix tools/firebase-tests ci
$env:JAVA_HOME = 'C:/Program Files/Android/Android Studio/jbr'
$env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
./tools/firebase-tests/node_modules/.bin/firebase.cmd emulators:exec --project demo-fitvisions --only firestore,storage 'node --test tools/firebase-tests/rules.test.cjs'
```

These tests cover owner/admin access, denied cross-user access, measurement/history batches, feedback validation, catalog price tampering, forbidden paid status/card details, and private image storage. Real account testing after publication is still pending and requires a complete `users/{uid}` profile. No existing user records were repaired automatically.
