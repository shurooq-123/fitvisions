# Local push notification worker

Run `notification-worker.mjs` from the project root after Firebase CLI login. Set `FITVISIONS_FIREBASE_CLI_LIB` to the absolute Firebase CLI `lib` directory (the project uses `tools/firebase-tests/node_modules/firebase-tools/lib`). Credentials remain in the CLI credential store; never bundle them in the app.

The worker checks every 30 seconds, creates persistent notification records, and sends FCM notification payloads for OS display while the app is backgrounded. It handles payment confirmations, renewals and reminders within three days of expiry. The subscription snapshot supplies the amount and calendar duration. Device receipts reduce duplicate sends on retries; network ambiguity can still cause at-least-once delivery.

The laptop must remain awake and online. This is not an always-on cloud deployment. Firebase Functions remain prepared for future deployment; no paid plan is enabled. Android notification permission and a registered FCM device token are required. Historical payments older than five minutes at worker startup are not replayed. Failed sends remain pending for retry.

The existing Notifications screen provides history and read/unread state. Opening it marks visible notifications read and clears their badge count.

Validation: `node --test tools/login-mail/notification-worker.test.mjs`. Automated checks cover Oman calendar month boundaries, expiry, renewal content and FCM payload/receipt handling. Physical background delivery still requires a connected test phone; mocked delivery is not evidence of device receipt.
