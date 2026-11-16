# Generation history and feedback

Avatar and clothing generation (including edits) now saves a 320-pixel-wide PNG preview with its description, owner UID, email, kind and server timestamp in Firestore history. This works without Firebase Storage. These are previews, not original-resolution downloads. Save failures are reported in the generation screen.

Users see their own records; administrators open each user's history from Users. Both can open saved previews. Older descriptive activity remains visible; images never persisted cannot be recovered from descriptions. Legacy imagePath records continue using SavedImage.

Admin feedback uses message cards with five stars showing the stored rating. The system feedback list also includes older documents without createdAt.

The Firestore history schema update was published through Firebase Console on 2026-10-05. Existing owner/admin read restrictions were preserved. The preceding deployed rules are backed up in firestore-before-image-history.rules.

Validation: all 10 Firebase emulator security tests passed. Flutter widget execution is blocked by Windows Application Control preventing dartaotruntime.exe from running; no security setting was changed. The updated app has not yet been built or installed, and a live signed-in generation/history round trip remains unverified. AI reconnection remains pending.
