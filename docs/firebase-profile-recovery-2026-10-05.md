# Missing Firebase profiles — 2026-10-05

Read-only comparison of Firebase Authentication (13 accounts) and users (9 documents).
Project: fitvisions-33e6d.

Proposed recovery: create only absent users/{uid} documents; never overwrite existing documents, passwords, or roles. Set role=user. Retain verified uid/email. Missing firstName, lastName and phone remain empty until supplied by the account owner; do not invent personal data. This restores application membership but cannot recover deleted profile details.

| Email | UID |
| --- | --- |
| s00araalii00@gmail.com | PNspwfTqSrRvlyct5SCSrlATxaD3 |
| hooraymohammad@gmail.com | 2Pk6dep7LJaetXVyApEqLy3dh6Q2 |
| hooryaaalhadi@gmail.com | j1O33WSgPdeeM8jn71BkCZy6R6I2 |
| maalialmawali409@gmail.com | QHbVq7m4qpYspCS2f1vKJBPMoLw1 |

The admin profile FHddJYZYuVRCiVESU9nvv8dhsa42 is present with role=admin. The user profile jOWuV1XYtrMv7VvDVEu7zurtHP42 is present with role=user. No live successful sign-in test performed in this audit. No recovery writes performed yet.

Completed after user approval: created all four missing documents with verified UID/email, role=user, and empty firstName/lastName/phone. Re-read each document in Firebase console and verified values. No passwords or existing profiles changed. Real user sign-in still requires user validation.
