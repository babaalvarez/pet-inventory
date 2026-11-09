# Petsupplies Sync Server - Hostinger Deploy Runbook

PHP 8.1+ REST API backed by MySQL. The mobile app talks to it at `https://api.<your-domain>` (a dedicated subdomain).

## 1. Create the MySQL database (hPanel)

1. hPanel -> Databases -> MySQL Databases.
2. Create a database and a user (Hostinger prefixes both, e.g. `u123_sync`). Choose a strong password.
3. Make sure the user is assigned to the database with **All Privileges**.
4. Note the host (usually `localhost`), database name, user and password.

## 2. Upload the files

Upload the whole `server/` folder (File Manager or FTP). Skip `vendor/`, `tests/` and `.phpunit.cache/`; production does not need them.

The web root must be `server/public`, served from a subdomain:

1. hPanel -> Domains -> Subdomains: create `api.<domain>`.
2. Set that subdomain's document root (custom folder) to the uploaded `.../server/public` folder.
3. The app base URL is then `https://api.<domain>`.

A `/api` subfolder under the main domain is NOT supported: the router matches the raw path (`/health`, `/auth/login`, ...) with no base-path handling.

Keep `config.php`, `src/`, `schema.sql` and `seed_admin.php` outside the public web root.

## 3. Import the schema

hPanel -> Databases -> phpMyAdmin -> select your database -> Import -> choose `server/schema.sql` -> Go.

## 4. Configure credentials

Copy `config.sample.php` to `config.php` (same folder) and fill in `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`. Never commit `config.php`; it is git-ignored.

## 5. HTTPS

hPanel -> Security -> SSL: install the free SSL for the domain/subdomain and enable "Force HTTPS". `public/.htaccess` also redirects http to https. If the server sits behind a TLS-terminating proxy, PHP/Apache may see every request as plain http and the redirect would loop; in that case change the rewrite condition to test the `X-Forwarded-Proto` header (`RewriteCond %{HTTP:X-Forwarded-Proto} !https`) instead of `%{HTTPS} off`.

## 6. Uploads folder

Ensure `public/uploads/` exists and is writable by the web user (permissions 755, or 775 if uploads fail). Its `.htaccess` (committed) disables PHP execution there; do not delete it.

## 7. Create the first Super Admin

From SSH (hPanel -> Advanced -> SSH Access), in the `server/` folder:

```
php seed_admin.php --username=admin --password='A-strong-password' --name='Owner'
```

Running it again with the same username resets that account's password and re-activates it (no duplicates). The account then syncs down to every device.

## 8. Verify

```
curl https://api.<domain>/health        # -> {"status":"ok"}
curl -X POST https://api.<domain>/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"A-strong-password"}'
```

A successful login returns a token.

## Endpoints used by the app

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/auth/login` | Log in, receive a token |
| POST | `/auth/logout` | Invalidate the token |
| GET | `/sync?since=<seq>` | Pull changes with `server_seq` greater than `since` |
| POST | `/sync` | Push local changes (last-write-wins) |
| POST | `/images` | Authenticated image upload |

All endpoints except `/health` and `/auth/login` require the bearer token.

## Local development

`composer install`, then `vendor/bin/phpunit` (tests expect MySQL at 127.0.0.1:3310, db `petsupplies_sync_test`; override via `DB_*` env vars).
