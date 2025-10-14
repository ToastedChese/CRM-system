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

//generic
CREATE TABLE employees (
    user_id VARCHAR(255) PRIMARY KEY,
    EmployeeID VARCHAR(255) UNIQUE NOT NULL,
    FirstName VARCHAR(255),
    LastName VARCHAR(255),
    Email VARCHAR(255),
    PhoneNumber VARCHAR(20),
    Role VARCHAR(100),
    HireDate DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE customers (
    user_id VARCHAR(255) PRIMARY KEY,
    FirstName VARCHAR(255),
    LastName VARCHAR(255),
    Email VARCHAR(255),
    Phone VARCHAR(20),
    Address TEXT,
    CustomerType VARCHAR(50),
    DateCreated DATE,
    CustomerSatisfactionScore INT,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);