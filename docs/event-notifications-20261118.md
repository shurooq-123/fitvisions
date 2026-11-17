# Event notifications — 18 November 2026

Reports are available only to the admin role. The report screen checks the role again before exporting.

After a generation or payment record is saved, the app queues its record ID in local preferences and displays a bilingual on-screen message. The local mail bridge verifies the Firebase ID token and record ownership, resolves the recipient from the registered account, writes notification history, and sends the email. Payment messages use the saved amount and durationMonths, not the current plan. Demo/pending payments are explicitly identified as uncharged.

The queue retries while the app runs and after sign-in/restart. Successful delivery is tracked on the notification document to avoid ordinary duplicate retries. An SMTP acceptance followed by a database failure can still result in a duplicate email. SMTP acceptance does not prove inbox delivery.

This setup requires the laptop mail bridge, sender setup, Firebase CLI authorization, network access, and USB port reversal 8789. It is not an always-on cloud service. Cloud Functions and background push were not deployed. Firestore rules deployment requires the user's explicit approval following the automatic review rejection.

Validation: 186 Flutter tests; 14 Firebase emulator tests; 5 event message/delivery tests (bilingual content, amounts/months, invalid records, cross-user rejection, registered recipient and retry deduplication). No real payment or real avatar email was sent as part of these automated tests.
