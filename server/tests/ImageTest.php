<?php
declare(strict_types=1);

final class ImageTest extends DbTestCase
{
    private const USER_ID = '11111111-1111-4111-8111-111111111111';
    private const PNG_B64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

    /** @var string[] */
    private array $tmp = [];
    private string $uploadDir;
    /** @var string[] */
    private array $before = [];

    protected function setUp(): void
    {
        parent::setUp();
        Db::pdo()->prepare(
            'INSERT INTO user_accounts (id, username, password, display_name, role, is_active, updated_at, is_deleted, server_seq)
             VALUES (?,?,?,?,?,1,1,0,1)'
        )->execute([self::USER_ID, 'admin', Auth::hash('secret'), 'Admin', 'admin']);
        Auth::$authHeader = 'Bearer ' . Auth::issueToken(Db::pdo(), self::USER_ID);
        Router::reset();
        require __DIR__ . '/../src/routes.php';
        $this->uploadDir = __DIR__ . '/../public/uploads';
        $this->before = is_dir($this->uploadDir) ? (scandir($this->uploadDir) ?: []) : [];
        ImageHandlers::$moveFn = fn(string $from, string $to): bool => rename($from, $to);
    }

    protected function tearDown(): void
    {
        $_FILES = [];
        Auth::$authHeader = null;
        foreach ($this->tmp as $f) {
            @unlink($f);
        }
        if (is_dir($this->uploadDir)) {
            foreach (array_diff(scandir($this->uploadDir) ?: [], $this->before) as $f) {
                @unlink($this->uploadDir . '/' . $f);
            }
        }
        ImageHandlers::$moveFn = null;
        parent::tearDown();
    }

    private function tmpFile(string $bytes): string
    {
        $p = tempnam(sys_get_temp_dir(), 'imgtest');
        file_put_contents($p, $bytes);
        $this->tmp[] = $p;
        return $p;
    }

    private function upload(string $bytes, int $error = UPLOAD_ERR_OK, string $name = 'x.png'): array
    {
        $p = $this->tmpFile($bytes);
        $_FILES = ['image' => ['name' => $name, 'type' => 'image/png', 'tmp_name' => $p,
            'error' => $error, 'size' => strlen($bytes)]];
        ob_start();
        Router::dispatch('POST', '/images');
        return [http_response_code(), json_decode((string) ob_get_clean(), true)];
    }

    private function savedCount(): int
    {
        return count(array_diff(is_dir($this->uploadDir) ? (scandir($this->uploadDir) ?: []) : [], $this->before));
    }

    public function test_valid_png_upload_returns_url_and_file_exists(): void
    {
        [$status, $res] = $this->upload((string) base64_decode(self::PNG_B64));
        $this->assertSame(200, $status);
        $this->assertMatchesRegularExpression('#^/uploads/[0-9a-f-]{36}\.png$#', $res['url']);
        $this->assertFileExists($this->uploadDir . '/' . basename($res['url']));
    }

    public function test_non_image_rejected_400(): void
    {
        [$status, $res] = $this->upload('just some text, not an image', UPLOAD_ERR_OK, 'evil.png');
        $this->assertSame(400, $status);
        $this->assertArrayHasKey('error', $res);
        $this->assertSame(0, $this->savedCount());
    }

    public function test_oversize_rejected(): void
    {
        $big = (string) base64_decode(self::PNG_B64) . str_repeat("\0", 5 * 1024 * 1024);
        [$status, $res] = $this->upload($big);
        $this->assertSame(413, $status);
        $this->assertArrayHasKey('error', $res);
        $this->assertSame(0, $this->savedCount());
    }

    public function test_missing_file_400(): void
    {
        $_FILES = [];
        ob_start();
        Router::dispatch('POST', '/images');
        ob_get_clean();
        $this->assertSame(400, http_response_code());
    }

    public function test_upload_error_400(): void
    {
        [$status] = $this->upload('', UPLOAD_ERR_PARTIAL);
        $this->assertSame(400, $status);
    }

    public function test_requires_auth(): void
    {
        Auth::$authHeader = null;
        [$status] = $this->upload((string) base64_decode(self::PNG_B64));
        $this->assertSame(401, $status);
        $this->assertSame(0, $this->savedCount());
    }
}
