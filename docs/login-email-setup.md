# Login email trial

Updated November 1: registration now calls `/registration` after the profile is
saved and before sign-out. It sends exactly `تم إنشاء حسابك في FitVisions بنجاح.`
Login sends exactly `تم تسجيل الدخول إلى حسابك في FitVisions بنجاح.` for both
user and admin. Neither message contains a verification link. Automatic Firebase
verification email and the Profile verification button were removed.
Registration email failure returns a warning without deleting the account or
preventing navigation to Login. Registration endpoint additionally requires a
recent server profile creation timestamp and uses a separate deduplication key.

The user and admin login screens request a notification only after successful
authentication and role checks. Failure does not undo login and is reported to
the user. SMTP acceptance is not proof of inbox delivery.

Run `node tools/login-mail/server.mjs` from the project directory. The setup URL
is in ignored `build/mail-setup-url.txt`. Enter the sender Gmail address and a
Google App Password there. Credentials stay in process memory; restarting the
server requires setup again. Do not put credentials in Dart, source control or
chat. Dependencies are installed with `npm ci --prefix tools/login-mail`.

For each Android device run `adb -s SERIAL reverse tcp:8789 tcp:8789`.
This implementation is a debug-only local trial and requires the laptop and USB.
It is not deployed hosting or an always-on production email service.

The server verifies Firebase JWT signatures, audience, issuer and recent
authentication, reads the role through Firestore rules and derives the recipient
from the verified token. Requests cannot choose another recipient or email body.
Notifications are deduplicated by UID and authentication time within the running
process. No passwords or tokens are logged. Production deployment needs HTTPS,
managed secrets, persistent deduplication/rate limits and delivery monitoring.

Validation: Dart analysis and Android build passed; missing sender setup returns
503 instead of reporting email success. Actual Gmail verification and delivery
for user/admin logins remain pending sender setup and live sign-in tests.
