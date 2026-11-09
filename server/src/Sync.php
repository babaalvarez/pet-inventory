<?php
declare(strict_types=1);

/** Shared sync logic: table registry, typed row serialization, change queries. */
final class Sync
{
    /** Syncable tables, parents first where it matters. Fixed whitelist: never built from input. */
    public const SYNC_TABLES = [
        'categories', 'suppliers', 'expense_types', 'discounts', 'inventory_items',
        'loans', 'expenses', 'user_accounts', 'receipts', 'purchase_orders', 'stock_adjustments',
    ];

    /** LONGTEXT JSON-array columns: NULL becomes '[]'. */
    private const JSON_ARRAY_COLUMNS = ['variants', 'purchased_items', 'line_items'];

    /** @var array<string, array<string, string>> table => column => DATA_TYPE */
    private static array $columnTypes = [];

    /** @return array<string, string> column => lowercase DATA_TYPE */
    public static function columnTypes(PDO $db, string $table): array
    {
        if (!isset(self::$columnTypes[$table])) {
            $st = $db->prepare(
                'SELECT COLUMN_NAME, DATA_TYPE FROM information_schema.columns
                 WHERE table_schema = DATABASE() AND table_name = ?'
            );
            $st->execute([$table]);
            $map = [];
            foreach ($st->fetchAll(PDO::FETCH_NUM) as [$name, $type]) {
                $map[(string) $name] = strtolower((string) $type);
            }
            self::$columnTypes[$table] = $map;
        }
        return self::$columnTypes[$table];
    }

    /** Casts a raw PDO row to correct JSON types by column type. Reused by push responses. */
    public static function serializeRow(PDO $db, string $table, array $row): array
    {
        $types = self::columnTypes($db, $table);
        $out = [];
        foreach ($row as $col => $val) {
            $type = $types[$col] ?? 'varchar';
            if ($val === null) {
                $out[$col] = in_array($col, self::JSON_ARRAY_COLUMNS, true) ? '[]' : null;
            } elseif (in_array($type, ['int', 'bigint', 'tinyint', 'smallint', 'mediumint'], true)) {
                $out[$col] = (int) $val;
            } elseif (in_array($type, ['decimal', 'float', 'double'], true)) {
                $out[$col] = (float) $val;
            } else {
                $out[$col] = (string) $val;
            }
        }
        return $out;
    }

    /** @return array{cursor:int, changes:array<string,array>, stock:object}  stock is an object so empty encodes as {} (map itemId => int qty) */
    public static function changesSince(PDO $db, int $since): array
    {
        $cursor = $since;
        $changes = [];
        foreach (self::SYNC_TABLES as $table) {
            $st = $db->prepare("SELECT * FROM `$table` WHERE server_seq > :since ORDER BY server_seq");
            $st->bindValue(':since', $since, PDO::PARAM_INT);
            $st->execute();
            $rows = [];
            foreach ($st->fetchAll(PDO::FETCH_ASSOC) as $raw) {
                $row = self::serializeRow($db, $table, $raw);
                $cursor = max($cursor, $row['server_seq']);
                $rows[] = $row;
            }
            $changes[$table] = $rows;
        }

        $stock = [];
        $st = $db->query(
            'SELECT inventory_item_id, SUM(delta) AS qty FROM stock_movements WHERE is_deleted = 0 GROUP BY inventory_item_id'
        );
        foreach ($st->fetchAll(PDO::FETCH_NUM) as [$itemId, $qty]) {
            $stock[(string) $itemId] = (int) $qty;
        }

        return ['cursor' => $cursor, 'changes' => $changes, 'stock' => (object) $stock];
    }
}
