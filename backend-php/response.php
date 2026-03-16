<?php
function json_success(array $data, int $code = 200): void {
    http_response_code($code);
    echo json_encode($data);
    exit;
}

function json_error(string $message, int $code = 400): void {
    http_response_code($code);
    echo json_encode(['error' => $message]);
    exit;
}

function get_json_body(): array {
    $body = file_get_contents('php://input');
    return json_decode($body, true) ?? [];
}

function current_stock(int $product_id): float {
    $db = get_db();
    $stmt = $db->prepare(
        'SELECT COALESCE(SUM(quantity_in),0) - COALESCE(SUM(quantity_out),0)
         FROM stock_movements WHERE product_id = ?'
    );
    $stmt->execute([$product_id]);
    return (float)$stmt->fetchColumn();
}
