<?php
declare(strict_types=1);

/**
 * Create (or reset) the first Super Admin. Idempotent on username.
 * CLI: php seed_admin.php --username=admin --password=secret --name="Owner"
 */

require_once __DIR__ . '/src/Db.php';
require_once __DIR__ . '/src/Auth.php';
require_once __DIR__ . '/src/Sync.php';

function seedAdmin(PDO $db, string $username, string $password, string $name): void
{
    $now = (int) round(microtime(true) * 1000);
    $hash = Auth::hash($password);
    // A real server_seq is required: pull with since=0 returns only server_seq > 0.
    $seq = Sync::nextSeq($db);

    $st = $db->prepare('SELECT id FROM user_accounts WHERE username = ?');
    $st->execute([$username]);
    $id = $st->fetchColumn();

    if ($id !== false) {
        $db->prepare(
            "UPDATE user_accounts SET password = ?, display_name = ?, role = 'super_admin',
             is_active = 1, is_deleted = 0, updated_at = ?, server_seq = ? WHERE id = ?"
        )->execute([$hash, $name, $now, $seq, $id]);
        return;
    }
    $db->prepare(
        "INSERT INTO user_accounts (id, username, password, display_name, role, is_active, is_deleted, updated_at, server_seq)
         VALUES (?, ?, ?, ?, 'super_admin', 1, 0, ?, ?)"
    )->execute([Auth::uuid4(), $username, $hash, $name, $now, $seq]);
}

if (PHP_SAPI === 'cli' && isset($argv[0]) && realpath($argv[0]) === __FILE__) {
    $opts = getopt('', ['username:', 'password:', 'name:']);
    if (empty($opts['username']) || empty($opts['password']) || empty($opts['name'])) {
        fwrite(STDERR, "Usage: php seed_admin.php --username=... --password=... --name=...\n");
        exit(1);
    }
    require_once __DIR__ . '/config.php';
    seedAdmin(Db::pdo(), (string) $opts['username'], (string) $opts['password'], (string) $opts['name']);
    echo "Super Admin '{$opts['username']}' is ready.\n";
}
