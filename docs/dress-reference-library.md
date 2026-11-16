# User dress references — 2026-10-05

The six user-supplied collages are copied unchanged into images/dress_reference_{white,blue,black,green,brown,red}.png. They contain 6 + 12 + 7 + 5 + 6 + 14 = 50 individually described garments. Classification is exported in dress-reference-catalog.csv. Fabric, occasion, lengths and styles are visual estimates, not manufacturer facts. No size measurements can be inferred from these collages.

Generate Clothes offers the library and ranks compatible women’s dress references by silhouette, length, neckline, sleeves, favourite colour, fabric appearance, style and fit. This is a heuristic ordering, not a calibrated similarity percentage. User selects the reference explicitly. The currently supplied library has no male, child, teen or abaya references.

Each selected reference is cropped at runtime with normalized coordinates. Original sheets remain intact; only the selected garment crop is prepended to generation images. Optional face is still last, with a separate prompt role. Selecting a ready-made outfit clears the dress reference and vice versa. Incompatible gender/age/abaya changes clear the dress reference. User preferences override differences with the selected reference. History receives its ID and description.

No model training, remote library upload, or live AI call was performed. Flutter analyzer passes. Regression tests for metadata, ranking and runtime crops were added, but execution and APK installation remain unverified because Windows Application Control blocked the Flutter compilation runtime in this session. Crop regions were assigned from the supplied images; runtime visual QA remains pending with that blocker.

## Update installed — 2026-10-05

After the user changed the Windows setting, Flutter debug APK compilation succeeded. Installed with adb install -r on emulator-5554 (Mobile_API_36) and launched com.example.fitvisions/.MainActivity. Nine targeted tests passed across history_feedback_test, outfit_catalog_test, dress_reference_test and create_clothes_test, including all 50 runtime crops. This supersedes the compilation/test blockers noted earlier. This build uses no stale local AI credentials; reconnecting live AI remains separate and unverified.
