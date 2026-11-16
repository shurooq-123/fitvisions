# Account feature status — 2026-09-30

## Implemented
- Successful login routes by the server profile role to User Dashboard or Admin Dashboard.
- Admin Users now has a history icon for each UID. The history page queries that exact UID, sorts timestamps locally, handles loading/error/empty results and is read-only.
- Firestore rules permit history reads to the record owner or an authenticated admin. Other users remain denied. Tested in the rules emulator. Published through the Firebase console on 2026-09-30 at 22:20 Asia/Muscat; the console marks that version active. Firebase CLI remains unauthenticated.
- Change Password now asks for the current password, rejects the same value with an explicit reuse message, reauthenticates with Firebase, changes the password and signs out. Admin Dashboard has an account menu linking to this screen.

## Not implemented or enabled
- Login email notifications: no email backend is configured in this repository. Live console confirmed Spark billing. Firebase Trigger Email extension requires an SMTP provider and Blaze; billing was not changed and no notification was sent.
- Full historical password reuse prevention: the current change only blocks choosing the CURRENT password in the app. It does not prevent A -> B -> A, nor constrain Firebase's hosted Forgot Password flow. A server-owned salted password-history store and controlled change/reset flow are needed; historical plaintext passwords cannot be recovered. Direct Firebase password endpoints also need to be accounted for when deciding enforcement architecture. Do not label this as complete password history enforcement.

Sources:
- https://firebase.google.com/docs/extensions/official/firestore-send-email
- https://extensions.dev/extensions/firebase/firestore-send-email
- https://firebase.google.com/docs/auth/custom-email-handler

## Verification
- Auth regression tests include same-current-password rejection, required reauthentication and failed reauthentication preventing mutation.
- Firestore emulator tests include admin cross-user history reads and denial to a different ordinary user.
- No real user password was changed by development/testing.
