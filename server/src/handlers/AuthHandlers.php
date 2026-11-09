<?php
declare(strict_types=1);

require_once __DIR__ . '/../Auth.php';
require_once __DIR__ . '/../Db.php';

final class AuthHandlers
{
    public static function login(array $params): void
    {
        $body = Json::body();
        $username = (string) ($body['username'] ?? '');
        $password = (string) ($body['password'] ?? '');

        $pdo = Db::pdo();
        $st = $pdo->prepare('SELECT * FROM user_accounts WHERE username = ? AND is_active = 1 AND is_deleted = 0');
        $st->execute([$username]);
        $user = $st->fetch(PDO::FETCH_ASSOC);

        if ($user === false || !password_verify($password, (string) $user['password'])) {
            Json::error('Invalid credentials', 401);
            return;
        }

        $token = Auth::issueToken($pdo, (string) $user['id']);
        unset($user['password']);
        Json::send(['token' => $token, 'user' => $user]);
    }

    public static function logout(array $params): void
    {
        $pdo = Db::pdo();
        Auth::requireUser($pdo);
        $pdo->prepare('DELETE FROM auth_tokens WHERE token = ?')->execute([Auth::bearerToken()]);
        Json::send(['ok' => true]);
    }
}
