<?php
declare(strict_types=1);

final class AuthTest extends DbTestCase
{
    private const USER_ID = '11111111-1111-4111-8111-111111111111';

    protected function setUp(): void
    {
        parent::setUp();
        Db::pdo()->prepare(
            'INSERT INTO user_accounts (id, username, password, display_name, role, is_active, updated_at, is_deleted, server_seq)
             VALUES (?,?,?,?,?,1,1,0,1)'
        )->execute([self::USER_ID, 'admin', Auth::hash('secret'), 'Admin', 'admin']);
        Router::reset();
        require __DIR__ . '/../src/routes.php';
        Auth::$authHeader = null;
    }

    private function post(string $uri, array $body): array
    {
        Json::$input = json_encode($body);
        ob_start();
        Router::dispatch('POST', $uri);
        return [http_response_code(), json_decode((string) ob_get_clean(), true)];
    }

    public function test_login_success_returns_token_and_user(): void
    {
        [$status, $res] = $this->post('/auth/login', ['username' => 'admin', 'password' => 'secret']);
        $this->assertSame(200, $status);
        $this->assertSame(64, strlen($res['token']));
        $this->assertSame('admin', $res['user']['username']);
        $this->assertSame(self::USER_ID, $res['user']['id']);
        $this->assertNotNull(Auth::userForToken(Db::pdo(), $res['token']));
    }

    public function test_login_wrong_password_401(): void
    {
        [$status] = $this->post('/auth/login', ['username' => 'admin', 'password' => 'nope']);
        $this->assertSame(401, $status);
    }

    public function test_login_unknown_user_401(): void
    {
        [$status] = $this->post('/auth/login', ['username' => 'ghost', 'password' => 'secret']);
        $this->assertSame(401, $status);
    }

    public function test_login_deactivated_user_401(): void
    {
        Db::pdo()->exec('UPDATE user_accounts SET is_active=0');
        [$status] = $this->post('/auth/login', ['username' => 'admin', 'password' => 'secret']);
        $this->assertSame(401, $status);
    }

    public function test_token_for_deactivated_user_rejected(): void
    {
        $token = Auth::issueToken(Db::pdo(), self::USER_ID);
        $this->assertNotNull(Auth::userForToken(Db::pdo(), $token));
        Db::pdo()->exec('UPDATE user_accounts SET is_active=0');
        $this->assertNull(Auth::userForToken(Db::pdo(), $token));
    }

    public function test_login_response_omits_password(): void
    {
        [, $res] = $this->post('/auth/login', ['username' => 'admin', 'password' => 'secret']);
        $this->assertArrayNotHasKey('password', $res['user']);
    }

    public function test_logout_deletes_token(): void
    {
        $token = Auth::issueToken(Db::pdo(), self::USER_ID);
        Auth::$authHeader = 'Bearer ' . $token;
        [$status] = $this->post('/auth/logout', []);
        $this->assertSame(200, $status);
        $this->assertNull(Auth::userForToken(Db::pdo(), $token));
    }

    public function test_logout_without_token_401(): void
    {
        [$status] = $this->post('/auth/logout', []);
        $this->assertSame(401, $status);
    }
}
