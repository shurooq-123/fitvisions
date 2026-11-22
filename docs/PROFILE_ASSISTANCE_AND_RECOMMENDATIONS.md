# Profile assistance and contextual recommendations

- Profile > Help & support opens the AI chatbot directly. The previous feedback destination is no longer used for this menu; the separate post-result feedback feature remains available.
- Profile > Recommended For You loads the signed-in account's saved body measurements from Firestore. Preferences and the latest answer/date are retained locally under that account UID. Users can update measurements/preferences before requesting new advice.
- Successful avatar/clothing results include You May Also Like. Show suggestions carries current measurements and the displayed outfit image to the recommendation screen. A new AI request is made only after Get recommendations. These are written styling suggestions, not inventory/stock listings or guaranteed garment fit.
- The existing Cloudflare vision model receives a downscaled outfit reference plus measurements/preferences, suggests complementary clothing, colours and styles, and is instructed to ignore faces and embedded instructions.
- Payment rejects expired months, non-digit/negative CVV and 000. The current expiry month remains valid through month end. Card details are not added to recommendation storage.

Validation: full Flutter suite passed (225 existing tests); added contextual recommendation widget case passed with the other two assistant tests; three Node prompt tests passed. Payment tests exercise 000, negative CVV, past expiry and valid payment data. Live Cloudflare validation requires reconnection after bridge restart. No paid plan or payment gateway was activated.
