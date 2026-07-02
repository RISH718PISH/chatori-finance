# Chatori Finance

A tap-first finance tracker for a catering + cloud-kitchen business. Flutter
(Android), with cloud sync across devices via Supabase.

## Install on your phone

Go to the repo's **[Releases](../../releases)** page → open **Latest build** →
download **`app-release.apk`** → open it on your phone to install.

> The first time, Android may ask you to allow installing apps from this source
> — tap **Settings → Allow**, then reopen the APK.

Every push to `main` automatically rebuilds the APK and updates that release, so
to update the app you just re-download the latest `app-release.apk`.

## What it does

- Add income / expense in a few taps (₹, kitchen-specific categories)
- Shared books for multiple owners (sign in; invite by email)
- Cloud-synced so each device sees the same data
- **Events**: track each catering party's P&L — revenue vs linked expenses,
  per-plate cost, money left to collect
- **Monthly P&L** in Reports: Revenue → COGS → Gross profit → Operating →
  Net, with food-cost % warning and month-over-month deltas
- **Scan bill**: Paytm/UPI screenshots *and* Hyperpure invoices are read
  on-device (OCR) into a pre-filled entry you review; the bill photo is
  attached to the saved entry
- Salaries & staff advances (with advance deduction), customer/vendor ledgers
- WhatsApp-ready summaries + CSV export
- App lock (fingerprint / PIN), optional

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the design and build plan, and
[`supabase/schema.sql`](supabase/schema.sql) for the database setup.

## Developing

```bash
flutter pub get
flutter run            # run on a connected device/emulator
flutter build apk      # release APK (needs android/key.properties for signing)
```

Backend config is in `lib/core/supabase_config.dart` (the anon key is a public
client key; data is protected by Row-Level Security).
