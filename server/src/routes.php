<?php
declare(strict_types=1);

require_once __DIR__ . '/Json.php';
require_once __DIR__ . '/Router.php';
require_once __DIR__ . '/Db.php';

// Route registration. Included by public/index.php and by tests (after Router::reset()).
Router::add('GET', '/health', function (array $params): void {
    Json::send(['status' => 'ok']);
});
