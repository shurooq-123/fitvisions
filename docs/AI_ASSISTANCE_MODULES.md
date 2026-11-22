# AI assistance modules

## M1F1 — Recommendation Systems
Home > AI recommendations. Enter height/chest/waist/hips in cm or inches and clothing/colour preferences. The backend derives an illustrative size baseline using all three torso measurements, then Cloudflare Gemma explains the suggested starting size and recommends colours from the stated preferences. This is AI-assisted advice with a deterministic chart baseline, not a trained sizing model or a guarantee of garment fit. No skin tone or gender is inferred.

## M2F1 — AI Chatbot for Assistance
Home > AI assistant. Questions and recent conversation context are sent to Cloudflare Gemma through the existing local AI bridge. The assistant is grounded in current app instructions (upload, optional face, measurements, edit/history, subscriptions, language/theme and troubleshooting). Responses are in the selected UI language. It cannot change account data or perform payments. Conversation is in memory for this page; Clear conversation removes it. Failed questions remain available to retry.

## Implementation
- `lib/screens/ai_assistance_screen.dart`: forms, chat, progress and retry.
- `lib/services/ai_generation_service.dart`: authenticated local/cloud request abstraction.
- `tools/assistant-prompts.mjs`: validated request shape, chart baseline and guidance.
- `tools/ai-local-server.mjs`: /chat and /recommendations, Gemma inference.

The local bridge and USB forwarding must remain active. Cloud endpoints require a corresponding deployment; only the local bridge was updated. No new paid plan was enabled. Personal measurements/preferences are sent only when requesting recommendations; chat text is sent only when sending a question. Responses can be inaccurate and should not be represented as guaranteed results.

Validation on 22 November 2026: 223 Flutter tests passed, focused retry/empty-input tests passed, two Node prompt-validation tests passed. Live /chat and /recommendations both returned HTTP 200 using synthetic input. The Arabic recommendation returned M for chest 93/waist 75/hips 99, plus blue/beige/light grey and a brand-size caveat. No real user data was needed for these tests.
