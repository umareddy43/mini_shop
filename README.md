# Grocery Shop Khata & Order Management App

An offline-first Flutter app for grocery shop owners to manage orders, a
customer credit ledger (khata), and shop inventory — designed for one-handed,
low-friction use at a busy counter.

## Tech stack

- **Flutter** (Material 3, `useMaterial3: true`)
- **Riverpod** (`flutter_riverpod`) for state management — plain
  `StateNotifierProvider`s and `FutureProvider`s, no code generation required
- **SQLite** (`sqflite`) for fully offline local storage
- **pdf** + **printing** packages for PDF bill/statement generation and the
  OS print/share sheet
- Clean, layered architecture: `models -> repositories -> providers -> screens`

The app needs **no internet connection** at any point.

---

## Folder structure

```
lib/
  core/
    constants/        # app_constants.dart - shop info, enums (OrderStatus, PaymentMode)
    theme/             # app_theme.dart - Material 3 theme + status colors
    utils/             # validators.dart, formatters.dart
    routing/           # (reserved - navigation currently handled by nested Navigators)
  database/
    database_helper.dart   # SQLite schema + singleton connection
  models/
    customer.dart, item.dart, order.dart, order_item.dart, payment.dart
  repositories/
    customer_repository.dart   # CRUD + khata (due) calculations
    item_repository.dart
    order_repository.dart      # orders + order_items, filters, dashboard stats
    payment_repository.dart
  providers/
    repository_providers.dart  # DI for repositories
    customer_provider.dart     # customer list/search/CRUD state
    item_provider.dart         # item list/search/CRUD state
    order_provider.dart        # order list/filter state + order creation service
    cart_provider.dart         # in-memory "draft order" for the Create Order flow
    khata_provider.dart        # khata list + per-customer detail (orders+payments)
    payment_provider.dart      # records payments, refreshes khata
    dashboard_provider.dart    # aggregated dashboard stats
    printer_provider.dart      # exposes the (stubbed) Bluetooth printer service
    pdf_provider.dart          # exposes the PDF service
  printing/
    printer_service.dart       # Bluetooth thermal printer abstraction (STUBBED - see below)
    receipt_formatter.dart     # plain-text 58mm receipt layout
  pdf/
    pdf_service.dart           # PDF bill + khata statement generation/printing/sharing
  screens/
    home/main_shell.dart       # bottom navigation shell (4 tabs, each with its own Navigator)
    create_order/              # Select Customer -> Select Items -> Order Summary
    orders/                    # Orders list (+ dashboard header) and Order Details
    khata/                     # Khata list, Customer Detail, Add Payment
    items/                     # Item List (add/edit/delete/availability)
  widgets/                     # shared, reusable UI pieces
  main.dart                    # entry point (ProviderScope + MaterialApp)
```

---

## About the Bluetooth thermal printer

Per your request, **Bluetooth printing is stubbed** rather than wired to a
real plugin, so the whole app can be built, run, and demoed without a
physical 58mm printer or Bluetooth permissions setup.

- `lib/printing/printer_service.dart` defines the `PrinterService`
  interface (`scanForDevices`, `connect`, `printOrderReceipt`, …) and a
  `StubPrinterService` implementation that simulates scanning/connecting
  with realistic delays and prints the formatted receipt text to the debug
  console instead of over Bluetooth.
- `lib/printing/receipt_formatter.dart` already builds the exact 32-char-wide
  receipt layout a real 58mm printer would need — this text (or ESC/POS
  bytes derived from it) is the payload you'd hand to a real plugin.

**To connect a real printer later:** add a plugin such as
`esc_pos_bluetooth`, `blue_thermal_printer`, or `print_bluetooth_thermal` to
`pubspec.yaml`, then implement the same three methods on `PrinterService`
using that plugin. No screen in the app needs to change — they all only
depend on `printerServiceProvider`.

PDF bill generation (`lib/pdf/pdf_service.dart`) is fully implemented using
the `pdf` and `printing` packages and works today: "Print Bill (PDF)" opens
the OS print/share preview from Create Order, Order Details, and the Khata
customer statement.

---

## Getting an installable .apk without installing Flutter yourself

This project includes a ready-to-use GitHub Actions workflow at
`.github/workflows/build-apk.yml` that builds the APK for you on GitHub's
servers — you never need Flutter, Android Studio, or a JDK on your own
machine.

### One-time setup (~5 minutes)

1. Create a new **public** repository on GitHub (public makes the final
   download link work with no login — see step 4).
2. Upload this whole project folder into it. Easiest way with no local git
   experience: on the repo page, use **Add file → Upload files**, drag in
   everything from this zip, and commit directly to `main`.
3. Go to the repo's **Actions** tab. A workflow called **"Build Android
   APK"** starts automatically within a few seconds of your upload
   finishing (it's also triggered by any push to `main`). Click into the
   running job to watch it — it takes roughly 5–10 minutes.

### Downloading the APK to your phone

You have two options once the workflow finishes (green checkmark):

- **Quick way (needs a GitHub login on your phone):** open the finished
  workflow run → scroll to **Artifacts** → tap
  `grocery-shop-app-apk` → it downloads a `.zip` containing the `.apk`.
- **Direct public link (no login needed on your phone) — recommended:**
  tag a release once, and every future push can be released the same way:
  ```bash
  git tag v1.0.0
  git push origin v1.0.0
  ```
  (No local git? On the GitHub website: **Releases → Draft a new release →
  pick/create tag `v1.0.0` → Publish**. This alone re-runs the workflow via
  the tag push and attaches the APK.) Once that run finishes, go to the
  repo's **Releases** page — the `app-release.apk` file there is a normal
  public download link. Open it in your phone's browser and it downloads
  straight to your phone.

### Installing the APK on your Android phone

1. Download the `.apk` (from Artifacts or Releases, above).
2. Tap the downloaded file. Android will prompt to allow installs from
   this source the first time ("Install unknown apps") — allow it just
   for your browser/file manager app.
3. Tap **Install**. The app appears in your app drawer as "Grocery Shop
   Khata".

This only produces an unsigned/debug-style release APK for your own
sideloading — it isn't set up for Play Store submission (that needs a
signing key and a bit more Gradle config, which I can add if you ever want
to publish it).

---

## How to run the project

This deliverable contains the Flutter `lib/` source and `pubspec.yaml` only
(no `android/`, `ios/`, `web/` platform scaffolding, since that's
machine/IDE-generated boilerplate best created fresh by Flutter itself).

1. **Create a fresh Flutter project shell** (requires the Flutter SDK
   installed locally):
   ```bash
   flutter create grocery_shop_app
   cd grocery_shop_app
   ```

2. **Replace** the generated `lib/` folder and `pubspec.yaml` with the ones
   from this deliverable (copy `lib/` and `pubspec.yaml` into the new
   project, overwriting the defaults).

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the app** on a connected device or emulator:
   ```bash
   flutter run
   ```

The app works fully offline from first launch — the SQLite database and
its tables (`customers`, `items`, `orders`, `order_items`, `payments`) are
created automatically the first time the app opens.

### Optional: seed some items to start with

The Item List starts empty. Add a few items from the **Items** tab (➕ Add
Item) before creating your first order — Create Order's item picker only
shows items marked **Available**.

---

## Notes on design decisions

- **Khata balances are always derived, never stored** — a customer's
  "pending amount" is computed on the fly as
  `SUM(order totals) - SUM(payments)`. This means it's always accurate even
  if orders/payments are edited or deleted later, with no risk of the
  stored balance drifting out of sync.
- **Order prices are snapshotted** at the time of the order (`order_items.price`),
  so editing an item's price later never rewrites historical bills.
- **Duplicate customer/item names are blocked** case-insensitively at the
  repository layer, so the rule holds regardless of which screen triggers
  the save.
- **Each bottom-nav tab owns its own `Navigator`**, so pushing a detail
  screen (e.g. Order Details, Customer Detail) keeps the bottom bar visible
  and preserves the other tabs' state/scroll position when you switch away
  and back.
