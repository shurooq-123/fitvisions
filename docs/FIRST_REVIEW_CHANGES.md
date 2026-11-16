# CP2 Group 13 - first review changes

Work is based on the supplied FitVisions-Source.zip, opened in this folder on 16 November 2026. No historical commit dates have been changed.

## Implemented in the app

- History displays day/date/time, defaults to newest first and offers an oldest-first switch.
- Measurement changes invalidate the body reference; regeneration uses the new body and outfit. Editing/downloading rechecks subscription access.
- Measurement guides update the displayed value, silhouette scale and increase/decrease indicator.
- Design gender changes clear incompatible answers and dress references. Male/female catalog filtering is retained; face-free avatars stay featureless without a portrait.
- Gallery/camera uploads have a zoomable preview and a remove/replace action (advanced image-preview functionality for CAT B). Local images are copied out of temporary picker storage.
- Plan prices reject letters, negative/zero values and more than three decimals. Duration is a validated number of calendar months.
- Selected subscriptions snapshot name, price, duration and features. Payment records use that snapshot, not the live catalogue. Later plan edits do not alter prior purchases.
- Month arithmetic clamps to the final day of the target month, including leap years. Expiry is exclusive; access stops at the expiry instant. Foreground subscription display refreshes with time.
- Card numbers permit zeros, reject an all-zero card, and past expiry months are rejected. Current-month cards remain valid through that month.
- Shared account header exposes notifications, unread count, reports and the profile name across screens.
- Notification history supports read/unread status and reports load fresh database data with role-based queries.
- User/admin activity, payment/subscription and feedback reports generate paginated PDF files with export/print and share actions.
- Bottom navigation avoids duplicate page stacks. Forms are scrollable, width-constrained and tested at phone, tablet and landscape sizes with enlarged text.
- Generation-history failures expose an idempotent save retry, without paying for another AI generation.

## Server implementation prepared, NOT deployed

The user chose to stay on Firebase's free plan. No billing upgrade, rules deployment or Functions deployment was performed.

`functions/index.js` provides:
- Atomic demo subscription activation and renewal, with frozen subscription terms and server-generated dates.
- Payment/renewal notices, generation notices and scheduled expiry/expiry-soon reminders.
- FCM delivery to registered devices. Android OS displays notification payloads while the app is backgrounded; foreground messages show an in-app banner.
- Restricted account archival: blocks self/admin archival and accounts with active subscriptions, disables authentication and retains transaction records. Direct profile deletion is denied by the prepared rules.

**These server-dependent features are not live on the free project.** New Firestore fields/collections also require deployment of the prepared rules before testing this build against production. The existing production project and installed phone app were not changed.

## Persistence and privacy

Firestore Emulator tests cover transactional writes, price/snapshot validation, user isolation, notification read state, forbidden deletion and image access. This does not demonstrate a successful write to the live database. Original user pictures remain device-local unless `FIREBASE_STORAGE_ENABLED` is explicitly enabled; a local file path is not a cross-device image upload. Generated history stores a bounded thumbnail, not a full-resolution cloud backup.

Payments remain a prototype; no bank/payment gateway was added. `demo_active` is deliberately distinct from bank-confirmed `paid`. Reports disclose this distinction. AI calls continue to need the existing runtime configuration and a working AI bridge/cloud endpoint. Pixel-perfect clothing fit is not guaranteed by a generative image model.

## Deployment later

1. Review Firebase billing before enabling Blaze; do not assume a spending alert is a spending cap.
2. In `functions`, run `npm ci` (after a lockfile exists) or `npm install` and `npm test`.
3. Review/test the rules with the emulator, then deploy `firestore:rules,functions` to the correct project.
4. Build/install the app using the existing AI configuration. Grant notification permission on the phone.
5. Test actual FCM delivery in foreground/background/terminated states, token refresh, logout/account switching, and offline recovery. Force-stopping an Android app or disabling notification permission can prevent delivery.
6. Test real signup/profile/history writes and subscription lifecycle with dedicated test accounts; do not use real card details.
7. For iOS, configure APNs credentials and Push Notifications capabilities before claiming iOS support.

## Version control

Make small, genuine commits after each tested change and push to a review branch. The earlier 25-day gap cannot be repaired by backdating commits. Keep AI/mail secrets and generated build files out of Git.

## Validation results (16 November 2026)

- Flutter: **125 tests passed**, including measurement-edit regeneration, PDF byte generation for both roles, history sorting/timestamps, notification read/unread, invalid admin price, card expiry, gender-dependent questions and layouts at 360x640, 800x360 and 1024x768 with 130% text scale.
- Firebase Firestore/Storage emulators: **13 tests passed** (no production data modified).
- Backend calendar/expiry policy: **4 tests passed**; all five exported Functions handlers load successfully.
- Backend dependency audit: zero known vulnerabilities in the installed versions at test time.
- Android debug APK built successfully. Actual Android notification delivery, PDF sharing UI, live database writes and live AI image fidelity still need device/server validation.
- Static analysis has no errors or warnings; nine informational style/logging notices remain, including pre-existing notices.
