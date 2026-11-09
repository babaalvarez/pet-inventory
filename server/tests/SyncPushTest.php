<?php
declare(strict_types=1);

final class SyncPushTest extends DbTestCase
{
    private const USER_ID = '11111111-1111-4111-8111-111111111111';

    protected function setUp(): void
    {
        parent::setUp();
        // Auth user with a fixed server_seq, leaving the shared counter at 0 so
        // server_seq values assigned during a push are predictable (1, 2, ...).
        Db::pdo()->prepare(
            'INSERT INTO user_accounts (id, username, password, display_name, role, is_active, updated_at, is_deleted, server_seq)
             VALUES (?,?,?,?,?,1,1,0,1000)'
        )->execute([self::USER_ID, 'admin', Auth::hash('secret'), 'Admin', 'admin']);
        $token = Auth::issueToken(Db::pdo(), self::USER_ID);
        Router::reset();
        require __DIR__ . '/../src/routes.php';
        Auth::$authHeader = 'Bearer ' . $token;
    }

    protected function tearDown(): void
    {
        Json::$input = null;
        Auth::$authHeader = null;
        $_GET = [];
        parent::tearDown();
    }

    /** POST /sync with the given push body; returns [status, decodedResponse]. */
    private function push(array $changes, int $lastSyncAt = 0, array $movements = []): array
    {
        Json::$input = json_encode([
            'last_sync_at' => $lastSyncAt,
            'changes' => $changes,
            'movements' => $movements,
        ]);
        ob_start();
        Router::dispatch('POST', '/sync');
        return [http_response_code(), json_decode((string) ob_get_clean(), true)];
    }

    /** One category change row (server_seq is whatever the client sent; the server overrides it). */
    private function catRow(string $id, string $name, int $updatedAt, int $deleted = 0, int $serverSeq = 0): array
    {
        return [
            'id' => $id,
            'name' => $name,
            'color_value' => 255,
            'is_protected' => 0,
            'updated_at' => $updatedAt,
            'is_deleted' => $deleted,
            'server_seq' => $serverSeq,
        ];
    }

    private function expenseTypeRow(string $id, string $name, int $updatedAt, int $deleted = 0): array
    {
        return [
            'id' => $id,
            'name' => $name,
            'updated_at' => $updatedAt,
            'is_deleted' => $deleted,
            'server_seq' => 0,
        ];
    }

    private function storedRow(string $table, string $id): ?array
    {
        $st = Db::pdo()->prepare("SELECT * FROM `$table` WHERE id = ?");
        $st->execute([$id]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }

    public function test_new_row_inserted_and_gets_server_seq(): void
    {
        [$status] = $this->push(['categories' => [$this->catRow('c1', 'Food', 10, 0, 999)]]);
        $this->assertSame(200, $status);
        $row = $this->storedRow('categories', 'c1');
        $this->assertNotNull($row);
        $this->assertSame('Food', $row['name']);
        // server_seq comes from the counter (first nextSeq => 1), never the client's 999.
        $this->assertSame(1, (int) $row['server_seq']);
    }

    public function test_older_update_is_ignored(): void
    {
        $this->push(['categories' => [$this->catRow('c1', 'New', 100)]]);
        $this->push(['categories' => [$this->catRow('c1', 'Stale', 50)]]);
        $row = $this->storedRow('categories', 'c1');
        $this->assertSame('New', $row['name']);
        $this->assertSame(100, (int) $row['updated_at']);
    }

    public function test_newer_update_wins(): void
    {
        $this->push(['categories' => [$this->catRow('c1', 'Old', 100)]]);
        $this->push(['categories' => [$this->catRow('c1', 'Fresh', 200)]]);
        $row = $this->storedRow('categories', 'c1');
        $this->assertSame('Fresh', $row['name']);
        $this->assertSame(200, (int) $row['updated_at']);
        // server_seq advances on UPDATE too (the counter rule, not AUTO_INCREMENT).
        $this->assertSame(2, (int) $row['server_seq']);
    }

    public function test_delete_tombstone_applied(): void
    {
        $this->push(['categories' => [$this->catRow('c1', 'Food', 100)]]);
        $this->push(['categories' => [$this->catRow('c1', 'Food', 200, 1)]]);
        $this->assertSame(1, (int) $this->storedRow('categories', 'c1')['is_deleted']);
    }

    public function test_tombstone_then_newer_update_resurrects(): void
    {
        // Already-tombstoned row.
        $this->push(['categories' => [$this->catRow('c1', 'Food', 100, 1)]]);
        $this->assertSame(1, (int) $this->storedRow('categories', 'c1')['is_deleted']);
        // A newer update with the same id resurrects it.
        $this->push(['categories' => [$this->catRow('c1', 'Food Reborn', 200, 0)]]);
        $row = $this->storedRow('categories', 'c1');
        $this->assertSame(0, (int) $row['is_deleted']);
        $this->assertSame('Food Reborn', $row['name']);
    }

    public function test_push_then_pull_roundtrip_returns_other_devices_changes(): void
    {
        // A change another device already persisted on the server (unsynced from this device's view).
        Db::pdo()->prepare(
            'INSERT INTO categories (id, name, color_value, is_protected, updated_at, is_deleted, server_seq)
             VALUES (?,?,1,0,?,0,?)'
        )->execute(['c-other', 'FromOther', 50, Sync::nextSeq(Db::pdo())]);

        // This device pushes its own change and pulls everything since last sync, in one round trip.
        [$status, $res] = $this->push(['categories' => [$this->catRow('c-mine', 'FromMe', 60)]], 0);

        $this->assertSame(200, $status);
        $ids = array_column($res['changes']['categories'], 'id');
        $this->assertContains('c-other', $ids); // other device's change echoed back
        $this->assertContains('c-mine', $ids);  // own change, now carrying a server-assigned server_seq
        $this->assertArrayHasKey('server_time', $res);
        $this->assertIsInt($res['server_time']);
    }

    public function test_same_id_increasing_updated_at_ends_at_newer(): void
    {
        // Two rows with the same id in one push; the later (newer updated_at) must win.
        [$status] = $this->push(['categories' => [
            $this->catRow('c1', 'First', 100),
            $this->catRow('c1', 'Second', 200),
        ]]);
        $this->assertSame(200, $status);
        $row = $this->storedRow('categories', 'c1');
        $this->assertSame('Second', $row['name']);
        $this->assertSame(200, (int) $row['updated_at']);
    }

    public function test_recreate_soft_deleted_name_frees_tombstone(): void
    {
        // A soft-deleted expense type holds the unique name 'Rent'.
        Db::pdo()->prepare(
            'INSERT INTO expense_types (id, name, updated_at, is_deleted, server_seq) VALUES (?,?,?,1,?)'
        )->execute(['et-old', 'Rent', 100, Sync::nextSeq(Db::pdo())]);

        // A new row with a DIFFERENT id re-creates the same name.
        [$status] = $this->push(['expense_types' => [$this->expenseTypeRow('et-new', 'Rent', 200)]]);
        $this->assertSame(200, $status);

        $rows = Db::pdo()->query("SELECT id FROM expense_types WHERE name = 'Rent'")->fetchAll(PDO::FETCH_COLUMN);
        $this->assertSame(['et-new'], $rows); // tombstone freed, new row inserted
    }

    public function test_active_name_collision_is_skipped(): void
    {
        // An ACTIVE expense type holds 'Rent'.
        Db::pdo()->prepare(
            'INSERT INTO expense_types (id, name, updated_at, is_deleted, server_seq) VALUES (?,?,?,0,?)'
        )->execute(['et-active', 'Rent', 100, Sync::nextSeq(Db::pdo())]);

        // A different-id row with the same name is dropped; the push still succeeds.
        [$status] = $this->push(['expense_types' => [$this->expenseTypeRow('et-new', 'Rent', 200)]]);
        $this->assertSame(200, $status);

        $this->assertNull($this->storedRow('expense_types', 'et-new'));
        $this->assertNotNull($this->storedRow('expense_types', 'et-active'));
    }

    public function test_update_rename_into_active_name_is_skipped_not_fatal(): void
    {
        // Two active expense types, plus a normal change that must still apply in the same batch.
        $ins = Db::pdo()->prepare(
            'INSERT INTO expense_types (id, name, updated_at, is_deleted, server_seq) VALUES (?,?,?,0,?)'
        );
        $ins->execute(['et-a', 'Alpha', 100, Sync::nextSeq(Db::pdo())]);
        $ins->execute(['et-b', 'Beta', 100, Sync::nextSeq(Db::pdo())]);

        // One push: (a) a normal unrelated row, and (b) renaming et-a -> 'Beta' (collides with active et-b).
        [$status] = $this->push([
            'categories' => [$this->catRow('c1', 'Food', 10)],
            'expense_types' => [$this->expenseTypeRow('et-a', 'Beta', 200)],
        ]);

        // The conflicting rename must NOT abort the whole batch.
        $this->assertSame(200, $status);
        // (a) the normal row applied...
        $this->assertNotNull($this->storedRow('categories', 'c1'));
        // ...(b) the conflicting rename was skipped: et-a keeps its name, et-b untouched.
        $this->assertSame('Alpha', $this->storedRow('expense_types', 'et-a')['name']);
        $this->assertSame('Beta', $this->storedRow('expense_types', 'et-b')['name']);
    }

    public function test_update_rename_over_tombstone_frees_it(): void
    {
        // An active row and a tombstone holding the target name.
        $ins = Db::pdo()->prepare(
            'INSERT INTO expense_types (id, name, updated_at, is_deleted, server_seq) VALUES (?,?,?,?,?)'
        );
        $ins->execute(['et-a', 'Alpha', 100, 0, Sync::nextSeq(Db::pdo())]);
        $ins->execute(['et-dead', 'Gamma', 100, 1, Sync::nextSeq(Db::pdo())]);

        // Rename et-a -> 'Gamma' (held only by the tombstone): the tombstone is freed, rename applies.
        [$status] = $this->push(['expense_types' => [$this->expenseTypeRow('et-a', 'Gamma', 200)]]);
        $this->assertSame(200, $status);

        $this->assertSame('Gamma', $this->storedRow('expense_types', 'et-a')['name']);
        $this->assertNull($this->storedRow('expense_types', 'et-dead')); // tombstone freed
    }

    public function test_equal_updated_at_tie_applies_incoming(): void
    {
        $this->push(['categories' => [$this->catRow('c1', 'Before', 100)]]);
        // Same updated_at as stored: the tie goes to the incoming write.
        $this->push(['categories' => [$this->catRow('c1', 'After', 100)]]);
        $this->assertSame('After', $this->storedRow('categories', 'c1')['name']);
    }

    public function test_movements_field_applied_alongside_changes(): void
    {
        $movements = [[
            'id' => 'm1', 'inventory_item_id' => 'i1', 'variant_name' => '',
            'delta' => 5, 'source_type' => 'adjustment', 'source_id' => 's1',
            'created_at' => 1, 'updated_at' => 1, 'is_deleted' => 0,
        ]];
        [$status] = $this->push(['categories' => [$this->catRow('c1', 'Food', 10)]], 0, $movements);
        $this->assertSame(200, $status);
        // Task 6: movements are applied (no item row exists, so only the movement is stored).
        $count = (int) Db::pdo()->query('SELECT COUNT(*) FROM stock_movements')->fetchColumn();
        $this->assertSame(1, $count);
        // The ordinary change still applied.
        $this->assertNotNull($this->storedRow('categories', 'c1'));
    }

    public function test_missing_or_null_json_blob_column_defaults_to_empty_array(): void
    {
        $base = [
            'id' => 'i1', 'name' => 'Bone', 'category' => 'Toys',
            'stock' => 4, 'reorder_level' => 2, 'unit_cost' => '3.50', 'price' => '9.99',
            'updated_at' => 10, 'is_deleted' => 0, 'server_seq' => 0,
        ];
        $missing = $base;                       // variants omitted entirely
        $null = ['id' => 'i2'] + $base;
        $null['id'] = 'i2';
        $null['variants'] = null;               // variants present but null

        [$status] = $this->push(['inventory_items' => [$missing, $null]]);
        $this->assertSame(200, $status);
        $this->assertSame('[]', $this->storedRow('inventory_items', 'i1')['variants']);
        $this->assertSame('[]', $this->storedRow('inventory_items', 'i2')['variants']);
    }

    public function test_unknown_columns_are_dropped(): void
    {
        $row = $this->catRow('c1', 'Food', 10);
        $row['bogus_col'] = 'nope';
        $row['another'] = 123;
        [$status] = $this->push(['categories' => [$row]]);
        $this->assertSame(200, $status);
        $this->assertSame('Food', $this->storedRow('categories', 'c1')['name']);
    }

    public function test_unknown_table_is_ignored(): void
    {
        [$status] = $this->push(['not_a_real_table' => [['id' => 'x', 'updated_at' => 1]]]);
        $this->assertSame(200, $status);
    }

    public function test_push_movements_updates_stock_and_response_map(): void
    {
        Db::pdo()->prepare(
            'INSERT INTO inventory_items (id, name, category, stock, reorder_level, unit_cost, price, updated_at, is_deleted, server_seq)
             VALUES (?,?,?,?,?,?,?,?,0,1)'
        )->execute(['i1', 'Food', 'Food', 50, 1, '1.00', '2.00', 1]);
        $mv = fn (string $id, int $d) => [
            'id' => $id, 'inventory_item_id' => 'i1', 'delta' => $d, 'source_type' => 'sale',
            'source_id' => 's' . $id, 'created_at' => 5, 'updated_at' => 5,
        ];

        [$status, $body] = $this->push([], 0, [$mv('m1', -3), $mv('m2', -2)]);
        $this->assertSame(200, $status);
        $this->assertSame(-5, $body['stock']['i1']);
        $this->assertSame(-5, (int) $this->storedRow('inventory_items', 'i1')['stock']);

        // Retried push (dropped response) must not double-count.
        [, $body] = $this->push([], 0, [$mv('m1', -3), $mv('m2', -2)]);
        $this->assertSame(-5, $body['stock']['i1']);
    }

    public function test_requires_auth(): void
    {
        Auth::$authHeader = null;
        unset($_SERVER['HTTP_AUTHORIZATION'], $_SERVER['REDIRECT_HTTP_AUTHORIZATION']);
        Json::$input = json_encode([
            'last_sync_at' => 0,
            'changes' => ['categories' => [$this->catRow('c1', 'X', 1)]],
            'movements' => [],
        ]);
        ob_start();
        Router::dispatch('POST', '/sync');
        ob_end_clean();
        $this->assertSame(401, http_response_code());
        $this->assertNull($this->storedRow('categories', 'c1')); // nothing written
    }
}
