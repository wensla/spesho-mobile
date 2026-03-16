<?php
$user = require_auth();
$db   = get_db();
$sub  = $segments[1] ?? '';

function movement_row(array $m): array {
    return [
        'id'            => (int)$m['id'],
        'product_id'    => (int)$m['product_id'],
        'product_name'  => $m['product_name'] ?? null,
        'quantity_in'   => (float)($m['quantity_in'] ?? 0),
        'quantity_out'  => (float)($m['quantity_out'] ?? 0),
        'unit_price'    => $m['unit_price'] !== null ? (float)$m['unit_price'] : null,
        'note'          => $m['note'],
        'movement_type' => $m['movement_type'],
        'created_by'    => $m['created_by'] ? (int)$m['created_by'] : null,
        'date'          => $m['date'],
        'created_at'    => $m['created_at'],
    ];
}

// POST /stock/in
if ($method === 'POST' && $sub === 'in') {
    require_manager();
    $data = get_json_body();
    foreach (['product_id', 'quantity', 'unit_price'] as $f) {
        if (!isset($data[$f])) json_error("$f is required", 400);
    }
    $qty   = (float)$data['quantity'];
    $price = (float)$data['unit_price'];
    if ($qty <= 0)   json_error('Quantity must be positive', 400);
    if ($price <= 0) json_error('unit_price must be greater than zero', 400);

    $pid = (int)$data['product_id'];
    $stmt = $db->prepare('SELECT id FROM products WHERE id = ? AND is_active = 1');
    $stmt->execute([$pid]);
    if (!$stmt->fetch()) json_error('Product not found', 404);

    $mov_date = !empty($data['date']) ? $data['date'] : date('Y-m-d');
    $db->prepare(
        'INSERT INTO stock_movements (product_id, quantity_in, quantity_out, unit_price, note, movement_type, created_by, date)
         VALUES (?, ?, 0, ?, ?, "in", ?, ?)'
    )->execute([$pid, $qty, $price, $data['note'] ?? '', $user['id'], $mov_date]);

    $mov_id = (int)$db->lastInsertId();
    $s = $db->prepare(
        'SELECT sm.*, p.name AS product_name FROM stock_movements sm
         JOIN products p ON sm.product_id=p.id WHERE sm.id=?'
    );
    $s->execute([$mov_id]);
    json_success([
        'message'     => 'Stock added successfully',
        'movement'    => movement_row($s->fetch()),
        'new_balance' => current_stock($pid),
    ], 201);
}

// GET /stock/balance
if ($method === 'GET' && $sub === 'balance') {
    $stmt = $db->query('SELECT * FROM products WHERE is_active = 1 ORDER BY name');
    $balances = [];
    foreach ($stmt->fetchAll() as $p) {
        $stock = current_stock((int)$p['id']);
        $balances[] = [
            'product_id'   => (int)$p['id'],
            'product_name' => $p['name'],
            'unit_price'   => (float)$p['unit_price'],
            'package_size' => (int)($p['package_size'] ?? 5),
            'current_stock'=> $stock,
            'stock_value'  => $stock * (float)$p['unit_price'] / max(1, (int)($p['package_size'] ?? 5)),
        ];
    }
    json_success(['balances' => $balances]);
}

// GET /stock/movements
if ($method === 'GET' && $sub === 'movements') {
    $page     = max(1, (int)($_GET['page'] ?? 1));
    $per_page = min(200, (int)($_GET['per_page'] ?? 50));
    $offset   = ($page - 1) * $per_page;

    $where = []; $params = [];
    if (!empty($_GET['product_id'])) { $where[] = 'sm.product_id = ?'; $params[] = (int)$_GET['product_id']; }
    if (!empty($_GET['type']))        { $where[] = 'sm.movement_type = ?'; $params[] = $_GET['type']; }
    if (!empty($_GET['start_date']))  { $where[] = 'sm.date >= ?'; $params[] = $_GET['start_date']; }
    if (!empty($_GET['end_date']))    { $where[] = 'sm.date <= ?'; $params[] = $_GET['end_date']; }

    $where_sql = $where ? 'WHERE ' . implode(' AND ', $where) : '';

    $count = $db->prepare("SELECT COUNT(*) FROM stock_movements sm $where_sql");
    $count->execute($params);
    $total = (int)$count->fetchColumn();

    $stmt = $db->prepare(
        "SELECT sm.*, p.name AS product_name FROM stock_movements sm
         JOIN products p ON sm.product_id=p.id $where_sql
         ORDER BY sm.created_at DESC LIMIT ? OFFSET ?"
    );
    $stmt->execute(array_merge($params, [$per_page, $offset]));

    json_success([
        'movements' => array_map('movement_row', $stmt->fetchAll()),
        'total'     => $total,
        'pages'     => (int)ceil($total / $per_page),
        'page'      => $page,
    ]);
}

json_error('Not found', 404);
