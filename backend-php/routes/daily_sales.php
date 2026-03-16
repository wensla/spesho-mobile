<?php
$user = require_auth();
$db   = get_db();
$id   = isset($segments[1]) && is_numeric($segments[1]) ? (int)$segments[1] : null;

// Ensure table exists
$db->exec("CREATE TABLE IF NOT EXISTS daily_sales (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    date         DATE NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL,
    cash_paid    DECIMAL(15,2) NOT NULL DEFAULT 0,
    debt         DECIMAL(15,2) NOT NULL DEFAULT 0,
    note         TEXT,
    customer_name  VARCHAR(255),
    customer_phone VARCHAR(50),
    recorded_by  INT,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ds_user FOREIGN KEY (recorded_by) REFERENCES users(id)
)");

function ds_row(array $r): array {
    return [
        'id'              => (int)$r['id'],
        'date'            => $r['date'],
        'total_amount'    => (float)$r['total_amount'],
        'cash_paid'       => (float)$r['cash_paid'],
        'debt'            => (float)$r['debt'],
        'note'            => $r['note'],
        'customer_name'   => $r['customer_name'],
        'customer_phone'  => $r['customer_phone'],
        'recorded_by'     => $r['recorded_by'] ? (int)$r['recorded_by'] : null,
        'recorded_by_name'=> $r['recorded_by_name'] ?? null,
        'created_at'      => $r['created_at'],
    ];
}

// POST /daily-sales/
if ($method === 'POST' && $id === null) {
    $data = get_json_body();
    if (!isset($data['total_amount'])) json_error('total_amount is required', 400);

    $total = (float)$data['total_amount'];
    $paid  = isset($data['cash_paid']) ? (float)$data['cash_paid'] : $total;
    $debt  = max(0, $total - $paid);

    if ($total <= 0) json_error('total_amount must be positive', 400);
    if ($paid < 0)   json_error('cash_paid cannot be negative', 400);

    $sale_date = !empty($data['date']) ? $data['date'] : date('Y-m-d');

    $db->prepare(
        'INSERT INTO daily_sales (date, total_amount, cash_paid, debt, note, customer_name, customer_phone, recorded_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
    )->execute([
        $sale_date,
        $total,
        $paid,
        $debt,
        $data['note'] ?? null,
        $debt > 0 ? ($data['customer_name'] ?? null) : null,
        $debt > 0 ? ($data['customer_phone'] ?? null) : null,
        (int)$user['id'],
    ]);

    $new_id = (int)$db->lastInsertId();
    $s = $db->prepare(
        'SELECT ds.*, u.username AS recorded_by_name
         FROM daily_sales ds LEFT JOIN users u ON ds.recorded_by = u.id
         WHERE ds.id = ?'
    );
    $s->execute([$new_id]);
    json_success(['message' => 'Sale recorded successfully', 'sale' => ds_row($s->fetch())], 201);
}

// GET /daily-sales/
if ($method === 'GET' && $id === null) {
    $where = []; $params = [];
    if (!empty($_GET['start_date'])) { $where[] = 'ds.date >= ?'; $params[] = $_GET['start_date']; }
    if (!empty($_GET['end_date']))   { $where[] = 'ds.date <= ?'; $params[] = $_GET['end_date']; }
    $where_sql = $where ? 'WHERE ' . implode(' AND ', $where) : '';

    $stmt = $db->prepare(
        "SELECT ds.*, u.username AS recorded_by_name
         FROM daily_sales ds LEFT JOIN users u ON ds.recorded_by = u.id
         $where_sql ORDER BY ds.date DESC, ds.created_at DESC"
    );
    $stmt->execute($params);
    json_success(['sales' => array_map('ds_row', $stmt->fetchAll())]);
}

// DELETE /daily-sales/{id}
if ($method === 'DELETE' && $id !== null) {
    require_manager();
    $db->prepare('DELETE FROM daily_sales WHERE id = ?')->execute([$id]);
    json_success(['message' => 'Deleted']);
}

json_error('Not found', 404);
