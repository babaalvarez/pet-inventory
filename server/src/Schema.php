<?php
declare(strict_types=1);

/** Applies server/schema.sql to a database (used by tests and usable for setup). */
final class Schema
{
    public static function applyTo(PDO $pdo): void
    {
        $sql = file_get_contents(__DIR__ . '/../schema.sql');
        if ($sql === false) {
            throw new RuntimeException('schema.sql not readable');
        }
        // Strip full-line comments, then split on statement terminators.
        $lines = array_filter(
            explode("\n", $sql),
            static fn (string $l): bool => !str_starts_with(ltrim($l), '--')
        );
        foreach (explode(';', implode("\n", $lines)) as $stmt) {
            if (trim($stmt) !== '') {
                $pdo->exec($stmt);
            }
        }
    }
}
