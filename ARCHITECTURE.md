# Chatori Finance — Technical Architecture & Build Plan

> Status: **Plan for review** (no app code written yet)
> Target: Offline-first Android APK for catering + cloud kitchen finance tracking
> AI scope for MVP: **Rules-only** (zero data leaves the device)
> Date: 2026-06-30

---

## 1. Stack decision

**Recommendation: Flutter (Dart) + Drift (SQLite) + Google ML Kit on-device OCR.**

You asked for the stack that is *feasible for me to build*, has *good security infra*, and is *fast*. Flutter wins on all three:

| Constraint | Why Flutter | 
|---|---|
| **Feasible** | One codebase, huge package ecosystem for every PRD feature (DB, OCR, charts, biometrics, CSV/PDF). Single `flutter build apk` produces the APK. iOS is a free option later if you ever want it. |
| **Secure** | Encrypted DB via **SQLCipher** (`drift` + `sqlcipher_flutter_libs`), OS keystore-backed secrets via **`flutter_secure_storage`**, biometric/PIN lock via **`local_auth`**. All standard, battle-tested. |
| **Fast** | Compiled to native ARM (AOT). 60fps UI, sub-second cold start on mid-range phones. Easily meets the PRD's "<3s open, <10s to add a transaction." |
| **Offline OCR** | **Google ML Kit Text Recognition** runs fully on-device, no network, no per-call cost. Perfect for reading Paytm screenshots. |

### Why not the others
- **Native Kotlin** — best performance but ~2x the code and Android-locked. The marginal speed gain doesn't justify the slower build for a CRUD + OCR app.
- **React Native / Expo** — fine, but the offline-OCR + encrypted-DB story is rougher and the native bridge adds friction for the screenshot pipeline.
- **Capacitor/Web** — weakest offline feel and OCR; not worth it for a daily-use money app.

### Core dependencies (all free, offline-capable, actively maintained)
```
drift                       # type-safe SQLite ORM (compile-time checked queries)
sqlcipher_flutter_libs      # encrypted database engine
sqlite3_flutter_libs        # sqlite native libs
flutter_secure_storage      # OS keystore for the DB encryption key
local_auth                  # fingerprint / face / device PIN
google_mlkit_text_recognition  # on-device OCR
image_picker                # pick Paytm screenshots from gallery
fl_chart                    # reports / charts
intl                        # currency (₹) + date formatting
csv                         # CSV export/import
pdf + printing              # PDF reports (post-MVP)
path_provider               # local file paths for backups/attachments
riverpod (flutter_riverpod) # state management
go_router                   # navigation
```

---

## 2. Security architecture

Privacy is a first-class PRD requirement ("all data stays on the phone", "encrypted DB preferred", "optional PIN/biometric").

1. **Encrypted database at rest** — Drift over SQLCipher (AES-256). The whole `.sqlite` file is unreadable without the key.
2. **Key management** — a random 256-bit key is generated on first launch and stored in **`flutter_secure_storage`**, which is backed by the Android Keystore (hardware-backed on most devices). The key is never hardcoded and never leaves the device.
3. **App lock** — optional PIN + biometric gate (`local_auth`) on cold start and on resume after a timeout. Configurable in Settings.
4. **No network by default** — the app ships with **no internet permission needs** for core features. Rules-only AI means there is literally nothing to upload. (If you later opt into a cloud LLM, it becomes an explicit, toggled feature.)
5. **Attachments** — imported screenshots are copied into the app's private storage (`getApplicationDocumentsDirectory`), not left only in the public gallery, and referenced by `attachmentPath`.
6. **Backups are user-controlled** — export writes an (optionally password-protected) file to a location the user picks; nothing auto-syncs.

---

## 3. Layered architecture

```
┌─────────────────────────────────────────────┐
│  Presentation  (screens, widgets, Riverpod)  │  tap-first, big buttons
├─────────────────────────────────────────────┤
│  Application   (use-cases / services)        │  e.g. PaySalaryService,
│                                              │  AdvanceAdjustmentService,
│                                              │  ImportScreenshotService
├─────────────────────────────────────────────┤
│  Domain        (entities, rules engine)      │  accounting rules,
│                                              │  classification, dedup
├─────────────────────────────────────────────┤
│  Data          (Drift DAOs, repositories)    │  encrypted SQLite
│                OCR adapter, file/backup IO    │
└─────────────────────────────────────────────┘
```

Folder layout:
```
lib/
  main.dart
  app/                 # router, theme (light/dark), app lock gate
  core/                # constants, ₹ formatting, result types, categories
  data/
    db/                # Drift tables, database.dart, DAOs
    repos/             # TransactionRepo, StaffRepo, AdvanceRepo, ...
    ocr/               # ML Kit adapter + Paytm parser
    backup/            # CSV export/import, backup file IO
  domain/
    models/            # plain Dart entities
    rules/             # classifier, duplicate detector, summarizer
  features/
    home/              # dashboard
    transaction/       # add income/expense flow
    salary/            # staff + salary records
    advances/          # advance tracking
    screenshot/        # import + OCR confirm flow
    reports/           # charts + summaries
    settings/          # backup, categories, staff, app lock
```

---

## 4. Data model (PRD → Drift tables)

All money stored as **integer paise** (₹1 = 100) to avoid floating-point errors — formatted to ₹ at the UI edge.

### `transactions`
| column | type | notes |
|---|---|---|
| id | text (uuid) | PK |
| type | text | `income` \| `expense` |
| category | text | FK-ish to category list |
| subcategory | text? | |
| amountPaise | int | |
| dateTime | datetime | indexed |
| paymentMode | text | cash/upi/paytm/bank/other |
| partyName | text? | vendor/person |
| notes | text? | |
| source | text | manual / screenshot / rules |
| tag | text? | catering / cloud_kitchen / event / other |
| attachmentPath | text? | local file for screenshots |
| createdAt / updatedAt | datetime | |

### `staff`
id, name, role, monthlySalaryPaise, joinedDate, activeStatus (bool), notes.

### `salary_records`
id, staffId (FK), amountPaidPaise, month (YYYY-MM), paymentDate, paymentMode, notes, advanceAdjustedPaise.

### `advance_records`
id, personName, personType (staff/vendor/helper/other), amountPaise, date, reason, recoveredAmountPaise, status (`open`/`partial`/`closed`), linkedSalaryRecordId?, linkedStaffId?.

### `screenshot_imports`
id, imagePath, extractedText, extractedAmountPaise?, extractedDate?, extractedType?, confidenceScore, status (`draft`/`confirmed`/`discarded`), createdTransactionId?.

### `categories` (seeded, user-editable)
Seeded from the PRD expense heads: Salaries, Advances, Groceries, Transport, Oil, Veggies, Dairy, Packaging, Gas/Cylinder, Rent, Electricity, Repairs, Marketing/Ads, Miscellaneous. Plus income types: Catering, Cloud Kitchen, Other. Each row: id, name, kind (income/expense), icon, isDefault, sortOrder.

**Derived values (computed, not stored):** pending salary = monthlySalary − paid-this-month; outstanding advance = amount − recovered; today's net = income − expense. Computed via DAO queries so totals are always consistent.

---

## 5. Rules engine (the "AI Assist" for MVP)

Deterministic, on-device, explainable. Pipeline: **OCR/text → normalize → classify → confidence → user confirm.**

1. **Category classifier** — keyword map per category (`"sabzi","veg","vegetable" → Veggies`; `"petrol","auto","cab" → Transport`; `"salary","tankha" → Salaries`, etc.) matched against notes/party/OCR text. Includes common Hindi/Hinglish terms.
2. **Income vs expense** — Paytm "paid to / sent" → expense; "received from / added" → income. Also inferred from sale-type keywords.
3. **Vendor/person suggestion** — pull the most frequent `partyName` previously paired with the matched category.
4. **Duplicate detection** — flag entries with same amount + same day + similar reference text (Levenshtein on notes/txn-id) within a window.
5. **Advance sanity check** — warn if a salary advance for a staff member looks already paid/adjusted this month.
6. **Plain-language summary** — template-based monthly/daily recap: *"June: income ₹X, expenses ₹Y (top: Groceries ₹Z), net ₹N. Salaries paid ₹S, advances outstanding ₹A."*

Every uncertain suggestion shows as an editable pre-fill — **user confirmation is always required**, per the PRD. The classifier is a swap-in interface, so a real LLM can replace it later without touching the UI.

---

## 6. Paytm screenshot OCR pipeline

```
Pick image (image_picker)
   → copy into app private storage
   → ML Kit TextRecognition (on-device)
   → PaytmParser: regex for ₹ amount, date/time, "Paid to/Received from",
     UPI ref / txn ID, party name
   → run rules engine (category, type, confidence)
   → ScreenshotImport saved as 'draft'
   → user reviews pre-filled Add-Transaction form
   → confirm → Transaction created (source = screenshot), import marked 'confirmed'
```
Robust to varied screenshot quality: the parser degrades gracefully — whatever it can't extract is left blank for the user to fill, never blocks the flow.

---

## 7. Screens & navigation (tap-first)

`go_router` routes. Large buttons, minimal typing, recent-value defaults.

1. **Home/Dashboard** — today's income/expense/net cards, pending salaries/advances/receivables, big Quick-Add buttons, recent entries, period summary toggle (day/week/month).
2. **Add Transaction** — income/expense toggle → category grid → amount keypad → payment mode chips → save. 3-tap target.
3. **Salary** — staff list with status; pay full / pay partial / add advance / adjust advance; staff-wise history.
4. **Advances** — open advances, recovery status, add advance, mark recovered.
5. **Screenshot Import** — pick image → OCR preview → confirm/edit.
6. **Reports** — month/week selector, category pie, cash-vs-UPI, catering-vs-cloud-kitchen, salary total, advance outstanding, top vendors, trend line.
7. **Settings** — backup/restore, CSV export, category management, staff management, app lock/PIN, theme.

Search/filter (PRD 9.9) available on a transactions list: date range, category, payment mode, staff, vendor, income/expense, tag.

---

## 8. Reports & export

- Charts via `fl_chart` (pie for category split, bars for cash/UPI and revenue split, line for trends).
- **CSV export/import** in MVP (`csv` package) — full transaction dump + re-import for backup/restore.
- **PDF reports** deferred to post-MVP (`pdf`/`printing`) per the PRD.
- Backups: write a single file (DB copy or CSV bundle) to a user-chosen folder via the system file picker.

---

## 9. Build order (milestones)

Follows the PRD's suggested order, sliced into shippable increments:

| # | Milestone | Deliverable |
|---|---|---|
| **M0** | Project + security shell | Flutter app, encrypted Drift DB wired, app lock gate, theme, navigation skeleton. |
| **M1** | Income/expense entry | Add-Transaction flow + category grid + transactions list. Core daily use works. |
| **M2** | Dashboard | Home cards, recent entries, period summaries, quick-add. |
| **M3** | Salary + advances | Staff module, salary records, advance tracking + adjustment logic. |
| **M4** | Reports & search | Charts, filters, summaries. |
| **M5** | Screenshot OCR | ML Kit pipeline + Paytm parser + confirm flow. |
| **M6** | Rules engine | Classifier, duplicate/advance warnings, summaries wired into entry + import. |
| **M7** | Backup/export | CSV export/import, local backup. |
| **M8** | Polish | Defaults from recent usage, dark mode, performance pass, PIN/biometric polish. |

I'll build and verify each milestone before moving on, and keep the rules engine behind an interface so a cloud LLM can slot in later.

---

## 10. Dev environment (Windows — what you'll need)

To compile the APK on this machine you'll need, one-time:

1. **Flutter SDK** (stable channel) — `git clone` or zip, add to PATH.
2. **Android Studio** — for the Android SDK, platform tools, and an emulator (or use a physical phone via USB debugging).
3. `flutter doctor` should pass (accept Android licenses with `flutter doctor --android-licenses`).
4. Build debug APK: `flutter build apk --debug`; release: `flutter build apk --release` (we'll set up a signing key for release).

I can write all the code regardless; you'd run these to produce/install the APK. I'll flag exactly when you need them (first at M0 to run the shell).

---

## 11. Key risks & how the plan handles them

| Risk (PRD §21) | Mitigation |
|---|---|
| OCR accuracy varies | Parser degrades gracefully; user always confirms; never blocks on a missing field. |
| AI suggestions wrong | Rules are explainable + always editable; confirmation mandatory. |
| Feature creep → slow app | Integer-paise math, indexed queries, milestone slicing, lean MVP scope. |
| Local-only = no multi-device | CSV/file backup now; user-controlled cloud backup listed as future enhancement. |
| Payroll/advance confusion | Advances tracked as money-out but not counted as final salary expense until adjusted; explicit status lifecycle (open/partial/closed). |

---

## 12. Open questions for you

1. **Currency/locale** — assume ₹ INR, English UI with Hinglish category keywords. OK, or do you want full Hindi labels too?
2. **App lock default** — on or off out of the box? (I'd default *off*, prompt to enable on first launch.)
3. **Receivables** — the dashboard shows "pending receivables." Do you want a lightweight credit-sale/customer-owes tracker in MVP, or just a manual number for now? (PRD lists full receivables as a *future* enhancement, so I'd keep it minimal in MVP.)
4. **Single business only** for MVP (multi-business is a future item) — confirm.
```

When you've reviewed, say the word and I'll start at **M0** (project scaffold + encrypted DB + app lock).
