<?php
declare(strict_types=1);

use PHPUnit\Framework\TestCase;

/** Base for tests that touch the database: starts every test from a clean schema. */
abstract class DbTestCase extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::reset(Db::pdo());
    }
}
