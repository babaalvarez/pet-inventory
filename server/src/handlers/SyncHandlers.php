<?php
declare(strict_types=1);

require_once __DIR__ . '/../Auth.php';
require_once __DIR__ . '/../Db.php';
require_once __DIR__ . '/../Sync.php';
require_once __DIR__ . '/../Stock.php';

final class SyncHandlers
{
    public static function pull(array $params): void
    {
        $pdo = Db::pdo();
        Auth::requireUser($pdo);
        $since = max(0, (int) ($_GET['since'] ?? 0));
        Json::send(Sync::changesSince($pdo, $since));
    }

    /**
     * POST /sync — apply a client push, then return the same shape as pull so one
     * round trip does push+pull. Body: { last_sync_at, changes, movements }.
     * `movements` are applied idempotently via Stock::applyMovements.
     */
    public static function push(array $params): void
    {
        $pdo = Db::pdo();
        Auth::requireUser($pdo);
        $body = Json::body();
        $lastSyncAt = max(0, (int) ($body['last_sync_at'] ?? 0));
        $changes = is_array($body['changes'] ?? null) ? $body['changes'] : [];

        $pdo->beginTransaction();
        try {
            Sync::applyChanges($pdo, $changes);
            // After applyChanges so movement-derived stock overrides any pushed absolute stock.
            $movements = is_array($body['movements'] ?? null) ? $body['movements'] : [];
            Stock::applyMovements($pdo, $movements);
            $pdo->commit();
        } catch (Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        Json::send(
            Sync::changesSince($pdo, $lastSyncAt)
            + ['server_time' => (int) round(microtime(true) * 1000)]
        );
    }
}
