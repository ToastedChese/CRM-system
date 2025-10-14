<?php
header('Content-Type: application/json');
require '../src/db.php';

$data = json_decode(file_get_contents('php://input'), true);
$email = $data['Email'] ?? '';
$password = password_hash($data['Password'] ?? '', PASSWORD_BCRYPT);
$first_name = $data['FirstName'] ?? '';
$last_name = $data['LastName'] ?? '';
$phone = $data['Phone'] ?? '';
$address = $data['Address'] ?? '';
$date_created = $data['DateCreated'] ?? '';
$customer_satisfaction_score = $data['CustomerSatisfactionScore'] ?? 0;
$user_id = uniqid('cust_');

try {
    $stmt = $pdo->prepare("INSERT INTO customers (user_id, FirstName, LastName, Email, Phone, Address, DateCreated, CustomerSatisfactionScore) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->execute([$user_id, $first_name, $last_name, $email, $phone, $address, $customer_type, $date_created, $customer_satisfaction_score]);
    echo json_encode(['success' => true, 'user_id' => $user_id]);
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>