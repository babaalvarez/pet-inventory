<?php
declare(strict_types=1);

require_once __DIR__ . '/../Auth.php';
require_once __DIR__ . '/../Db.php';
require_once __DIR__ . '/../Sync.php';

final class SyncHandlers
{
    public static function pull(array $params): void
    {
        $pdo = Db::pdo();
        Auth::requireUser($pdo);
        $since = max(0, (int) ($_GET['since'] ?? 0));
        Json::send(Sync::changesSince($pdo, $since));
    }
}
