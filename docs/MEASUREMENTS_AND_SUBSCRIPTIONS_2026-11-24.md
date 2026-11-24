# Measurement, recommendations and subscription update — 24 November 2026

- Shared accepted body ranges in centimetres: height 50–250; chest/waist/hips 30–300; optional shoulders 15–100. These are application input limits, not medical guidance. Zero, one, non-finite and out-of-range values are rejected before AI requests; edited fields show their allowed range. The current measurements replace result measurements only after successful regeneration; changed measurements invalidate the measured-body reference cache. Generative images still do not guarantee exact physical dimensions.
- Removed camera choices while keeping gallery uploads and optional face photos. Removed the user-home back arrows in both page and account header.
- Recommendations generate a board of three garment looks and show a short localized caption. The last generated board is stored in app-private storage under the account UID; existing long recommendations prompt a refresh instead of being displayed.
- Appearance and language moved below Recommended For You and before About Us.
- Created the missing Basic Plan (3 OMR, one calendar month) in Firestore. Existing catalogue edit/delete behavior already retains purchased payment snapshots; no existing subscription/payment was edited.
- Subscription summary now shows plan, purchased duration, expiry and remaining days, without feature lists.
- Local mail service polls for active subscriptions with at most 48 hours remaining, uses the registered account email, sends Arabic/English remaining-days reminders, and persists an emailSent receipt. Newer entitlements suppress older expiry reminders. Requires the laptop, internet and configured sender; no paid hosting enabled.

Validation: 229 Flutter tests passed; 17 focused follow-up tests passed after final input feedback changes. Reminder boundary and mocked recipient/duplicate-delivery tests passed, together with existing calendar/notification tests. Cloudflare generated a real recommendation image using synthetic measurements. SMTP ready verified; no production user's expiry was changed to force a test email. App is still using the existing prototype payment flow.
