# Firebase authentication repair

Project: `fitvisions-33e6d`.

Observed in Android logs: profile creation fails with Firestore `PERMISSION_DENIED`,
then a repeat registration fails with `email-already-in-use`. Login also previously
queried the users collection before authenticating and received `PERMISSION_DENIED`.

The app now signs in first, reads only `users/{uid}` from the server, preserves
Firestore-specific errors, and signs out if the profile cannot be read. It does not
grant a role to a missing profile or to a hard-coded email address. A definitively
rejected new registration rolls back only the account created by that operation.
An ambiguous write/rollback failure explicitly reports the retained account.

## Deployment prerequisite — not yet applied

Review the deployed Firestore Rules in Firebase Console. Merge
`firestore-users.rules.fragment` inside the existing database documents match,
replacing the existing users rule only. Preserve and review rules for other
collections. Do not use public `allow read, write: if true` rules. Overlapping
allow rules are ORed, so an existing wildcard grant must also be reviewed.
This fragment has not been verified against the deployed rules or a rules emulator.

Use the Rules Playground to verify: unsigned users cannot read/write profiles;
signed-in users can create/get only their own user profile; they cannot create an
admin role or change roles; admins can list users. Check normal user login,
admin login, fresh registration and duplicate registration after publishing.

## Repair accounts from earlier failed registrations

An authorized project administrator must inspect Authentication > Users and
Firestore > users. Match each account by Firebase UID, not by a guessed email.
If a user profile is missing because registration failed, restore the verified
profile under that exact UID with `uid`, `firstName`, `lastName`, `phone`, `email`,
`role: user`, and `createdAt`. Obtain missing personal details from the account
owner. Do not recreate deliberately removed profiles or assign admin privileges
without confirming the intended role. Never store the password in Firestore.

Existing records were not changed by this repair. Browser access to Firebase
redirected to Google sign-in and was blocked by automatic approval review.
