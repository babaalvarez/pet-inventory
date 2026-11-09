<?php
declare(strict_types=1);

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../src/Schema.php';

final class SchemaTest extends TestCase
{
    private const SYNCABLE = [
        'categories', 'inventory_items', 'discounts', 'expenses', 'expense_types',
        'user_accounts', 'loans', 'suppliers', 'receipts', 'purchase_orders',
        'stock_adjustments',
    ];

    public function test_all_tables_exist(): void
    {
        $pdo = Db::pdo();
        Schema::applyTo($pdo);
        Schema::applyTo($pdo); // idempotent

        $tables = $pdo->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);
        foreach (array_merge(self::SYNCABLE, ['auth_tokens', 'stock_movements', 'server_sequence']) as $t) {
            $this->assertContains($t, $tables, "missing table $t");
        }

        $cols = $pdo->query('SHOW COLUMNS FROM inventory_items')->fetchAll(PDO::FETCH_COLUMN);
        $expected = 'id,name,category,stock,reorder_level,unit_cost,price,variant,variants,sku,representation,display_color_value,display_shape,image_path,image_url,updated_at,is_deleted,server_seq';
        foreach (explode(',', $expected) as $c) {
            $this->assertContains($c, $cols, "inventory_items missing $c");
        }
    }

    public function test_every_syncable_table_has_sync_metadata_and_seq_index(): void
    {
        $pdo = Db::pdo();
        Schema::applyTo($pdo);
        foreach (array_merge(self::SYNCABLE, ['stock_movements']) as $t) {
            $cols = $pdo->query("SHOW COLUMNS FROM `$t`")->fetchAll(PDO::FETCH_COLUMN);
            foreach (['updated_at', 'is_deleted', 'server_seq'] as $c) {
                $this->assertContains($c, $cols, "$t missing $c");
            }
            $idx = $pdo->query("SHOW INDEX FROM `$t` WHERE Column_name = 'server_seq'")->fetchAll();
            $this->assertNotEmpty($idx, "$t has no server_seq index");
        }
    }

    public function test_server_sequence_seeded_once_and_server_seq_not_auto_increment(): void
    {
        $pdo = Db::pdo();
        Schema::applyTo($pdo);
        Schema::applyTo($pdo);
        $this->assertSame(1, (int) $pdo->query('SELECT COUNT(*) FROM server_sequence')->fetchColumn());
        $extra = $pdo->query("SELECT EXTRA FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='inventory_items' AND COLUMN_NAME='server_seq'")->fetchColumn();
        $this->assertStringNotContainsString('auto_increment', strtolower((string) $extra));
    }
}
