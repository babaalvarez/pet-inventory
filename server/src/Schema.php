<?php
declare(strict_types=1);

/** Applies server/schema.sql to a database (used by tests and usable for setup). */
final class Schema
{
    /** Test-only: drops every table this schema owns, then recreates them. */
    public static function reset(PDO $pdo): void
    {
        $sql = (string) file_get_contents(__DIR__ . '/../schema.sql');
        preg_match_all('/CREATE TABLE IF NOT EXISTS\s+`?(\w+)`?/i', $sql, $m);
        $pdo->exec('SET FOREIGN_KEY_CHECKS=0');
        foreach ($m[1] as $table) {
            $pdo->exec("DROP TABLE IF EXISTS `$table`");
        }
        self::applyTo($pdo);
        $pdo->exec('SET FOREIGN_KEY_CHECKS=1');
    }

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
