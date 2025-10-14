<?php
// Optional: quiet the deprecation noise in dev
error_reporting(E_ALL & ~E_DEPRECATED);
ini_set('display_errors', 1);

use Slim\Factory\AppFactory;

require __DIR__ . '/../vendor/autoload.php';

// Load .env
$dotenv = Dotenv\Dotenv::createImmutable(dirname(__DIR__), ['.env']);
$dotenv->safeLoad();

$app = AppFactory::create();
$app->addBodyParsingMiddleware();

// CORS (dev)
$app->add(function ($req, $handler) {
    $res = $handler->handle($req);
    return $res->withHeader('Access-Control-Allow-Origin', '*')
        ->withHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        ->withHeader('Access-Control-Allow-Methods', 'GET,POST,PATCH,DELETE,OPTIONS');
});

// Register routes (including the "/" route)
require __DIR__ . '/../src/routes.php';

// Run the app (must be last)
$app->run();
