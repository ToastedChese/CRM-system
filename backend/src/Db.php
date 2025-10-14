<?php
namespace App;
use PDO;

class Db
{
    protected static function env(string $key, $default = null)
    {
        if (isset($_ENV[$key]))
            return $_ENV[$key];
        if (isset($_SERVER[$key]))
            return $_SERVER[$key];
        $v = getenv($key);
        return ($v === false || $v === '') ? $default : $v;
    }

    public static function pdo(): PDO
    {
        $dsn = sprintf(
            "%s:host=%s;port=%s;dbname=%s",
            self::env('DB_DRIVER', 'pgsql'),
            self::env('DB_HOST', '127.0.0.1'),
            self::env('DB_PORT', '5432'),
            self::env('DB_NAME', 'postgres')
        );

        return new PDO($dsn, self::env('DB_USER'), self::env('DB_PASS'), [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
    }
}
