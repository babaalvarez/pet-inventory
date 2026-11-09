<?php
declare(strict_types=1);

/** JSON request/response helpers. */
final class Json
{
    /** Override in tests; null means read php://input. */
    public static ?string $input = null;

    /** Decoded JSON request body as an assoc array ([] when empty). */
    public static function body(): array
    {
        $raw = self::$input ?? (string) file_get_contents('php://input');
        if (trim($raw) === '') {
            return [];
        }
        $data = json_decode($raw, true);
        if (!is_array($data)) {
            self::error('Invalid JSON body', 400);
            throw new HttpAbort(400);
        }
        return $data;
    }

    public static function send(array $data, int $status = 200): void
    {
        http_response_code($status);
        if (!headers_sent()) {
            header('Content-Type: application/json; charset=utf-8');
        }
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    public static function error(string $msg, int $status): void
    {
        self::send(['error' => $msg], $status);
    }
}

/** Thrown after an error response has already been sent, to stop handler execution. */
final class HttpAbort extends RuntimeException
{
}
