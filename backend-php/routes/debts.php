<?php
$user = require_auth();
$db   = get_db();
$id   = isset($segments[1]) && is_numeric($segments[1]) ? (int)$segments[1] : null;
$sub  = isset($segments[1]) && !is_numeric($segments[1]) ? $segments[1] : null;
$action = $segments[2] ?? ''; // 'payments'

function debt_row(array $d): array {
    return [
        'id'             => (int)$d['id'],
        'customer_name'  => $d['customer_name'],
        'customer_phone' => $d['customer_phone'],
        'product_id'     => $d['product_id'] !== null ? (int)$d['product_id'] : null,
        'product_name'   => $d['product_name'] ?? null,
        'quantity'       => $d['quantity'] !== null ? (float)$d['quantity'] : null,
        'unit_price'     => $d['unit_price'] !== null ? (float)$d['unit_price'] : null,
        'total_amount'   => (float)$d['total_amount'],
        'amount_paid'    => (float)($d['amount_paid'] ?? 0),
        'balance'        => (float)$d['total_amount'] - (float)($d['amount_paid'] ?? 0),
        'note'           => $d['note'],
        'date'           => $d['date'],
        'status'         => $d['status'],
        'created_by'     => $d['created_by'] ? (int)$d['created_by'] : null,
        'created_at'     => $d['created_at'],
    ];
}

function payment_row(array $p): array {
    return [
        'id'           => (int)$p['id'],
        'debt_id'      => (int)$p['debt_id'],
        'amount'       => (float)$p['amount'],
        'note'         => $p['note'],
        'payment_date' => $p['payment_date'],
        'recorded_by'  => $p['recorded_by'] ? (int)$p['recorded_by'] : null,
        'created_at'   => $p['created_at'],
    ];
}

function update_debt_status(PDO $db, int $debt_id): void {
    $stmt = $db->prepare('SELECT total_amount, amount_paid FROM debts WHERE id = ?');
    $stmt->execute([$debt_id]);
    $debt = $stmt->fetch();
    $total = (float)$debt['total_amount'];
    $paid  = (float)$debt['amount_paid'];
    $status = $paid <= 0 ? 'pending' : ($paid >= $total ? 'paid' : 'partial');
    $db->prepare('UPDATE debts SET status = ? WHERE id = ?')->execute([$status, $debt_id]);
}

// GET /debts/summary
if ($method === 'GET' && $sub === 'summary') {
    $s = $db->query(
        'SELECT
            COUNT(*) AS total_debts,
            COUNT(CASE WHEN status="pending" THEN 1 END) AS pending,
            COUNT(CASE WHEN status="partial" THEN 1 END) AS partial,
            COUNT(CASE WHEN status="paid" THEN 1 END) AS paid,
            COALESCE(SUM(total_amount),0) AS total_amount,
            COALESCE(SUM(amount_paid),0) AS total_paid,
            COALESCE(SUM(total_amount - amount_paid),0) AS total_balance
         FROM debts'
    )->fetch();
    json_success([
        'total_debts'   => (int)$s['total_debts'],
        'pending'       => (int)$s['pending'],
        'partial'       => (int)$s['partial'],
        'paid'          => (int)$s['paid'],
        'total_amount'  => (float)$s['total_amount'],
        'total_paid'    => (float)$s['total_paid'],
        'total_balance' => (float)$s['total_balance'],
    ]);
}

// GET /debts/
if ($method === 'GET' && $id === null && $sub === null) {
    $where = []; $params = [];
    if (!empty($_GET['status']))   { $where[] = 'd.status = ?';          $params[] = $_GET['status']; }
    if (!empty($_GET['customer'])) { $where[] = 'd.customer_name LIKE ?'; $params[] = '%' . $_GET['customer'] . '%'; }
    $w = $where ? 'WHERE ' . implode(' AND ', $where) : '';
    $stmt = $db->prepare(
        "SELECT d.*, p.name AS product_name
         FROM debts d LEFT JOIN products p ON d.product_id = p.id
         $w ORDER BY d.created_at DESC"
    );
    $stmt->execute($params);
    json_success(['debts' => array_map('debt_row', $stmt->fetchAll())]);
}

// POST /debts/ — create credit sale (deducts stock)
if ($method === 'POST' && $id === null && $sub === null) {
    $data = get_json_body();
    foreach (['customer_name', 'product_id', 'quantity', 'unit_price'] as $f) {
        if (empty($data[$f])) json_error("$f is required", 400);
    }
    $customer = trim($data['customer_name']);
    $pid      = (int)$data['product_id'];
    $qty      = (float)$data['quantity'];
    $price    = (float)$data['unit_price'];
    if ($qty <= 0)   json_error('quantity must be positive', 400);
    if ($price <= 0) json_error('unit_price must be greater than zero', 400);

    $stmt = $db->prepare('SELECT id FROM products WHERE id = ? AND is_active = 1');
    $stmt->execute([$pid]);
    if (!$stmt->fetch()) json_error('Product not found', 404);

    $stock = current_stock($pid);
    if ($stock < $qty) json_error("Insufficient stock. Available: $stock, Requested: $qty", 400);

    $total = $qty * $price;
    $ddate = !empty($data['date']) ? $data['date'] : date('Y-m-d');

    $db->beginTransaction();

    // Create debt record
    $db->prepare(
        'INSERT INTO debts (customer_name, customer_phone, product_id, quantity, unit_price, total_amount, note, date, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
    )->execute([$customer, $data['customer_phone'] ?? null, $pid, $qty, $price, $total,
                $data['note'] ?? null, $ddate, $user['id']]);
    $debt_id = (int)$db->lastInsertId();

    // Deduct stock movement
    $db->prepare(
        'INSERT INTO stock_movements (product_id, quantity_in, quantity_out, unit_price, note, movement_type, created_by, date)
         VALUES (?, 0, ?, ?, ?, "out", ?, ?)'
    )->execute([$pid, $qty, $price, "Credit sale to $customer (Debt #$debt_id)", $user['id'], $ddate]);

    $db->commit();

    $s = $db->prepare('SELECT d.*, p.name AS product_name FROM debts d LEFT JOIN products p ON d.product_id=p.id WHERE d.id=?');
    $s->execute([$debt_id]);
    json_success([
        'message'     => 'Credit sale recorded',
        'debt'        => debt_row($s->fetch()),
        'new_balance' => current_stock($pid),
    ], 201);
}

// POST /debts/from-sale — create debt linked to an already-recorded sale (no stock deduction)
// Used when a customer pays partially at time of sale; balance becomes a debt.
if ($method === 'POST' && $sub === 'from-sale') {
    $data = get_json_body();
    foreach (['customer_name', 'total_amount'] as $f) {
        if (empty($data[$f])) json_error("$f is required", 400);
    }
    $total  = (float)$data['total_amount'];
    $paid   = (float)($data['amount_paid'] ?? 0);
    if ($total <= 0)  json_error('total_amount must be positive', 400);
    if ($paid < 0)    json_error('amount_paid cannot be negative', 400);
    if ($paid > $total + 0.01) json_error('amount_paid cannot exceed total_amount', 400);

    $balance = $total - $paid;
    $status  = $paid <= 0 ? 'pending' : ($paid >= $total ? 'paid' : 'partial');
    $ddate   = !empty($data['date']) ? $data['date'] : date('Y-m-d');

    $db->beginTransaction();

    $db->prepare(
        'INSERT INTO debts (customer_name, customer_phone, product_id, quantity, unit_price,
                            total_amount, amount_paid, note, date, status, created_by)
         VALUES (?, ?, NULL, NULL, NULL, ?, ?, ?, ?, ?, ?)'
    )->execute([
        trim($data['customer_name']),
        $data['customer_phone'] ?? null,
        $total, $paid,
        $data['note'] ?? null,
        $ddate, $status,
        (int)$user['id'],
    ]);
    $debt_id = (int)$db->lastInsertId();

    // Record the initial payment if any
    if ($paid > 0) {
        $db->prepare(
            'INSERT INTO debt_payments (debt_id, amount, note, payment_date, recorded_by)
             VALUES (?, ?, ?, ?, ?)'
        )->execute([$debt_id, $paid, 'Initial payment at time of sale', $ddate, (int)$user['id']]);
    }

    $db->commit();

    $s = $db->prepare('SELECT d.*, NULL AS product_name FROM debts d WHERE d.id = ?');
    $s->execute([$debt_id]);
    json_success(['message' => 'Debt recorded', 'debt' => debt_row($s->fetch())], 201);
}

// GET /debts/{id}
if ($method === 'GET' && $id !== null && $action === '') {
    $s = $db->prepare('SELECT d.*, p.name AS product_name FROM debts d LEFT JOIN products p ON d.product_id=p.id WHERE d.id=?');
    $s->execute([$id]);
    $debt = $s->fetch();
    if (!$debt) json_error('Debt not found', 404);

    $ps = $db->prepare('SELECT * FROM debt_payments WHERE debt_id = ? ORDER BY payment_date DESC');
    $ps->execute([$id]);
    $payments = array_map('payment_row', $ps->fetchAll());

    json_success(['debt' => debt_row($debt), 'payments' => $payments]);
}

// POST /debts/{id}/payments — record a payment
if ($method === 'POST' && $id !== null && $action === 'payments') {
    $s = $db->prepare('SELECT * FROM debts WHERE id = ?');
    $s->execute([$id]);
    $debt = $s->fetch();
    if (!$debt) json_error('Debt not found', 404);

    $data   = get_json_body();
    $amount = (float)($data['amount'] ?? 0);
    if ($amount <= 0) json_error('amount must be greater than zero', 400);

    $balance = (float)$debt['total_amount'] - (float)$debt['amount_paid'];
    if ($amount > $balance + 0.01) {
        json_error("Payment ($amount) exceeds outstanding balance ($balance)", 400);
    }

    $pay_date = !empty($data['date']) ? $data['date'] : date('Y-m-d');

    $db->beginTransaction();

    $db->prepare(
        'INSERT INTO debt_payments (debt_id, amount, note, payment_date, recorded_by) VALUES (?, ?, ?, ?, ?)'
    )->execute([$id, $amount, $data['note'] ?? null, $pay_date, $user['id']]);

    $db->prepare('UPDATE debts SET amount_paid = amount_paid + ? WHERE id = ?')->execute([$amount, $id]);

    $db->commit();

    update_debt_status($db, $id);

    $s2 = $db->prepare('SELECT d.*, p.name AS product_name FROM debts d LEFT JOIN products p ON d.product_id=p.id WHERE d.id=?');
    $s2->execute([$id]);
    json_success(['message' => 'Payment recorded', 'debt' => debt_row($s2->fetch())], 201);
}

json_error('Not found', 404);
