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

    /** Tables with a UNIQUE business key besides the primary key: table => column. */
    private const UNIQUE_COLUMNS = [
        'user_accounts' => 'username',
        'expense_types' => 'name',
    ];

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

    /**
     * @return array{cursor:int, changes:array<string,array>, stock:object}  stock is an object so empty encodes as {} (map itemId => int qty)
     *
     * All reads run inside ONE read transaction so every per-table SELECT and the stock SUM
     * share a single committed snapshot. InnoDB's default REPEATABLE READ fixes that snapshot
     * at the first SELECT, so a push committing midway cannot be seen partially and the cursor
     * (max server_seq) can never advance past a row that wasn't returned (which would lose it
     * permanently). Pushes serialize on the server_sequence counter row, so a consistent snapshot
     * always sees a contiguous seq prefix. Always called OUTSIDE an active transaction (pull: none;
     * push: after commit), so this never nests.
     */
    public static function changesSince(PDO $db, int $since): array
    {
        $db->beginTransaction();
        try {
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

            $db->commit();
            return ['cursor' => $cursor, 'changes' => $changes, 'stock' => (object) $stock];
        } catch (Throwable $e) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            throw $e;
        }
    }

    /**
     * Atomically advance the shared server_seq counter and return the new value.
     * Every insert AND update pulls its server_seq from here (not column AUTO_INCREMENT,
     * which would not advance on UPDATE and would make pull miss edits).
     */
    public static function nextSeq(PDO $db): int
    {
        $db->exec('UPDATE server_sequence SET seq = LAST_INSERT_ID(seq + 1)');
        return (int) $db->lastInsertId();
    }

    /**
     * Apply a client push: last-write-wins upsert keyed strictly by `id`, per table.
     * Unknown tables and unknown columns are silently dropped (defensive). Each write
     * assigns a fresh server_seq from the counter.
     *
     * Each row's write is isolated in a SAVEPOINT so a single bad row (e.g. one omitting a
     * NOT-NULL-no-default column) is SKIPPED rather than aborting the whole POST /sync
     * transaction — sibling rows and the push's movements still apply. This matches the
     * "skip, don't abort" policy already used for unique-key collisions. A plain try/catch is
     * not enough: the SAVEPOINT rolls back only the failed row and leaves the outer transaction
     * intact and usable. Returns the number of rows skipped on write failure (0 = all applied).
     *
     * @param array<string, mixed> $changes table => list of row maps
     */
    public static function applyChanges(PDO $db, array $changes): int
    {
        $inTx = $db->inTransaction();
        $skipped = 0;

        foreach ($changes as $table => $rows) {
            if (!in_array($table, self::SYNC_TABLES, true) || !is_array($rows)) {
                continue; // never trust a table name from input
            }
            $types = self::columnTypes($db, $table);                       // column => type (the whitelist)
            $jsonCols = array_intersect(self::JSON_ARRAY_COLUMNS, array_keys($types));

            foreach ($rows as $row) {
                if (!is_array($row)) {
                    continue;
                }
                // Keep only columns that actually exist in this table.
                $data = array_intersect_key($row, $types);
                $id = isset($data['id']) ? (string) $data['id'] : '';
                if ($id === '') {
                    continue; // cannot upsert without a primary key
                }
                // JSON-blob columns are never NULL: coalesce null/missing to '[]'.
                foreach ($jsonCols as $col) {
                    if (!isset($data[$col])) {
                        $data[$col] = '[]';
                    }
                }
                // The counter owns server_seq; discard whatever the client sent.
                unset($data['server_seq']);

                // Isolate this row's write: a failure rolls back ONLY this row (SAVEPOINT),
                // never the batch. Deliberate skips (stale write / unique collision) return
                // normally and release the savepoint with nothing to undo.
                if ($inTx) {
                    $db->exec('SAVEPOINT sync_row');
                }
                try {
                    self::applyRow($db, $table, $data);
                    if ($inTx) {
                        $db->exec('RELEASE SAVEPOINT sync_row');
                    }
                } catch (Throwable $e) {
                    if ($inTx) {
                        $db->exec('ROLLBACK TO SAVEPOINT sync_row');
                        $db->exec('RELEASE SAVEPOINT sync_row');
                    }
                    $skipped++; // bad row dropped; sibling rows and movements survive
                }
            }
        }

        return $skipped;
    }

    /** Upsert one already-filtered row (id present). last-write-wins; throws on a DB write error. */
    private static function applyRow(PDO $db, string $table, array $data): void
    {
        $id = (string) $data['id'];
        $incomingUpdatedAt = (int) ($data['updated_at'] ?? 0);

        $sel = $db->prepare("SELECT updated_at FROM `$table` WHERE id = ?");
        $sel->execute([$id]);
        $stored = $sel->fetch(PDO::FETCH_NUM);

        if ($stored !== false) {
            // Existing row: last-write-wins (ties go to the incoming write).
            if ($incomingUpdatedAt < (int) $stored[0]) {
                return;
            }
            // A rename can collide on the UNIQUE key with a DIFFERENT row; resolve it
            // the same way as INSERT so one conflicting row can't 500 the whole batch.
            if (!self::resolveUnique($db, $table, $data)) {
                return;
            }
            self::writeRow($db, $table, $data, true);
            return;
        }

        // New id. Resolve a UNIQUE business-key collision before inserting.
        if (!self::resolveUnique($db, $table, $data)) {
            return; // an active row owns the key: drop this incoming row
        }
        self::writeRow($db, $table, $data, false);
    }

    /**
     * Resolve a UNIQUE business-key collision (username/name) before writing $data under its id.
     * A colliding row with a DIFFERENT id that is a tombstone (is_deleted=1) is freed so the write
     * succeeds; an active different-id row owns the key, so the write is skipped. Returns true when
     * the caller may proceed, false when this row must be skipped. No-op (true) for tables without a
     * unique business key or rows that omit it.
     */
    private static function resolveUnique(PDO $db, string $table, array $data): bool
    {
        $uniqueCol = self::UNIQUE_COLUMNS[$table] ?? null;
        if ($uniqueCol === null || !isset($data[$uniqueCol])) {
            return true;
        }
        $clash = $db->prepare("SELECT id, is_deleted FROM `$table` WHERE `$uniqueCol` = ? AND id <> ?");
        $clash->execute([(string) $data[$uniqueCol], (string) $data['id']]);
        $other = $clash->fetch(PDO::FETCH_NUM);
        if ($other === false) {
            return true; // no different-id row holds this value
        }
        if ((int) $other[1] === 1) {
            // Free the tombstone so the name/username can be (re-)used. NOTE: this hard-DELETE
            // drops the tombstone row, so its delete-signal is no longer re-delivered on pull;
            // other devices still holding that id learn of the deletion only if they already saw it.
            $db->prepare("DELETE FROM `$table` WHERE id = ?")->execute([(string) $other[0]]);
            return true;
        }
        return false; // an active different-id row owns the key
    }

    /** INSERT or UPDATE $data (already column-filtered, id present) with a fresh server_seq. */
    private static function writeRow(PDO $db, string $table, array $data, bool $update): void
    {
        $seq = self::nextSeq($db);
        if ($update) {
            $set = [];
            $vals = [];
            foreach ($data as $col => $val) {
                if ($col === 'id') {
                    continue; // the primary key is the match target, never reassigned
                }
                $set[] = "`$col` = ?";
                $vals[] = $val;
            }
            $set[] = 'server_seq = ?';
            $vals[] = $seq;
            $vals[] = (string) $data['id'];
            $sql = "UPDATE `$table` SET " . implode(', ', $set) . ' WHERE id = ?';
            $db->prepare($sql)->execute($vals);
            return;
        }
        $data['server_seq'] = $seq;
        $cols = array_keys($data);
        $colList = implode(', ', array_map(static fn (string $c): string => "`$c`", $cols));
        $place = implode(', ', array_fill(0, count($cols), '?'));
        $db->prepare("INSERT INTO `$table` ($colList) VALUES ($place)")->execute(array_values($data));
    }
}
