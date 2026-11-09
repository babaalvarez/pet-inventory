<?php
declare(strict_types=1);

require_once __DIR__ . '/../Auth.php';
require_once __DIR__ . '/../Db.php';

final class ImageHandlers
{
    public const MAX_BYTES = 5 * 1024 * 1024;
    private const EXT = ['image/png' => 'png', 'image/jpeg' => 'jpg', 'image/webp' => 'webp'];

    /** Override in tests (rename/copy); null means move_uploaded_file. fn(string $from, string $to): bool */
    public static $moveFn = null;

    public static function upload(array $params): void
    {
        Auth::requireUser(Db::pdo());

        $f = $_FILES['image'] ?? null;
        if (!is_array($f) || !isset($f['error'], $f['tmp_name'])) {
            Json::error('Missing "image" file', 400);
            return;
        }
        $err = (int) $f['error'];
        if ($err === UPLOAD_ERR_INI_SIZE || $err === UPLOAD_ERR_FORM_SIZE) {
            Json::error('Image too large (max 5 MB)', 413);
            return;
        }
        if ($err !== UPLOAD_ERR_OK) {
            Json::error('Upload failed (code ' . $err . ')', 400);
            return;
        }
        $tmp = (string) $f['tmp_name'];
        $size = @filesize($tmp);
        if ($size === false || $size === 0) {
            Json::error('Empty or unreadable upload', 400);
            return;
        }
        if ($size > self::MAX_BYTES) {
            Json::error('Image too large (max 5 MB)', 413);
            return;
        }

        // Detect from the bytes, never the client-supplied type or extension.
        $mime = (new finfo(FILEINFO_MIME_TYPE))->file($tmp);
        if ($mime === false || !isset(self::EXT[$mime])) {
            Json::error('Unsupported image type (png, jpeg, webp only)', 400);
            return;
        }

        $dir = __DIR__ . '/../../public/uploads';
        if (!is_dir($dir) && !@mkdir($dir, 0775, true) && !is_dir($dir)) {
            Json::error('Cannot create upload directory', 500);
            return;
        }
        $name = Auth::uuid4() . '.' . self::EXT[$mime];
        $move = self::$moveFn ?? static fn(string $a, string $b): bool => move_uploaded_file($a, $b);
        if (!$move($tmp, $dir . '/' . $name)) {
            Json::error('Failed to store upload', 500);
            return;
        }
        Json::send(['url' => '/uploads/' . $name]);
    }
}
