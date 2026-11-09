<?php
declare(strict_types=1);

final class SyncPullTest extends DbTestCase
{
    private const USER_ID = '11111111-1111-4111-8111-111111111111';

    protected function setUp(): void
    {
        parent::setUp();
        $this->cat('c0', 'Seed', 1, 1, 0);
        $token = Auth::issueToken(Db::pdo(), self::USER_ID);
        Db::pdo()->prepare(
            'INSERT INTO user_accounts (id, username, password, display_name, role, is_active, updated_at, is_deleted, server_seq)
             VALUES (?,?,?,?,?,1,1,0,2)'
        )->execute([self::USER_ID, 'admin', Auth::hash('secret'), 'Admin', 'admin']);
        Router::reset();
        require __DIR__ . '/../src/routes.php';
        Auth::$authHeader = 'Bearer ' . $token;
    }

    private function cat(string $id, string $name, int $seq, int $updatedAt, int $deleted): void
    {
        Db::pdo()->prepare(
            'INSERT INTO categories (id, name, color_value, is_protected, updated_at, is_deleted, server_seq)
             VALUES (?,?,?,1,?,?,?)'
        )->execute([$id, $name, 255, $updatedAt, $deleted, $seq]);
    }

    private function pull(int $since): array
    {
        $_GET = ['since' => (string) $since];
        ob_start();
        Router::dispatch('GET', '/sync?since=' . $since);
        return json_decode((string) ob_get_clean(), true);
    }

    public function test_since_zero_returns_all_rows(): void
    {
        $this->cat('c1', 'A', 3, 5, 0);
        $res = $this->pull(0);
        $this->assertCount(2, $res['changes']['categories']);
        $this->assertCount(1, $res['changes']['user_accounts']);
        $this->assertSame(3, $res['cursor']);
        $this->assertSame('c1', $res['changes']['categories'][1]['id']);
    }

    public function test_returns_only_rows_after_cursor(): void
    {
        $this->cat('c1', 'A', 3, 5, 0);
        $this->cat('c2', 'B', 4, 6, 0);
        $res = $this->pull(3);
        $this->assertSame(['c2'], array_column($res['changes']['categories'], 'id'));
        $this->assertSame(4, $res['cursor']);
    }

    public function test_no_changes_keeps_cursor(): void
    {
        $res = $this->pull(50);
        $this->assertSame(50, $res['cursor']);
        $this->assertCount(0, $res['changes']['categories']);
    }

    public function test_includes_tombstones(): void
    {
        $this->cat('c1', 'A', 3, 5, 1);
        $row = $this->pull(2)['changes']['categories'][0];
        $this->assertSame('c1', $row['id']);
        $this->assertSame(1, $row['is_deleted']);
    }

    public function test_cursor_is_max_server_seq_not_updated_at(): void
    {
        $this->cat('c1', 'Old', 9, 1, 0); // ancient updated_at, newest seq
        $this->cat('c2', 'New', 8, 999999999, 0);
        $res = $this->pull(5);
        $this->assertCount(2, $res['changes']['categories']);
        $this->assertSame(9, $res['cursor']);
    }

    public function test_json_types_are_numeric(): void
    {
        Db::pdo()->prepare(
            'INSERT INTO inventory_items (id, name, category, stock, reorder_level, unit_cost, price, variants, updated_at, is_deleted, server_seq)
             VALUES (?,?,?,?,?,?,?,NULL,?,0,?)'
        )->execute(['i1', 'Bone', 'Toys', 4, 2, '3.50', '9.99', 123, 7]);
        $res = $this->pull(0);
        $i = $res['changes']['inventory_items'][0];
        $this->assertSame(4, $i['stock']);
        $this->assertIsInt($i['updated_at']);
        $this->assertIsInt($i['server_seq']);
        $this->assertSame(0, $i['is_deleted']);
        $this->assertSame(9.99, $i['price']);
        $this->assertSame('[]', $i['variants']);
        $this->assertSame('Bone', $i['name']);
        $this->assertSame(1, $res['changes']['categories'][0]['is_protected']);
    }

    public function test_user_accounts_include_password_hash(): void
    {
        $u = $this->pull(0)['changes']['user_accounts'][0];
        $this->assertTrue(password_verify('secret', $u['password']));
    }

    public function test_stock_map_sums_non_deleted_movements(): void
    {
        $ins = Db::pdo()->prepare(
            'INSERT INTO stock_movements (id, inventory_item_id, variant_name, delta, source_type, source_id, created_at, updated_at, is_deleted, server_seq)
             VALUES (?,?,?,?,?,?,?,?,?,?)'
        );
        $ins->execute(['m1', 'i1', '', 10, 'adjustment', 's', 1, 1, 0, 3]);
        $ins->execute(['m2', 'i1', '', -3, 'sale', 's', 1, 1, 0, 4]);
        $ins->execute(['m3', 'i1', '', 100, 'sale', 's', 1, 1, 1, 5]);
        $ins->execute(['m4', 'i2', '', 2, 'adjustment', 's', 1, 1, 0, 6]);
        $res = $this->pull(0);
        $this->assertSame(['i1' => 7, 'i2' => 2], $res['stock']);
    }

    public function test_empty_stock_is_json_object(): void
    {
        $_GET = ['since' => '0'];
        ob_start();
        Router::dispatch('GET', '/sync?since=0');
        $raw = (string) ob_get_clean();
        $this->assertStringContainsString('"stock":{}', $raw);
    }

    public function test_requires_auth(): void
    {
        Auth::$authHeader = null;
        unset($_SERVER['HTTP_AUTHORIZATION'], $_SERVER['REDIRECT_HTTP_AUTHORIZATION']);
        ob_start();
        Router::dispatch('GET', '/sync');
        ob_end_clean();
        $this->assertSame(401, http_response_code());
    }
}
