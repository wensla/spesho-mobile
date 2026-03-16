<?php
$user = require_auth();
$db   = get_db();
$id   = isset($segments[1]) && is_numeric($segments[1]) ? (int)$segments[1] : null;

function product_row(array $p, bool $stock = false): array {
    $row = [
        'id'           => (int)$p['id'],
        'name'         => $p['name'],
        'unit_price'   => (float)$p['unit_price'],
        'package_size' => (int)($p['package_size'] ?? 5),
        'is_active'    => (bool)$p['is_active'],
        'created_at'   => $p['created_at'],
    ];
    if ($stock) {
        $row['current_stock'] = current_stock((int)$p['id']);
    }
    return $row;
}

// GET /products/
if ($method === 'GET' && $id === null) {
    $include_stock = ($_GET['include_stock'] ?? 'false') === 'true';
    $stmt = $db->query('SELECT * FROM products WHERE is_active = 1 ORDER BY name');
    $products = array_map(fn($p) => product_row($p, $include_stock), $stmt->fetchAll());
    json_success(['products' => $products]);
}

// GET /products/{id}
if ($method === 'GET' && $id !== null) {
    $stmt = $db->prepare('SELECT * FROM products WHERE id = ?');
    $stmt->execute([$id]);
    $p = $stmt->fetch();
    if (!$p) json_error('Product not found', 404);
    json_success(['product' => product_row($p, true)]);
}

// POST /products/
if ($method === 'POST' && $id === null) {
    require_manager();
    $data = get_json_body();
    $name = trim($data['name'] ?? '');
    if (!$name) json_error('name is required', 400);
    if (!isset($data['unit_price'])) json_error('unit_price is required', 400);
    $price = (float)$data['unit_price'];
    if ($price <= 0) json_error('unit_price must be greater than zero', 400);
    $package_size = isset($data['package_size']) ? (int)$data['package_size'] : 5;
    if (!in_array($package_size, [5, 10, 25])) $package_size = 5;

    $check = $db->prepare('SELECT id FROM products WHERE name = ?');
    $check->execute([$name]);
    if ($check->fetch()) json_error('Product name already exists', 409);

    $stmt = $db->prepare(
        'INSERT INTO products (name, unit_price, package_size) VALUES (?, ?, ?)'
    );
    $stmt->execute([$name, $price, $package_size]);
    $new_id = (int)$db->lastInsertId();
    $stmt2 = $db->prepare('SELECT * FROM products WHERE id = ?');
    $stmt2->execute([$new_id]);
    json_success(['product' => product_row($stmt2->fetch())], 201);
}

// PUT /products/{id}
if ($method === 'PUT' && $id !== null) {
    require_manager();
    $stmt = $db->prepare('SELECT * FROM products WHERE id = ?');
    $stmt->execute([$id]);
    $p = $stmt->fetch();
    if (!$p) json_error('Product not found', 404);

    $data  = get_json_body();
    $name  = isset($data['name']) ? trim($data['name']) : $p['name'];
    if (!$name) json_error('name cannot be empty', 400);
    $price = isset($data['unit_price']) ? (float)$data['unit_price'] : (float)$p['unit_price'];
    if ($price <= 0) json_error('unit_price must be greater than zero', 400);
    $package_size = isset($data['package_size']) ? (int)$data['package_size'] : (int)($p['package_size'] ?? 5);
    if (!in_array($package_size, [5, 10, 25])) $package_size = (int)($p['package_size'] ?? 5);

    $db->prepare('UPDATE products SET name=?, unit_price=?, package_size=? WHERE id=?')
       ->execute([$name, $price, $package_size, $id]);

    $stmt3 = $db->prepare('SELECT * FROM products WHERE id = ?');
    $stmt3->execute([$id]);
    json_success(['product' => product_row($stmt3->fetch())]);
}

// DELETE /products/{id}
if ($method === 'DELETE' && $id !== null) {
    require_manager();
    $db->prepare('UPDATE products SET is_active = 0 WHERE id = ?')->execute([$id]);
    json_success(['message' => 'Product deleted']);
}

json_error('Not found', 404);
