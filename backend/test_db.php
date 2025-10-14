<?php
// Quiet the deprecations for now (library vs PHP version mismatch)
error_reporting(E_ALL & ~E_DEPRECATED);
ini_set('display_errors', 1);

require __DIR__ . '/vendor/autoload.php';

Dotenv\Dotenv::createImmutable(__DIR__, ['.env'])->safeLoad();

// Debug: prove .env was seen and values populated into $_ENV
echo "ENV file exists? " . (file_exists(__DIR__ . '/.env') ? 'YES' : 'NO') . " at " . (__DIR__ . '/.env') . "\n";
echo "Loaded ENV? DB_USER from _ENV=" . ($_ENV['DB_USER'] ?? 'EMPTY') . "\n";
echo "Loaded ENV? DB_PASS set? " . (isset($_ENV['DB_PASS']) && $_ENV['DB_PASS'] !== '' ? 'YES' : 'NO') . "\n";

// Use a helper that checks _ENV first, then _SERVER, then getenv()
function env(string $key, $default = null)
{
    if (isset($_ENV[$key]))
        return $_ENV[$key];
    if (isset($_SERVER[$key]))
        return $_SERVER[$key];
    $v = getenv($key);
    return ($v === false || $v === '') ? $default : $v;
}

$dsn = sprintf(
    "%s:host=%s;port=%s;dbname=%s",
    env('DB_DRIVER', 'pgsql'),
    env('DB_HOST', '127.0.0.1'),
    env('DB_PORT', '5432'),
    env('DB_NAME', 'postgres')
);

try {
    $pdo = new PDO($dsn, env('DB_USER'), env('DB_PASS'), [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
    echo "✅ Connected!\n";
    echo "Server version: " . $pdo->getAttribute(PDO::ATTR_SERVER_VERSION) . "\n";
} catch (Throwable $e) {
    echo "❌ Connection failed: " . $e->getMessage() . "\n";
}
