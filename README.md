# Family Expense Tracker

A premium, minimal Android expense & income tracker for one household, built with Flutter, Riverpod, and a free Google Sheets + Apps Script backend.

Family members: **T. Meenakshi Sundaran · Maheswari · Nitish · Shenbahaa** — one shared login, no separate accounts.

---

## 1. Architecture

```
lib/
  core/
    constants/    app-wide constants (members, categories, API config)
    theme/        colors, typography, ThemeData (light + dark)
    services/     ApiService, LocalCacheService (Hive), AuthService
    utils/        formatters, validators, category icon/color mapping
    widgets/      shared UI: buttons, form fields, cards, tiles, states
  models/         ExpenseModel, IncomeModel, BudgetModel, DashboardSummaryModel
  providers/      Riverpod StateNotifiers per feature (expense, income, budget, settings, auth, dashboard)
  routing/        go_router config with auth-based redirect
  features/
    splash/ auth/ dashboard/ expense/ income/ reports/ member/ budget/ settings/ pdf/
backend/
  Code.gs         Google Apps Script — the entire REST-style backend
```

Clean architecture, feature-based folders, repository-style `ApiService`, Riverpod for state — no business logic lives inside widgets.

---

## 2. Backend setup (Google Sheets + Apps Script) — do this first

1. Create a new Google Sheet. Add these tabs with header rows exactly as shown:

   | Tab | Columns (row 1) |
   |---|---|
   | `Expenses` | id, member, category, description, amount, paymentMode, date, time, remarks, createdAt |
   | `Income` | id, receivedBy, source, description, amount, date, createdAt |
   | `Budget` | category, limit, month |
   | `Settings` | key, value |
   | `Auth` | (leave A1 blank; put the SHA-256 hash of your family password in **B1**) |

   To generate the SHA-256 hash of your password, you can temporarily run this in the Apps Script editor's console:
   `Logger.log(Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, "yourpassword").map(b => (b<0?b+256:b).toString(16).padStart(2,'0')).join(''))`

2. Open **Extensions → Apps Script**, delete the default code, and paste in `backend/Code.gs` from this project.

3. In `Code.gs`, set `SHEET_ID` to your spreadsheet's ID (the long string in its URL between `/d/` and `/edit`).

4. Click **Deploy → New deployment → Web app**.
   - Execute as: **Me**
   - Who has access: **Anyone with the link**
   - Deploy, then copy the `/exec` URL.

5. Paste that URL into `lib/core/constants/api_config.dart`:
   ```dart
   static const String baseUrl = 'https://script.google.com/macros/s/XXXXXXXXXXXX/exec';
   ```

---

## 3. Flutter app setup

```bash
flutter pub get
flutter run
```

To build a release APK:

```bash
flutter build apk --release
```

> The debug signing config is used in `android/app/build.gradle` for simplicity. Before publishing, replace it with your own release keystore.

---

## 4. Fonts & assets

The theme references the **Poppins** font family at `assets/fonts/`. Download the four weights used (Regular, Medium, SemiBold, Bold) from [Google Fonts](https://fonts.google.com/specimen/Poppins) and place the `.ttf` files there — the app falls back to `google_fonts` package auto-download if you skip this, so it will still run without them, just add a first-launch network fetch for the font.

---

## 5. What's implemented

- Single shared-password login validated against the Apps Script backend, with local biometric unlock after first login
- Dashboard: balance, income/expense totals, today's & month's expense, category donut chart, quick actions, recent expenses
- Add/Edit/Delete Expense and Income, with full validation
- Expense list: search, category/member filters, sort, swipe-to-delete, pull-to-refresh
- Reports: Daily/Weekly/Monthly/Custom ranges, category & member summaries, PDF generation and native share sheet
- Member Wise spend breakdown with progress bars
- Budget: overall + per-category monthly limits with warning/over-budget coloring
- Settings: currency, theme (light/dark/system), reminder toggle, budget alert threshold, change password, logout
- Offline-first: expenses/income/budgets are cached locally (Hive) and shown instantly while the network call refreshes in the background
