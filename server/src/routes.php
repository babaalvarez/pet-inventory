<?php
declare(strict_types=1);

require_once __DIR__ . '/Json.php';
require_once __DIR__ . '/Router.php';
require_once __DIR__ . '/Db.php';

// Route registration. Included by public/index.php and by tests (after Router::reset()).
Router::add('GET', '/health', function (array $params): void {
    Json::send(['status' => 'ok']);
});

require_once __DIR__ . '/Auth.php';
require_once __DIR__ . '/handlers/AuthHandlers.php';

Router::add('POST', '/auth/login', [AuthHandlers::class, 'login']);
Router::add('POST', '/auth/logout', [AuthHandlers::class, 'logout']);

require_once __DIR__ . '/handlers/SyncHandlers.php';

Router::add('GET', '/sync', [SyncHandlers::class, 'pull']);
Router::add('POST', '/sync', [SyncHandlers::class, 'push']);

require_once __DIR__ . '/handlers/ImageHandlers.php';

Router::add('POST', '/images', [ImageHandlers::class, 'upload']);
