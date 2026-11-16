# Live connections verified — 2026-10-05

Cloudflare token FitVisions emulator October 5 created after explicit user approval, scoped to Workers AI Read/Edit on the existing account. Transferred through encrypted localhost setup form; retained only by local trial bridge process. No Cloudflare token stored in project/APK.

Firebase live integration test verified project fitvisions-33e6d and successfully read the signed-in user's profile from Firestore Source.server, with a valid user/admin role. No account/password was created or changed. This verifies the existing session, not fresh password login for every account.

Live emulator clothing and measurement-avatar generation test passed. Bridge measured 21.8 seconds for clothing and 34.8 seconds for avatar. Two integration tests passed. Generation test does not verify history persistence (its standalone harness does not initialize Firebase).

Normal debug APK rebuilt with current local-session configuration. Keep local bridge and laptop running; credential is intentionally memory-only. Restarting that server requires reconnection and an APK rebuilt with its new local session. This remains emulator-only trial integration, not a deployed production AI backend.
