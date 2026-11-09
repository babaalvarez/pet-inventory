<?php
declare(strict_types=1);

require_once __DIR__ . '/Json.php';

/** Password hashing, bearer tokens and the auth guard. */
final class Auth
{
    /** Override in tests (e.g. "Bearer abc"); null means read from the request. */
    public static ?string $authHeader = null;

    public static function hash(string $pw): string
    {
        return password_hash($pw, PASSWORD_BCRYPT);
    }

    public static function uuid4(): string
    {
        $b = random_bytes(16);
        $b[6] = chr((ord($b[6]) & 0x0f) | 0x40);
        $b[8] = chr((ord($b[8]) & 0x3f) | 0x80);
        $h = bin2hex($b);
        return substr($h, 0, 8) . '-' . substr($h, 8, 4) . '-' . substr($h, 12, 4)
            . '-' . substr($h, 16, 4) . '-' . substr($h, 20, 12);
    }

    public static function issueToken(PDO $pdo, string $userId): string
    {
        $token = bin2hex(random_bytes(32));
        $pdo->prepare('INSERT INTO auth_tokens (token, user_id, created_at) VALUES (?,?,?)')
            ->execute([$token, $userId, (int) round(microtime(true) * 1000)]);
        return $token;
    }

    /** User row for a valid token, or null if the token is unknown or the user inactive/deleted. */
    public static function userForToken(PDO $pdo, string $token): ?array
    {
        $st = $pdo->prepare(
            'SELECT u.* FROM auth_tokens t JOIN user_accounts u ON u.id = t.user_id
             WHERE t.token = ? AND u.is_active = 1 AND u.is_deleted = 0'
        );
        $st->execute([$token]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }

    public static function bearerToken(): ?string
    {
        $h = self::$authHeader;
        if ($h === null) {
            $h = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? null;
            if ($h === null && function_exists('getallheaders')) {
                foreach (getallheaders() as $k => $v) {
                    if (strcasecmp((string) $k, 'Authorization') === 0) {
                        $h = (string) $v;
                        break;
                    }
                }
            }
        }
        if ($h !== null && preg_match('/^Bearer\s+(\S+)$/i', trim($h), $m)) {
            return $m[1];
        }
        return null;
    }

    /** Returns the authenticated user or sends 401 and aborts. */
    public static function requireUser(PDO $pdo): array
    {
        $token = self::bearerToken();
        $user = $token === null ? null : self::userForToken($pdo, $token);
        if ($user === null) {
            Json::error('Unauthorized', 401);
            throw new HttpAbort('Unauthorized', 401);
        }
        return $user;
    }
}
