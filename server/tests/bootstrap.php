<?php
declare(strict_types=1);

require_once __DIR__ . '/../vendor/autoload.php';

$env = static fn (string $k, string $d): string => getenv($k) !== false ? (string) getenv($k) : $d;

define('DB_HOST', $env('DB_HOST', '127.0.0.1'));
define('DB_PORT', (int) $env('DB_PORT', '3310'));
define('DB_NAME', $env('DB_NAME', 'petsupplies_sync_test'));
define('DB_USER', $env('DB_USER', 'root'));
define('DB_PASS', $env('DB_PASS', ''));

require_once __DIR__ . '/../src/Json.php';
require_once __DIR__ . '/../src/Router.php';
require_once __DIR__ . '/../src/Db.php';
require_once __DIR__ . '/../src/Schema.php';
require_once __DIR__ . '/DbTestCase.php';
require_once __DIR__ . '/../src/Auth.php';
