<?php
$user = require_auth();
$db   = get_db();
$id   = isset($segments[1]) && is_numeric($segments[1]) ? (int)$segments[1] : null;

function sale_row(array $s): array {
    return [
        'id'           => (int)$s['id'],
        'product_id'   => (int)$s['product_id'],
        'product_name' => $s['product_name'] ?? null,
        'quantity'     => (float)$s['quantity'],
        'price'        => (float)$s['price'],
        'discount'     => (float)($s['discount'] ?? 0),
        'total'        => (float)$s['total'],
        'note'         => $s['note'],
        'sold_by'      => (int)$s['sold_by'],
        'sold_by_name' => $s['sold_by_name'] ?? null,
        'date'         => $s['date'],
        'created_at'   => $s['created_at'],
    ];
}

// POST /sales/
if ($method === 'POST' && $id === null) {
    $data = get_json_body();
    foreach (['product_id', 'quantity', 'price'] as $f) {
        if (!isset($data[$f])) json_error("$f is required", 400);
    }
    $price    = (float)$data['price'];
    $discount = (float)($data['discount'] ?? 0);
    $quantity = (float)$data['quantity'];
    if ($price <= 0) json_error('price must be greater than zero', 400);
    if ($discount < 0) json_error('discount cannot be negative', 400);
    if ($quantity <= 0) json_error('Quantity must be positive', 400);

    $product_id = (int)$data['product_id'];
    $stmt = $db->prepare('SELECT * FROM products WHERE id = ? AND is_active = 1');
    $stmt->execute([$product_id]);
    $product = $stmt->fetch();
    if (!$product) json_error('Product not found', 404);

    $stock = current_stock($product_id);
    if ($stock < $quantity) {
        json_error("Insufficient stock. Available: $stock, Requested: $quantity", 400);
    }

    $total     = ($quantity * $price) - $discount;
    $sale_date = !empty($data['date']) ? $data['date'] : date('Y-m-d');
    $user_id   = (int)$user['id'];

    $db->beginTransaction();
    $db->prepare(
        'INSERT INTO sales (product_id, quantity, price, discount, total, note, sold_by, date)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
    )->execute([$product_id, $quantity, $price, $discount, $total, $data['note'] ?? '', $user_id, $sale_date]);
    $sale_id = (int)$db->lastInsertId();

    $db->prepare(
        'INSERT INTO stock_movements (product_id, quantity_in, quantity_out, unit_price, note, movement_type, created_by, date)
         VALUES (?, 0, ?, ?, ?, "out", ?, ?)'
    )->execute([$product_id, $quantity, $price, "Sale #$sale_id", $user_id, $sale_date]);

    $db->commit();

    $s = $db->prepare(
        'SELECT s.*, p.name AS product_name, u.username AS sold_by_name
         FROM sales s JOIN products p ON s.product_id=p.id JOIN users u ON s.sold_by=u.id
         WHERE s.id = ?'
    );
    $s->execute([$sale_id]);
    json_success([
        'message'     => 'Sale recorded successfully',
        'sale'        => sale_row($s->fetch()),
        'new_balance' => current_stock($product_id),
    ], 201);
}

// GET /sales/
if ($method === 'GET' && $id === null) {
    $page     = max(1, (int)($_GET['page'] ?? 1));
    $per_page = min(200, (int)($_GET['per_page'] ?? 50));
    $offset   = ($page - 1) * $per_page;

    $where  = [];
    $params = [];

    if ($user['role'] === 'salesperson') {
        $where[]  = 's.sold_by = ?';
        $params[] = $user['id'];
    }
    if (!empty($_GET['product_id'])) {
        $where[]  = 's.product_id = ?';
        $params[] = (int)$_GET['product_id'];
    }
    if (!empty($_GET['start_date'])) {
        $where[]  = 's.date >= ?';
        $params[] = $_GET['start_date'];
    }
    if (!empty($_GET['end_date'])) {
        $where[]  = 's.date <= ?';
        $params[] = $_GET['end_date'];
    }

    $where_sql = $where ? 'WHERE ' . implode(' AND ', $where) : '';

    $count_stmt = $db->prepare("SELECT COUNT(*) FROM sales s $where_sql");
    $count_stmt->execute($params);
    $total = (int)$count_stmt->fetchColumn();

    $stmt = $db->prepare(
        "SELECT s.*, p.name AS product_name, u.username AS sold_by_name
         FROM sales s JOIN products p ON s.product_id=p.id JOIN users u ON s.sold_by=u.id
         $where_sql ORDER BY s.created_at DESC LIMIT ? OFFSET ?"
    );
    $stmt->execute(array_merge($params, [$per_page, $offset]));
    $sales = array_map('sale_row', $stmt->fetchAll());

    json_success([
        'sales' => $sales,
        'total' => $total,
        'pages' => (int)ceil($total / $per_page),
        'page'  => $page,
    ]);
}

// GET /sales/{id}
if ($method === 'GET' && $id !== null) {
    $stmt = $db->prepare(
        'SELECT s.*, p.name AS product_name, u.username AS sold_by_name
         FROM sales s JOIN products p ON s.product_id=p.id JOIN users u ON s.sold_by=u.id
         WHERE s.id = ?'
    );
    $stmt->execute([$id]);
    $s = $stmt->fetch();
    if (!$s) json_error('Sale not found', 404);
    json_success(['sale' => sale_row($s)]);
}

json_error('Not found', 404);
