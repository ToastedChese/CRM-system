<?php
header('Content-Type: application/json');
require '../src/db.php';

$data = json_decode(file_get_contents('php://input'), true);
$email = $data['Email'] ?? '';
$password = $data['Password'] ?? '';

try {
    $stmt = $pdo->prepare("SELECT user_id, email, password, user_type FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($user && password_verify($password, $user['password'])) {
        echo json_encode([
            'success' => true,
            'user_id' => $user['user_id'],
        ]);
    } else {
        echo json_encode(['success' => false, 'error' => 'Invalid email or password']);
    }
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>