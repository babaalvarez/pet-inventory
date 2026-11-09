<?php
declare(strict_types=1);

require_once __DIR__ . '/../src/Stock.php';

final class StockTest extends DbTestCase
{
    private const ITEM = 'item-1';

    protected function setUp(): void
    {
        parent::setUp();
        Db::pdo()->prepare(
            'INSERT INTO inventory_items (id, name, category, stock, reorder_level, unit_cost, price, updated_at, is_deleted, server_seq)
             VALUES (?,?,?,?,?,?,?,?,0,1)'
        )->execute([self::ITEM, 'Dog Food', 'Food', 100, 5, '1.00', '2.00', 1]);
    }

    private function mv(string $id, int $delta, int $deleted = 0): array
    {
        return [
            'id' => $id, 'inventory_item_id' => self::ITEM, 'variant_name' => '',
            'delta' => $delta, 'source_type' => 'sale', 'source_id' => 's-' . $id,
            'created_at' => 10, 'updated_at' => 10, 'is_deleted' => $deleted,
        ];
    }

    private function stock(): int
    {
        return (int) Db::pdo()->query("SELECT stock FROM inventory_items WHERE id = '" . self::ITEM . "'")->fetchColumn();
    }

    public function test_single_movement_sets_stock(): void
    {
        Stock::applyMovements(Db::pdo(), [$this->mv('m1', 7)]);
        $this->assertSame(7, $this->stock());
    }

    public function test_duplicate_movement_id_ignored(): void
    {
        Stock::applyMovements(Db::pdo(), [$this->mv('m1', -4)]);
        Stock::applyMovements(Db::pdo(), [$this->mv('m1', -4), $this->mv('m1', -4)]);
        $this->assertSame(-4, $this->stock());
        $this->assertSame(1, (int) Db::pdo()->query('SELECT COUNT(*) FROM stock_movements')->fetchColumn());
    }

    public function test_two_concurrent_decrements_sum(): void
    {
        Stock::applyMovements(Db::pdo(), [$this->mv('a', -3)]);
        Stock::applyMovements(Db::pdo(), [$this->mv('b', -2)]);
        $this->assertSame(-5, $this->stock());
    }

    public function test_deleted_movement_excluded_from_sum(): void
    {
        Stock::applyMovements(Db::pdo(), [$this->mv('a', -3), $this->mv('b', -2, 1)]);
        $this->assertSame(-3, $this->stock());
    }

    public function test_movements_without_id_or_item_skipped(): void
    {
        Stock::applyMovements(Db::pdo(), [['delta' => 1], ['id' => 'x', 'delta' => 1]]);
        $this->assertSame(0, (int) Db::pdo()->query('SELECT COUNT(*) FROM stock_movements')->fetchColumn());
    }
}
