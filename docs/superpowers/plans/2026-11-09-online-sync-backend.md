# Online Sync — Backend (PHP + MySQL) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Hostinger-hosted PHP + MySQL REST API that stores the shop's data and serves offline-first sync (push/pull), authentication, idempotent stock movements, and image upload.

**Architecture:** Plain PHP 8 with a tiny front-controller/router and PDO (no runtime framework, so it drops onto Hostinger shared hosting as files + one `schema.sql`). All syncable rows carry a UUID `id`, a device-authored `updated_at` (ms) for last-write-wins conflict resolution, a server-assigned `server_seq` for the pull cursor, and an `is_deleted` tombstone. Stock is never pushed as an absolute value; it is derived by applying idempotent `stock_movements` (unique by UUID) and returned reconciled.

**Tech Stack:** PHP 8.1+, MySQL 8 (or 5.7+), PDO, `password_hash`/`password_verify` (bcrypt), PHPUnit (dev-only) + Guzzle or PHP streams for HTTP-level tests, PHP built-in server (`php -S`) for local test runs.

**Spec:** `docs/superpowers/specs/2026-11-09-online-sync-design.md`

## Global Constraints

- PHP **8.1+**, MySQL **8.0** (target; must also run on 5.7+). No runtime Composer dependencies — dev/test deps only.
- **All SQL via PDO prepared statements.** No string-interpolated SQL.
- All syncable IDs are **UUID v4 strings** (`CHAR(36)`). Timestamps are **milliseconds since epoch** as `BIGINT`.
- Passwords stored only as **bcrypt hashes** (`password_hash(..., PASSWORD_BCRYPT)`). Never store or log plaintext.
- API is **JSON in / JSON out**, served over **HTTPS**. Every error returns `{ "error": "<message>" }` with a correct HTTP status.
- Monetary and quantity field names/types mirror the app's existing `toMap()` keys exactly (e.g. `unit_cost`, `reorder_level`, `display_color_value`) so the Flutter client maps 1:1.
- Syncable tables: `categories`, `inventory_items`, `discounts`, `expenses`, `expense_types`, `user_accounts`, `loans`, `suppliers`, `receipts`, `purchase_orders`, `stock_adjustments`. Plus server-only tables: `auth_tokens`, `stock_movements`.

## Review Focus

- **Replayed push** — the same `stock_movements` UUID (or any row) arriving twice (client retry after a dropped response) must not double-apply. → Task 6 duplicate-movement test; Task 5 upsert idempotency test.
- **Device clock skew** — the pull cursor must be the **server-assigned `server_seq`**, never a device `updated_at`, or a device with a slow clock loses rows. → Task 4 cursor test using out-of-order `updated_at`.
- **Deactivated user** — an existing token for a user whose `is_active` became 0 must be rejected. → Task 3 deactivated-token test.
- **Delete then re-reference** — a tombstoned row that a later push updates must resurrect/stay consistent (newer `updated_at` wins over the tombstone). → Task 5 tombstone-vs-newer-update test.
- **Bad image upload** — oversized or non-image upload must be rejected with a 4xx, not stored or fatal. → Task 7 invalid-upload test.

---

## Task 1: Project scaffold, config, DB connection, router, health check

**Files:**
- Create: `server/public/index.php` (front controller), `server/public/.htaccess` (route all to index, force HTTPS)
- Create: `server/src/Db.php` (PDO factory), `server/src/Router.php`, `server/src/Json.php` (request/response helpers)
- Create: `server/config.sample.php` (DB creds template; real `server/config.php` is git-ignored)
- Create: `server/.gitignore` (`config.php`, `uploads/`, `vendor/`)
- Create: `server/composer.json` (dev-only: phpunit), `server/tests/bootstrap.php`
- Test: `server/tests/HealthTest.php`

**Interfaces:**
- Produces: `Db::pdo(): PDO`; `Router::add(string $method, string $path, callable $handler)` and `Router::dispatch(string $method, string $uri): void`; `Json::body(): array`, `Json::send(array $data, int $status = 200): void`, `Json::error(string $msg, int $status): void`. Route path params use `{name}` and are passed to the handler as an assoc array.

- [ ] **Step 1: Write the failing test** — `server/tests/HealthTest.php::test_health_returns_ok`: boots the app (include front controller with `GET /health`), asserts HTTP 200 and JSON body `{"status":"ok"}`.
- [ ] **Step 2: Run test to verify it fails** — Run: `cd server && vendor/bin/phpunit tests/HealthTest.php`. Expected: FAIL (class/route missing).
- [ ] **Step 3: Implement** `Db`, `Json`, `Router`, and `index.php` registering `GET /health` → `Json::send(['status' => 'ok'])`. `.htaccess` rewrites all non-file requests to `index.php` and redirects http→https. `config.sample.php` defines `DB_HOST/DB_NAME/DB_USER/DB_PASS`.
- [ ] **Step 4: Run test to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(server): scaffold router, db, config, health check`.

## Task 2: Database schema

**Files:**
- Create: `server/schema.sql` (all tables)
- Create: `server/src/Schema.php` (test helper that applies `schema.sql` to the test DB)
- Test: `server/tests/SchemaTest.php`

**Interfaces:**
- Produces: the canonical column set per table. Every syncable table has: `id CHAR(36) PRIMARY KEY`, entity columns (mirroring the app's `toMap()` keys), `updated_at BIGINT NOT NULL`, `is_deleted TINYINT(1) NOT NULL DEFAULT 0`, `server_seq BIGINT NOT NULL` (indexed). `stock_movements`: `id CHAR(36) PK`, `inventory_item_id CHAR(36)`, `variant_name VARCHAR(190) DEFAULT ''`, `delta INT NOT NULL`, `source_type VARCHAR(20)`, `source_id CHAR(36)`, `created_at BIGINT`, `updated_at BIGINT`, `is_deleted TINYINT(1)`, `server_seq BIGINT`. `auth_tokens`: `token CHAR(64) PK`, `user_id CHAR(36)`, `created_at BIGINT`. A single `server_sequence` mechanism (an `AUTO_INCREMENT` counter table or `BIGINT AUTO_INCREMENT` column semantics) issues the monotonic `server_seq`.

- [ ] **Step 1: Write the failing test** — `SchemaTest.php::test_all_tables_exist`: applies `schema.sql` to the test DB, then asserts every table in the Global Constraints list plus `auth_tokens` and `stock_movements` exists, and that `inventory_items` has columns `id, name, category, stock, reorder_level, unit_cost, price, variant, variants, sku, representation, display_color_value, display_shape, image_path, image_url, updated_at, is_deleted, server_seq`.
- [ ] **Step 2: Run test to verify it fails** — Expected: FAIL (no schema).
- [ ] **Step 3: Implement** `schema.sql` creating every table with the columns above (quantity/money types matching the app: `stock INT`, `unit_cost DECIMAL(12,2)`, etc.), plus indexes on `server_seq` per table. `Schema::applyTo(PDO)` reads and executes the file.
- [ ] **Step 4: Run test to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(server): add MySQL schema with sync metadata`.

## Task 3: Authentication (login, tokens, auth middleware, logout)

**Files:**
- Create: `server/src/Auth.php`, `server/src/handlers/AuthHandlers.php`
- Modify: `server/public/index.php` (register `POST /auth/login`, `POST /auth/logout`)
- Test: `server/tests/AuthTest.php`

**Interfaces:**
- Produces: `Auth::hash(string $pw): string`; `Auth::issueToken(PDO, string $userId): string` (64-char random, stored in `auth_tokens`); `Auth::userForToken(PDO, string $token): ?array` (null if missing or user `is_active=0`); handler `POST /auth/login {username,password}` → `{ token, user }` (user map without `password`), 401 on bad creds; `POST /auth/logout` (Bearer token) deletes the token. `Auth::requireUser(PDO): array` reads the `Authorization: Bearer` header and 401s if invalid — reused by Task 5.

- [ ] **Step 1: Write the failing tests** — `AuthTest.php`: `test_login_success_returns_token_and_user` (seed one user via `Auth::hash`), `test_login_wrong_password_401`, `test_login_unknown_user_401`, `test_token_for_deactivated_user_rejected` (set `is_active=0`, `userForToken` returns null), `test_login_response_omits_password`.
- [ ] **Step 2: Run tests to verify they fail** — Expected: FAIL.
- [ ] **Step 3: Implement** `Auth` and `AuthHandlers` per the Interfaces. Verify with `password_verify`. Token = `bin2hex(random_bytes(32))`.
- [ ] **Step 4: Run tests to verify they pass** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(server): bcrypt auth with bearer tokens`.

## Task 4: Sync pull (`GET /sync?since=<server_seq>`)

**Files:**
- Create: `server/src/Sync.php` (shared table registry + row serialization), `server/src/handlers/SyncHandlers.php`
- Modify: `server/public/index.php` (register `GET /sync`)
- Test: `server/tests/SyncPullTest.php`

**Interfaces:**
- Produces: `Sync::SYNC_TABLES` (ordered list honoring FK dependencies); `Sync::changesSince(PDO, int $since): array` → `['cursor' => <maxServerSeq>, 'changes' => ['inventory_items' => [rows...], ...], 'stock' => ['<itemId>' => <qty>, ...]]`; handler `GET /sync?since=N` (auth required) returning that shape. Rows include tombstoned rows (so deletes propagate). `since=0` returns everything. **`user_accounts` rows include the bcrypt `password` hash** — devices need it for offline login (per spec §6.5); this is deliberate and differs from `/auth/login`, which omits `password`.

- [ ] **Step 1: Write the failing tests** — `SyncPullTest.php`: `test_since_zero_returns_all_rows`; `test_returns_only_rows_after_cursor` (insert rows with increasing `server_seq`, pull `since=lastSeen`, assert only newer returned); `test_includes_tombstones`; `test_cursor_is_max_server_seq_not_updated_at` (insert a row whose `updated_at` is far in the past but `server_seq` newest; assert it IS returned for a `since` below that seq).
- [ ] **Step 2: Run tests to verify they fail** — Expected: FAIL.
- [ ] **Step 3: Implement** `Sync::changesSince` querying each table `WHERE server_seq > :since ORDER BY server_seq` and the per-item reconciled stock (`SELECT inventory_item_id, SUM(delta) FROM stock_movements WHERE is_deleted=0 GROUP BY inventory_item_id`). Handler wires auth + query params.
- [ ] **Step 4: Run tests to verify they pass** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(server): sync pull with server-seq cursor`.

## Task 5: Sync push (`POST /sync`) with last-write-wins upsert

**Files:**
- Modify: `server/src/Sync.php` (add `applyChanges`), `server/src/handlers/SyncHandlers.php` (handle `POST /sync`)
- Modify: `server/public/index.php` (register `POST /sync`)
- Test: `server/tests/SyncPushTest.php`

**Interfaces:**
- Consumes: `Auth::requireUser` (Task 3), `Sync::changesSince` (Task 4).
- Produces: `Sync::applyChanges(PDO, array $changes): void` — per row, upsert by `id`; assign a fresh `server_seq`; **keep the incoming row only if its `updated_at` >= the stored `updated_at`** (older updates ignored), tombstone when `is_deleted=1`. Handler `POST /sync {last_sync_at, changes, movements}` runs in one transaction: `applyChanges`, then return `changesSince(last_sync_at)` plus `server_time`. The response is the same shape as Task 4 so one round-trip does push+pull. (The `movements` field is accepted but applied in Task 6, which adds `Stock::applyMovements` to this same handler.)

- [ ] **Step 1: Write the failing tests** — `SyncPushTest.php`: `test_new_row_inserted_and_gets_server_seq`; `test_older_update_is_ignored` (push row with `updated_at` < stored; stored value unchanged); `test_newer_update_wins`; `test_delete_tombstone_applied`; `test_tombstone_then_newer_update_resurrects` (Review Focus); `test_push_then_pull_roundtrip_returns_other_devices_changes`.
- [ ] **Step 2: Run tests to verify they fail** — Expected: FAIL.
- [ ] **Step 3: Implement** `applyChanges` (prepared upsert per table, LWW guard on `updated_at`) and the transactional `POST /sync` handler.
- [ ] **Step 4: Run tests to verify they pass** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(server): sync push with last-write-wins upsert`.

## Task 6: Stock movements (idempotent apply + reconciliation)

**Files:**
- Create: `server/src/Stock.php`
- Modify: `server/src/handlers/SyncHandlers.php` (call `Stock::applyMovements` inside the `POST /sync` transaction)
- Test: `server/tests/StockTest.php`

**Interfaces:**
- Produces: `Stock::applyMovements(PDO, array $movements): void` — insert each movement **only if its `id` is not already present** (idempotent); recompute and cache `inventory_items.stock = COALESCE(SUM(delta),0)` for each affected item. Movement shape: `{id, inventory_item_id, variant_name, delta, source_type, source_id, created_at, updated_at, is_deleted}`.

- [ ] **Step 1: Write the failing tests** — `StockTest.php`: `test_single_movement_sets_stock`; `test_duplicate_movement_id_ignored` (apply same id twice → stock counts it once) (Review Focus); `test_two_concurrent_decrements_sum` (two movements of delta -3 and -2 from two "devices" → stock drops by 5, neither overwrites); `test_deleted_movement_excluded_from_sum`.
- [ ] **Step 2: Run tests to verify they fail** — Expected: FAIL.
- [ ] **Step 3: Implement** `Stock::applyMovements` using `INSERT ... ON DUPLICATE KEY UPDATE` (no-op on existing id) then a grouped recompute of affected items' `stock`.
- [ ] **Step 4: Run tests to verify they pass** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(server): idempotent stock movements and reconciliation`.

## Task 7: Image upload

**Files:**
- Create: `server/src/handlers/ImageHandlers.php`
- Modify: `server/public/index.php` (register `POST /images`), `server/public/.htaccess` (serve `/uploads/*` statically)
- Test: `server/tests/ImageTest.php`

**Interfaces:**
- Produces: `POST /images` (auth, `multipart/form-data` file field `image`) → `{ url }` pointing at `/uploads/<uuid>.<ext>`; rejects files that are not `image/png|jpeg|webp` or exceed a size cap (e.g. 5 MB) with HTTP 400/413. Uploaded file saved under `server/public/uploads/`.

- [ ] **Step 1: Write the failing tests** — `ImageTest.php`: `test_valid_png_upload_returns_url_and_file_exists`; `test_non_image_rejected_400` (Review Focus); `test_oversize_rejected`.
- [ ] **Step 2: Run tests to verify they fail** — Expected: FAIL.
- [ ] **Step 3: Implement** `ImageHandlers` validating MIME (via `finfo`) and size, writing to `uploads/`, returning the URL.
- [ ] **Step 4: Run tests to verify they pass** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(server): authenticated image upload`.

## Task 8: Deployment runbook + seed admin

**Files:**
- Create: `server/README.md` (Hostinger deploy runbook), `server/seed_admin.php` (CLI: create the first Super Admin with a hashed password)
- Test: `server/tests/SeedAdminTest.php`

**Interfaces:**
- Produces: `seed_admin.php --username= --password= --name=` inserts one `super_admin` user with a bcrypt hash and a UUID id; idempotent on username.

- [ ] **Step 1: Write the failing test** — `SeedAdminTest.php::test_seed_creates_hashed_super_admin`: runs the seed function, asserts a user row exists with `role='super_admin'`, `is_active=1`, and `password_verify(plain, stored)` is true.
- [ ] **Step 2: Run test to verify it fails** — Expected: FAIL.
- [ ] **Step 3: Implement** the seed function/CLI and write `README.md` covering: create MySQL DB + user in hPanel, upload `server/` to `public_html/api` (document root → `server/public`) or an `api.` subdomain, import `schema.sql` via phpMyAdmin, copy `config.sample.php`→`config.php` with creds, enable SSL, run `seed_admin.php` once, verify `GET /health`.
- [ ] **Step 4: Run test to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(server): admin seed script and deploy runbook`.

---

## Notes carried to the app-side plans (Stage 2/3)

- **API contract** the app must speak: `POST /auth/login`, `POST /auth/logout`, `GET /sync?since=`, `POST /sync {last_sync_at, changes, movements}`, `POST /images`. Pull cursor is the returned `cursor` (server_seq). Row JSON keys match the app's `toMap()` keys plus `updated_at`, `is_deleted`.
- **Stock is movement-driven:** the app must emit a `stock_movements` row (with its own UUID) for every sale line, stock adjustment, approved PO line, and manual stock edit (delta vs previous), and must NOT treat `inventory_items.stock` it pushes as authoritative — it reads reconciled stock back from the sync response.
- **Known v1 limitation:** variant-level stock (`variants` JSON) is synced last-write-wins; only item-level `stock` is movement-reconciled. Flagged for a later iteration if concurrent variant edits prove to be a problem.
