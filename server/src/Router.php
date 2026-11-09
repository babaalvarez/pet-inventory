<?php
declare(strict_types=1);

require_once __DIR__ . '/Json.php';

/** Minimal router. Paths use {name} placeholders passed to handlers as an assoc array. */
final class Router
{
    /** @var array<int, array{string, string, callable}> */
    private static array $routes = [];

    public static function add(string $method, string $path, callable $handler): void
    {
        $regex = '#^' . preg_replace('#\\\{(\w+)\\\}#', '(?P<$1>[^/]+)', preg_quote($path, '#')) . '$#';
        self::$routes[] = [strtoupper($method), $regex, $handler];
    }

    public static function reset(): void
    {
        self::$routes = [];
    }

    public static function dispatch(string $method, string $uri): void
    {
        $path = rtrim((string) parse_url($uri, PHP_URL_PATH), '/');
        if ($path === '') {
            $path = '/';
        }
        $method = strtoupper($method);
        $pathMatched = false;

        try {
            foreach (self::$routes as [$m, $regex, $handler]) {
                if (!preg_match($regex, $path, $matches)) {
                    continue;
                }
                $pathMatched = true;
                if ($m !== $method) {
                    continue;
                }
                $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);
                $handler(array_map('urldecode', $params));
                return;
            }
        } catch (HttpAbort) {
            return; // error response already sent
        }

        if ($pathMatched) {
            Json::error('Method not allowed', 405);
        } else {
            Json::error('Not found', 404);
        }
    }
}
