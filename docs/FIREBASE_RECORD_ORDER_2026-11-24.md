# Firebase record ordering and measurement history — 2026-11-24

- Admin user lists now sort registrations by createdAt descending, with undated legacy records retained at the bottom. Existing snapshot listeners continue to update the lists.
- Saving measurements writes the latest measurements document and a dated history snapshot in one Firestore batch. The snapshot uses the already permitted editData.measurements map. Previous history remains unchanged.
- History and admin history already default to newest first. Subscription and payment records remain independent immutable purchase snapshots; catalogue changes do not rewrite existing subscriptions.
- Firebase Console ordering is a view/query setting, not a physical database order. Use createdAt descending for users/history/subscriptions/payments and updatedAt descending for measurements. An orderBy query excludes legacy documents missing that field; no dates were invented or backfilled.
- Synchronization occurs after a successful Save/Generate/Subscribe/Pay action, not each keystroke. Offline changes require reconnection and successful commit. Local original photos, recommendation caches, and transient chat are not made cloud backups by this change.
- No production data migration or security rule changes are required. Phone installation is separate from this source update.
