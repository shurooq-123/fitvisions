# AI emulator trial

Both Generate Avatar and Create Clothes open a real generation screen with explicit Cloudflare submission, progress, retry, image editing and PNG download. Avatar measurements are approximate visual guidance, not a dimensional body model or a sizing guarantee. Both reference photos are optional. Measurements still save through the existing Firebase service; generated images remain in the current screen until downloaded.

This is a local Android debug trial, not a deployed production backend. `tools/ai-local-server.mjs` binds only 127.0.0.1:8787 and forwards requests to Cloudflare FLUX.2 klein 4B. The Cloudflare token stays in the server process memory. RSA-OAEP-SHA256 transfers it without plaintext files. A temporary random session credential in ignored `build/ai-local-config.json` protects the loopback API; it is not the Cloudflare token. Requests have body/prompt limits, one in-flight generation, a 40-generation session cap and a 180-second upstream timeout. Restarting the bridge requires rebuilding with its new session configuration.

Run the bridge, supply the credential through the encrypted exchange, then:

```powershell
adb reverse tcp:8787 tcp:8787
flutter build apk --debug --dart-define-from-file=build/ai-local-config.json
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

The laptop bridge and ADB reverse must remain active for the emulator trial. Release builds disable this integration. A production deployment needs a hosted HTTPS backend, Firebase ID-token verification and per-user quotas; never embed the Cloudflare key in Flutter.

The opt-in `integration_test/ai_live_test.dart` consumes two real generations using synthetic measurements and no private photographs. Run with the same dart-define file and emulator. The normal unit/widget suite uses no live service.

## Validation, 1 October 2026 (Asia/Muscat)

- Flutter analysis: passed; unit/widget suite: 62 passed.
- Live Android integration: both generation screens received and displayed images from Cloudflare. Clothing response 14.8 seconds; measurement-guided avatar response 13.3 seconds (two samples, not a latency guarantee).
- Local bridge rejected an unauthenticated generation request with HTTP 401.
- No Firebase authentication credentials or personal photographs were used by the live generation test. The questionnaire-to-result route is available in the normal application; users confirm submission on the result screen.
