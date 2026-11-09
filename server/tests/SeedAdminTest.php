<?php
declare(strict_types=1);

require_once __DIR__ . '/../seed_admin.php';

final class SeedAdminTest extends DbTestCase
{
    public function test_seed_creates_hashed_super_admin(): void
    {
        $db = Db::pdo();
        seedAdmin($db, 'admin', 'pw123', 'Owner');
        $row = $db->query("SELECT * FROM user_accounts WHERE username='admin'")->fetch(PDO::FETCH_ASSOC);
        $this->assertSame('super_admin', $row['role']);
        $this->assertSame(1, (int) $row['is_active']);
        $this->assertSame(0, (int) $row['is_deleted']);
        $this->assertTrue(password_verify('pw123', $row['password']));
        $this->assertGreaterThan(0, (int) $row['server_seq']);
    }

    public function test_seed_is_idempotent_on_username(): void
    {
        $db = Db::pdo();
        seedAdmin($db, 'admin', 'pw123', 'Owner');
        $first = (int) $db->query("SELECT server_seq FROM user_accounts WHERE username='admin'")->fetchColumn();
        seedAdmin($db, 'admin', 'newpw', 'Owner 2');
        $rows = $db->query("SELECT * FROM user_accounts WHERE username='admin'")->fetchAll(PDO::FETCH_ASSOC);
        $this->assertCount(1, $rows);
        $this->assertTrue(password_verify('newpw', $rows[0]['password']));
        $this->assertSame('Owner 2', $rows[0]['display_name']);
        $this->assertGreaterThan($first, (int) $rows[0]['server_seq']);
    }
}
