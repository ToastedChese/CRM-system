<?php
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Db;

// Root – avoid 404 when you hit "/"
$app->get('/', function (Request $req, Response $res) {
    $res->getBody()->write(json_encode([
        'ok' => true,
        'message' => 'Backend is running',
        'routes' => ['/api/v1/health', '/api/v1/contacts']
    ]));
    return $res->withHeader('Content-Type', 'application/json');
});

$app->get('/api/v1/health', function (Request $req, Response $res) {
    $res->getBody()->write(json_encode(['ok' => true]));
    return $res->withHeader('Content-Type', 'application/json');
});

// List contacts
$app->get('/api/v1/contacts', function (Request $req, Response $res) {
    $pdo = Db::pdo();
    $rows = $pdo->query("SELECT * FROM contacts ORDER BY id DESC")->fetchAll();
    $res->getBody()->write(json_encode(['data' => $rows]));
    return $res->withHeader('Content-Type', 'application/json');
});

// Create contact
$app->post('/api/v1/contacts', function (Request $req, Response $res) {
    $b = json_decode((string) $req->getBody(), true) ?? [];
    foreach (['first_name', 'last_name', 'email'] as $f) {
        if (empty($b[$f])) {
            $res->getBody()->write(json_encode(['error' => "$f is required"]));
            return $res->withStatus(422)->withHeader('Content-Type', 'application/json');
        }
    }

    $pdo = Db::pdo();
    $stmt = $pdo->prepare(
        "INSERT INTO contacts(first_name,last_name,email,phone)
         VALUES(:fn,:ln,:em,:ph) RETURNING *"
    );
    $stmt->execute([
        ':fn' => $b['first_name'],
        ':ln' => $b['last_name'],
        ':em' => $b['email'],
        ':ph' => $b['phone'] ?? null,
    ]);

    $res->getBody()->write(json_encode($stmt->fetch()));
    return $res->withStatus(201)->withHeader('Content-Type', 'application/json');
});

// Update contact (PATCH)
$app->patch('/api/v1/contacts/{id}', function (Request $req, Response $res, array $args) {
    $pdo = Db::pdo();
    $id = (int) $args['id'];
    $b = json_decode((string) $req->getBody(), true) ?? [];

    // Only update provided fields
    $fields = [];
    $params = [':id' => $id];
    foreach (['first_name', 'last_name', 'email', 'phone'] as $f) {
        if (array_key_exists($f, $b) && $b[$f] !== null && $b[$f] !== '') {
            $fields[] = "$f = :$f";
            $params[":$f"] = $b[$f];
        }
    }

    if (!$fields) {
        $res->getBody()->write(json_encode(['error' => 'No fields to update']));
        return $res->withStatus(400)->withHeader('Content-Type', 'application/json');
    }

    $sql = "UPDATE contacts SET " . implode(', ', $fields) . " WHERE id = :id RETURNING *";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    $updated = $stmt->fetch();
    if (!$updated) {
        $res->getBody()->write(json_encode(['error' => 'Contact not found']));
        return $res->withStatus(404)->withHeader('Content-Type', 'application/json');
    }

    $res->getBody()->write(json_encode($updated));
    return $res->withHeader('Content-Type', 'application/json');
});

// Delete contact
$app->delete('/api/v1/contacts/{id}', function (Request $req, Response $res, array $args) {
    $pdo = Db::pdo();
    $id = (int) $args['id'];

    $stmt = $pdo->prepare("DELETE FROM contacts WHERE id = :id RETURNING *");
    $stmt->execute([':id' => $id]);

    $deleted = $stmt->fetch();
    if (!$deleted) {
        $res->getBody()->write(json_encode(['error' => 'Contact not found']));
        return $res->withStatus(404)->withHeader('Content-Type', 'application/json');
    }

    $res->getBody()->write(json_encode(['deleted' => $deleted]));
    return $res->withHeader('Content-Type', 'application/json');
});
