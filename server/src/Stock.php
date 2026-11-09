<?php
declare(strict_types=1);

require_once __DIR__ . '/Sync.php';

final class Stock
{
    /**
     * Apply stock movements idempotently by `id` (a retried push never double-counts),
     * then recompute the reconciled inventory_items.stock for each affected item as
     * SUM(delta) over non-deleted movements. Movements are additive, so concurrent
     * offline decrements from several devices all count.
     */
    public static function applyMovements(PDO $db, array $movements): void
    {
        $affected = [];
        $exists = $db->prepare('SELECT 1 FROM stock_movements WHERE id = ?');

        foreach ($movements as $m) {
            if (!is_array($m)) {
                continue;
            }
            $id = $m['id'] ?? null;
            $itemId = $m['inventory_item_id'] ?? null;
            if (!is_string($id) || $id === '' || !is_string($itemId) || $itemId === '') {
                continue;
            }
            $affected[$itemId] = true;

            $exists->execute([$id]);
            if ($exists->fetchColumn() !== false) {
                continue; // already applied: no-op
            }

            $now = (int) round(microtime(true) * 1000);
            $row = [
                'id' => $id,
                'inventory_item_id' => $itemId,
                'variant_name' => (string) ($m['variant_name'] ?? ''),
                'delta' => (int) ($m['delta'] ?? 0),
                'source_type' => (string) ($m['source_type'] ?? ''),
                'source_id' => (string) ($m['source_id'] ?? ''),
                'created_at' => (int) ($m['created_at'] ?? $now),
                'updated_at' => (int) ($m['updated_at'] ?? $now),
                'is_deleted' => (int) ($m['is_deleted'] ?? 0),
                'server_seq' => Sync::nextSeq($db),
            ];

            $cols = array_keys($row);
            $sql = 'INSERT INTO stock_movements (`' . implode('`,`', $cols) . '`) VALUES ('
                . implode(',', array_fill(0, count($cols), '?')) . ') ON DUPLICATE KEY UPDATE id = id';
            $db->prepare($sql)->execute(array_values($row));
        }

        $recompute = $db->prepare(
            'UPDATE inventory_items SET stock = (SELECT COALESCE(SUM(delta),0) FROM stock_movements
             WHERE inventory_item_id = ? AND is_deleted = 0) WHERE id = ?'
        );
        foreach (array_keys($affected) as $itemId) {
            $recompute->execute([$itemId, $itemId]);
        }
    }
}
