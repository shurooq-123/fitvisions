# CP2 Group 13 — latest-source review implementation

Source: `FitVisions-Latest-2026-11-16.zip`, extracted into this project on 16 November 2026. The supplied source is preserved as a separate Git commit. New email-link registration, light/dark appearance, removed ready-made screen, and the admin user-subscriptions page are retained.

## Review checklist

| Review comment | Implemented behavior / evidence | Availability |
|---|---|---|
| Changing measurements must regenerate | New dimensions invalidate the saved body reference and regenerate both the body and dressed output. Explicit cm/in conversion is tested. | Local automated tests; live AI fidelity still needs evaluation |
| Measurement illustration / arrow | MeasurementLabel and BodyMeasurePainter receive current and previous values; silhouette and direction indicator update. | Implemented |
| History dates/order | User history includes day, date and time; user and admin history default newest first and can switch to oldest first. | Implemented |
| Existing subscriptions must survive catalog edits | Name, price, features and calendar duration are frozen in the subscription/payment snapshot. Rules prevent altering a purchased snapshot. | App and emulator tested; production rules not deployed |
| Subscription expiry | Access is checked again before edit/download; exclusive expiry boundaries and cancelled records are tested. | Implemented; device lifecycle test pending |
| Registration / renewal calendar dates | Month arithmetic clamps to month end, handles leap years and retains time. Backend queues early renewals after the existing expiry. | Calendar tests pass; server renewal deployment pending |
| Gender-specific clothing / avatar | Male/female choices filter garments, clear incompatible prior answers and reference choices, and pass gender into the avatar prompt. Measurements determine body dimensions. | Implemented; AI outputs are probabilistic |
| Past card expiry | Picker starts in current month; validation rejects past months, invalid card values and all-zero card numbers. | Implemented and tested |
| Admin plan validation | Positive decimal price (up to 3 decimal places) and duration 1–120 calendar months; letters/invalid values rejected. | Implemented and tested |
| Dashboard notification menu | Shared authenticated header shows notification bell, unread count and report action. | Implemented |
| Notification history/read state | Owner-scoped history and read/unread action with error handling. | App and rules tested |
| Push/background notices | FCM permissions/token refresh/account-switch handling, foreground banner and background handler. Backend creates payment/renewal/expiry notices and delivers FCM payloads. | Code prepared; NOT live until backend deployment and device test |
| Downloadable/shareable reports | Activity, subscription/payment and feedback PDF tables, record count/date/page numbers; print/save and share actions for both roles. | PDF creation tested; mobile share dialog not tested |
| Persistence | Atomic batches, server timestamps, ownership checks, deterministic payment/history IDs and save-retry for generated output. | Firestore/Storage emulator tested; not a production-write test |
| Delete restrictions | Direct deletion denied; trusted archive endpoint blocks self/admin/active-subscription accounts, retains records and disables authentication. | Rules tested; endpoint not deployed |
| Back navigation / profile name | Back buttons and stack-aware bottom navigation; authenticated account header displays profile name across routes. | Layout/navigation tests |
| Edit clothing selections | Edit choices before generation; subscription rechecked for output edits, busy/invalid states block conflicting operations. | Implemented |
| Advanced image preview (CAT B) | Camera/gallery selection with zoomable image preview, remove/replace and durable local storage. | Implemented; this extends basic upload rather than counting it twice |
| Responsive UI (CAT B) | Scrollable constrained forms, flexible action sizes, small phone/tablet/landscape and enlarged-text tests; original dark mode retained. | Automated layout tests |
| Git activity | Genuine import and review commits; push to `codex/first-review-fixes` after completed tested changes. | No backdated commits; main unchanged |

## What is deliberately NOT claimed complete in production

The user chose to remain on the free Firebase plan. No billing upgrade, Functions deployment or production rules deployment is performed. Scheduled reminders, background delivery, atomic server renewal activation and protected account archival need the prepared backend deployed before they can be demonstrated live. The app cannot manufacture operating-system push delivery without a sending server.

Payment is still the existing prototype: no bank gateway and no real money charge. A pending demo record is not bank-confirmed revenue. Existing prototype entitlement behavior is retained.

The AI bridge still requires its existing runtime configuration and valid credentials. Generated clothing fit cannot be guaranteed pixel-for-pixel; the parametric body's numeric dimensions and the generator's visual output are different verification targets.

Original photos are copied to durable app-local storage by default. They are not cross-device cloud backups. Optional Firebase Storage requires its configuration/rules. Generated history saves a bounded preview; a failed history write can be retried without a second generation.

## Reproduce validation

- `flutter test`
- `flutter analyze`
- `cd functions` then `npm ci` and `npm test`
- At project root: `node tools/firebase-tests/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --project demo-fitvisions --only firestore,storage "node --test tools/firebase-tests/rules.test.cjs"`
- `flutter build apk --debug`

Use the existing AI build configuration when installing for AI testing. No secrets should be committed. Deploy later only after reviewing billing and testing on dedicated accounts. Verify push in foreground/background/terminated states, notification permission, renewal/expiry, real database writes and PDF sharing on a device.

## Validation results — 16 November 2026

- 185 Flutter tests passed, including compact phone, landscape, large text and dark-mode layouts; both user and admin pages are included.
- 14 Firestore/Storage emulator tests passed against this version's combined rules, including the verified-email registration flow.
- 4 backend calendar/expiry policy tests passed.
- These are local/mocked/emulator results, not evidence of live push delivery, actual bank payment, or exact AI clothing fit.
