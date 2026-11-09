# Design: Online Sync (Offline-First) for Pet Supplies Inventory

**Date:** 2026-11-09
**Status:** Awaiting approval (no code until approved)
**Written for:** the shop owner (to approve) and the developer who will build it.

---

## 1. Intent / Why

Today the app (Meng's Store / "Pink Paw") runs as a single-device app with all data
stored locally on that one device (sqflite). The owner wants the shop's **5 staff**,
across multiple devices, to share **one set of live data** — enter stock or a sale on
one device and everyone else sees it — with each person **logging into their own
account**.

Critically, the shop cannot be blocked by bad wifi: the app must stay **fully usable
offline** (record sales, stock changes, expenses, etc. with no connection) and
**auto-sync** both directions once a connection returns.

It will be hosted on the owner's existing **Hostinger regular (shared) web hosting**,
which provides **PHP + MySQL**.

## 2. Goals

- One shared dataset across all devices: inventory, categories, discounts, expenses,
  expense types, loans, suppliers, receipts/sales, purchase orders, stock adjustments,
  and user accounts.
- Per-person login with the **existing roles** (Super Admin / User / Cashier), verified
  by the server, working on every device.
- **Full offline use**: create/edit/record everything offline; auto-sync when back
  online, in both directions.
- **Correct stock math** even when several devices change the same item while offline
  (changes add up; one does not silently overwrite another).
- **Minimal disruption** to the existing Flutter UI and business logic — reuse the
  existing `AppDataStore` seam so screens barely change.

## 3. Non-goals (not in this version)

- Real-time, live "watch the number change" updates. We use refresh-on-open +
  pull-to-refresh + periodic/triggered sync instead (shared hosting can't run
  websockets reliably).
- Offline support **in a plain web browser**. Mobile and desktop only for v1; a browser
  build can be added later as online-only.
- Multiple stores / multi-tenant. This is one shop.
- Customer-facing features, online payments, barcode hardware integrations.

## 4. Anti-goals (would be a failure even if it technically runs)

- A sale or stock change **lost or double-counted** after syncing.
- Staff **blocked from ringing up a sale** because the internet is down.
- Passwords ever **sent or stored in plain text**.
- The owner forced into real server/devops work beyond basic Hostinger setup steps.

## 5. Constraints (what we're building on)

- **Hostinger shared hosting:** PHP (8.x) + MySQL, Apache, free SSL available. No
  long-running processes, no websockets, limited shell. Backend must be deployable by
  uploading files and importing a `.sql` file, and should keep third-party dependencies
  minimal (plain PHP + PDO, or a tiny vendored micro-framework).
- **~5 users**, small data volumes, shop-owned/trusted devices.
- **Existing app:** Flutter + sqflite, already funnels all data access through one
  interface, `AppDataStore` (`lib/data/local_database.dart`). Integer primary keys are
  used today and referenced across tables (e.g. a receipt line points at an inventory
  item id). This is the main thing that has to change for offline-first.

## 6. Architecture overview

Three pieces:

1. **Flutter app (local):** sync metadata on each record, a sync engine, an API client,
   and a new data-store layer that writes locally first and queues changes to sync.
2. **Backend (Hostinger):** a PHP REST API + MySQL schema mirroring the app's data, with
   auth and a sync endpoint.
3. **The sync protocol** between them.

### 6.1 Record identity — the foundation

**Problem:** auto-incrementing integer IDs collide across devices that are offline at the
same time (two devices both create "item 42").

**Decision:** every syncable record gets a **globally-unique ID (UUID), generated on the
device when the record is created**. The UUID is the primary key on both the local and
the server database, so IDs never need remapping and cross-references stay valid across
all devices.

- This changes `id` from `int` to `String` across the syncable models and local tables.
  It's a wide but mechanical change, isolated to the models and the local DB layer.
- The one-time data migration (§6.6) converts existing integer IDs to UUIDs while keeping
  all the cross-references pointing at the right rows.
- *Alternative considered:* keep integer IDs plus a separate UUID/server-id mapping.
  Rejected — it means remapping foreign keys on every sync, which is more fragile.

### 6.2 Sync metadata (added to every syncable table)

- `id` TEXT (UUID) — primary key
- `updated_at` INTEGER (ms since epoch) — when the row last changed
- `is_deleted` INTEGER (0/1) — soft-delete "tombstone" so deletions propagate instead of
  silently reappearing from another device
- Local-only: `dirty` INTEGER (0/1) — has local changes not yet pushed to the server

The server keeps `updated_at` and `is_deleted` too, plus its own receive timestamp.

### 6.3 Conflict rules

- **Ordinary fields** (names, prices, notes, categories, supplier details, etc.):
  **last-write-wins** by `updated_at`. Fine for a small shop.
- **Deletions:** a newer tombstone wins.
- **Stock quantities:** *not* last-write-wins — handled by movements below, because two
  people each selling the last units must **both** count.

### 6.4 Stock correctness via "movements"

Stock changes come from sales (receipt lines), stock adjustments, approved purchase
orders, and manual stock edits.

**Decision:** treat each stock-changing event as an **immutable movement with its own
UUID**. On sync, the server **applies each movement exactly once** (idempotent by UUID)
to compute the authoritative stock, then sends the reconciled stock back to every device.

- Sales, stock adjustments, and purchase-order receipts are *already* discrete records in
  the current app — they map naturally onto movements.
- **Manual stock edits** in the item editor (typing an absolute number) are converted into
  an adjustment movement for the *difference* vs. the previous value, so they compose
  correctly instead of overwriting.
- The server is the source of truth for the reconciled `stock` number; between syncs each
  device shows its own optimistic local stock, then reconciles on sync.

This keeps the app's existing "an item has a stock number" display logic mostly intact
while making that number correct under concurrent offline edits.

### 6.5 Authentication (online and offline)

- Server stores users with **bcrypt-hashed passwords** (`password_hash`). Roles unchanged.
- **Online login:** app POSTs username + password over HTTPS; server verifies and returns
  an auth **token** (stored in a tokens table) plus the user record. Token is sent as a
  Bearer header on later calls.
- **Offline login:** the user-accounts table (including the bcrypt hashes) syncs to the
  shop's devices, so any of the 5 staff can sign in offline; the app checks the typed
  password against the cached hash. *(Trust assumption: all devices are shop-owned/
  trusted. Flagged in §10.)*
- Deactivating a user (existing Super Admin user management) invalidates their token and
  blocks future logins once that change syncs.

### 6.6 One-time data migration ("move my current data online")

- Convert the existing local integer-ID data to UUIDs (fixing up all cross-references).
- Mark every row `dirty` so the **first sync uploads all current data** to the fresh
  server database. This is how the owner's existing inventory, receipts, etc. move online
  with nothing lost.

## 7. The backend (PHP + MySQL on Hostinger)

A small REST API over HTTPS, JSON in/out:

- `POST /auth/login` → `{ token, user }`
- `POST /auth/logout`
- `POST /sync` → the app sends `{ last_sync_at, changes: {table: [rows…]}, movements: [...] }`;
  the server applies them in a transaction and returns
  `{ server_time, changes: {table: [rows…]}, stock: {item_id: qty} }`. One round-trip does
  both push and pull.
- `POST /images` → upload an image file, returns its URL; images served statically.

MySQL schema mirrors the local tables, with the sync metadata columns from §6.2. A
`schema.sql` file is imported once via phpMyAdmin.

## 8. The Flutter app changes

- **Models** (`lib/models/app_models.dart`): `id` `int` → `String` (UUID) across syncable
  models; add `updated_at` / `is_deleted` where needed; update `toMap`/`fromMap`. Wide but
  mechanical.
- **Local DB** (`lib/data/local_database.dart`): new columns + a schema migration; writes
  mark rows `dirty` and bump `updated_at`.
- **New `ApiClient`**: login, sync, image upload (adds `http`, `connectivity_plus`,
  `uuid` packages).
- **New `SyncedDataStore implements AppDataStore`**: all writes go to local sqflite first
  (so the app is instant and works offline); reads come from local, unchanged. Because the
  whole app already talks to `AppDataStore`, the screens barely change.
- **`SyncService`**: runs on app start, when connectivity returns (`connectivity_plus`),
  after local changes (debounced), on pull-to-refresh, and on a periodic timer while
  online. Shows a small **sync status** indicator (offline / syncing / last-synced time).
- **Auth** (`_signIn` in `lib/main.dart`): try the server when online, fall back to the
  cached-hash check offline; store the token + current user.

## 9. Images

- Inventory images are local file paths today. Add `image_url` (the shared reference)
  alongside the existing `image_path` (kept as the on-device cache).
- Offline, the image file stays local and is queued; on sync it uploads, the server
  returns a URL, and `image_url` syncs so other devices can download and cache it.

## 10. Deployment on Hostinger (owner-facing, done once)

1. Create a MySQL database + user in hPanel.
2. Upload the PHP files (File Manager or FTP) into `public_html/api` (or an `api.`
   subdomain).
3. Import `schema.sql` via phpMyAdmin.
4. Put the DB credentials in a config file (real secrets not committed to git).
5. Enable the free SSL certificate; the app points at `https://<domain>/api`.

A short written runbook will be provided.

## 11. Suggested build order (for the later implementation plan)

1. Backend: schema + auth + sync endpoint + image upload (buildable/testable on its own).
2. App: UUID model/DB migration; `ApiClient`; `SyncedDataStore`; `SyncService`; online/
   offline auth; sync-status UI.
3. Data migration + first full upload; image upload path.
4. Hardening: conflict edge cases, retry/backoff, partial-sync failures, token
   revocation, and tests (unit tests for the stock-merge/conflict logic; an integration
   test simulating two offline devices).

## 12. Left to the builder

- Plain PHP vs. a tiny micro-framework (must run on shared hosting with minimal deps).
- Exact sync batching/pagination and retry/backoff policy.
- Sync-status UI styling (match the existing pink "Pink Paw" theme).
- Test specifics.

## 13. Decisions I made for you — please check these

- **Devices:** mobile (Android + iPhone/iPad) and desktop are supported offline; plain
  **web browser is out of scope for v1** (added later as online-only if wanted).
  *(Defaulted — the question was skipped.)*
- **Existing data:** **migrated up** to the server on first sync; nothing lost.
  *(Defaulted.)*
- **User accounts (with hashed passwords) sync to all 5 devices** so anyone can log in
  offline — this assumes every device is trusted/shop-owned.
- **Manual stock edits become adjustment movements**, so stock stays correct under
  concurrent offline edits.
- **API location** (`<yourdomain>/api` vs. an `api.` subdomain) decided at deployment.
- **Updates are near-real-time, not instant** — on open, on reconnect, pull-to-refresh,
  and a periodic check — not a live streaming feed.
