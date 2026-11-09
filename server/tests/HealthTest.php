<?php
declare(strict_types=1);

use PHPUnit\Framework\TestCase;

final class HealthTest extends TestCase
{
    public function test_health_returns_ok(): void
    {
        Router::reset();
        require __DIR__ . '/../src/routes.php';

        ob_start();
        Router::dispatch('GET', '/health');
        $out = ob_get_clean();

        $this->assertSame(200, http_response_code());
        $this->assertSame(['status' => 'ok'], json_decode($out, true));
    }

    public function test_unknown_route_returns_json_404(): void
    {
        Router::reset();
        require __DIR__ . '/../src/routes.php';

        ob_start();
        Router::dispatch('GET', '/nope');
        $out = ob_get_clean();

        $this->assertSame(404, http_response_code());
        $this->assertSame(['error' => 'Not found'], json_decode($out, true));
    }
}
