<?php
require_manager();
require_once __DIR__ . '/../utils/pdf.php';

$db  = get_db();
$sub = $segments[1] ?? '';

function week_bounds(?string $week_start_str): array {
    if ($week_start_str) {
        $start = new DateTime($week_start_str);
    } else {
        $start = new DateTime();
        $dow = (int)$start->format('N'); // 1=Mon
        $start->modify('-' . ($dow - 1) . ' days');
    }
    $end = (clone $start)->modify('+6 days');
    return [$start->format('Y-m-d'), $end->format('Y-m-d')];
}

function fetch_sales_between(PDO $db, string $sd, string $ed): array {
    $stmt = $db->prepare(
        'SELECT s.*, p.name AS product_name, u.username AS sold_by_name
         FROM sales s JOIN products p ON s.product_id=p.id JOIN users u ON s.sold_by=u.id
         WHERE s.date BETWEEN ? AND ? ORDER BY s.date'
    );
    $stmt->execute([$sd, $ed]);
    return $stmt->fetchAll();
}

function sales_summary(PDO $db, string $where, array $params): array {
    $stmt = $db->prepare("SELECT COALESCE(SUM(paid),0), COALESCE(SUM(discount),0), COUNT(*) FROM sales WHERE $where");
    $stmt->execute($params);
    return $stmt->fetch(PDO::FETCH_NUM);
}

$action = $segments[2] ?? ''; // 'pdf' or empty

// ---- PDF exports (must be checked BEFORE JSON endpoints) ----

function send_pdf(string $bytes, string $filename): void {
    header('Content-Type: application/pdf');
    header('Content-Disposition: attachment; filename="' . $filename . '"');
    header('Content-Length: ' . strlen($bytes));
    echo $bytes;
    exit;
}

// GET /reports/daily/pdf
if ($method === 'GET' && $sub === 'daily' && $action === 'pdf') {
    $d     = $_GET['date'] ?? date('Y-m-d');
    $sales = fetch_sales_between($db, $d, $d);
    $pdf   = generate_sales_pdf($sales, 'Daily Sales Report', "Date: $d");
    send_pdf($pdf, "sales_daily_$d.pdf");
}

// GET /reports/weekly/pdf
if ($method === 'GET' && $sub === 'weekly' && $action === 'pdf') {
    [$ws, $we] = week_bounds($_GET['week_start'] ?? null);
    $sales = fetch_sales_between($db, $ws, $we);
    $pdf   = generate_sales_pdf($sales, 'Weekly Sales Report', "Week: $ws to $we");
    send_pdf($pdf, "sales_weekly_$ws.pdf");
}

// GET /reports/monthly/pdf
if ($method === 'GET' && $sub === 'monthly' && $action === 'pdf') {
    $month = (int)($_GET['month'] ?? date('n'));
    $year  = (int)($_GET['year']  ?? date('Y'));
    $sd    = "$year-" . str_pad($month, 2, '0', STR_PAD_LEFT) . '-01';
    $ed    = date('Y-m-t', mktime(0, 0, 0, $month, 1, $year));
    $sales = fetch_sales_between($db, $sd, $ed);
    $pdf   = generate_sales_pdf($sales, 'Monthly Sales Report', "Month: $year-" . str_pad($month, 2, '0', STR_PAD_LEFT));
    send_pdf($pdf, "sales_monthly_{$year}_" . str_pad($month, 2, '0', STR_PAD_LEFT) . ".pdf");
}

// GET /reports/stock-movement/pdf
if ($method === 'GET' && $sub === 'stock-movement' && $action === 'pdf') {
    $q = 'SELECT sm.*, p.name AS product_name FROM stock_movements sm JOIN products p ON sm.product_id=p.id';
    $params = []; $conditions = [];
    if (!empty($_GET['start_date'])) { $conditions[] = 'sm.date >= ?'; $params[] = $_GET['start_date']; }
    if (!empty($_GET['end_date']))   { $conditions[] = 'sm.date <= ?'; $params[] = $_GET['end_date']; }
    if ($conditions) $q .= ' WHERE ' . implode(' AND ', $conditions);
    $q .= ' ORDER BY sm.date DESC';
    $stmt = $db->prepare($q); $stmt->execute($params);
    $pdf = generate_stock_pdf($stmt->fetchAll(), 'Stock Movement Report',
        ($_GET['start_date'] ?? 'All') . ' to ' . ($_GET['end_date'] ?? 'Today'));
    send_pdf($pdf, 'stock_movement.pdf');
}

// GET /reports/stock-balance/pdf
if ($method === 'GET' && $sub === 'stock-balance' && $action === 'pdf') {
    $products = $db->query('SELECT * FROM products WHERE is_active=1 ORDER BY name')->fetchAll();
    $balances = array_map(fn($p) => [
        'product_name'  => $p['name'],
        'unit_price'    => (float)$p['unit_price'],
        'current_stock' => current_stock((int)$p['id']),
        'stock_value'   => current_stock((int)$p['id']) * (float)$p['unit_price'],
    ], $products);
    send_pdf(generate_stock_balance_pdf($balances), 'stock_balance.pdf');
}

// ---- JSON endpoints ----

// GET /reports/daily?date=YYYY-MM-DD
if ($method === 'GET' && $sub === 'daily') {
    $d = $_GET['date'] ?? date('Y-m-d');
    $sales = fetch_sales_between($db, $d, $d);
    [$rev, $disc, $cnt] = sales_summary($db, 'date = ?', [$d]);
    json_success([
        'date'               => $d,
        'sales'              => $sales,
        'total_revenue'      => (float)$rev,
        'total_discounts'    => (float)$disc,
        'total_transactions' => (int)$cnt,
    ]);
}

// GET /reports/weekly?week_start=YYYY-MM-DD
if ($method === 'GET' && $sub === 'weekly') {
    [$ws, $we] = week_bounds($_GET['week_start'] ?? null);
    $sales = fetch_sales_between($db, $ws, $we);
    [$rev, $disc, $cnt] = sales_summary($db, 'date BETWEEN ? AND ?', [$ws, $we]);
    json_success([
        'week_start'         => $ws,
        'week_end'           => $we,
        'sales'              => $sales,
        'total_revenue'      => (float)$rev,
        'total_discounts'    => (float)$disc,
        'total_transactions' => (int)$cnt,
    ]);
}

// GET /reports/monthly?month=3&year=2026
if ($method === 'GET' && $sub === 'monthly') {
    $month = (int)($_GET['month'] ?? date('n'));
    $year  = (int)($_GET['year']  ?? date('Y'));
    $sales = fetch_sales_between($db,
        "$year-" . str_pad($month, 2, '0', STR_PAD_LEFT) . '-01',
        date('Y-m-t', mktime(0, 0, 0, $month, 1, $year))
    );
    [$rev, $disc, $cnt] = sales_summary($db, 'MONTH(date)=? AND YEAR(date)=?', [$month, $year]);
    json_success([
        'month'              => $month,
        'year'               => $year,
        'sales'              => $sales,
        'total_revenue'      => (float)$rev,
        'total_discounts'    => (float)$disc,
        'total_transactions' => (int)$cnt,
    ]);
}

// GET /reports/sales-summary?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
if ($method === 'GET' && $sub === 'sales-summary') {
    $sd = $_GET['start_date'] ?? date('Y-m-d');
    $ed = $_GET['end_date']   ?? date('Y-m-d');

    $stmt = $db->prepare(
        'SELECT date,
                SUM(total_amount) AS total,
                SUM(cash_paid)    AS cash_paid,
                SUM(debt)         AS debt,
                COUNT(*)          AS entries
         FROM daily_sales
         WHERE date BETWEEN ? AND ?
         GROUP BY date ORDER BY date ASC'
    );
    $stmt->execute([$sd, $ed]);
    $rows = $stmt->fetchAll();

    $grand_total = array_sum(array_column($rows, 'total'));
    $grand_cash  = array_sum(array_column($rows, 'cash_paid'));
    $grand_debt  = array_sum(array_column($rows, 'debt'));

    json_success([
        'start_date'  => $sd,
        'end_date'    => $ed,
        'days'        => array_map(fn($r) => [
            'date'      => $r['date'],
            'total'     => (float)$r['total'],
            'cash_paid' => (float)$r['cash_paid'],
            'debt'      => (float)$r['debt'],
            'entries'   => (int)$r['entries'],
        ], $rows),
        'grand_total' => (float)$grand_total,
        'grand_cash'  => (float)$grand_cash,
        'grand_debt'  => (float)$grand_debt,
    ]);
}

// ---- Debt Reports ----

function fetch_debts_between(PDO $db, string $sd, string $ed): array {
    $stmt = $db->prepare(
        'SELECT d.*, p.name AS product_name
         FROM debts d LEFT JOIN products p ON d.product_id=p.id
         WHERE d.date BETWEEN ? AND ? ORDER BY d.date'
    );
    $stmt->execute([$sd, $ed]);
    return $stmt->fetchAll();
}

function debt_summary(PDO $db, string $where, array $params): array {
    $stmt = $db->prepare("
        SELECT 
            COALESCE(SUM(total_amount),0) AS total_debt,
            COALESCE(SUM(amount_paid),0) AS total_paid,
            COALESCE(SUM(total_amount - amount_paid),0) AS outstanding,
            COUNT(*) AS debt_count
        FROM debts WHERE $where
    ");
    $stmt->execute($params);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

// GET /reports/debts/daily?date=YYYY-MM-DD
if ($method === 'GET' && $sub === 'debts' && ($segments[2] ?? '') === 'daily') {
    $d = $_GET['date'] ?? date('Y-m-d');
    $debts = fetch_debts_between($db, $d, $d);
    $summary = debt_summary($db, 'date = ?', [$d]);
    json_success([
        'date'                => $d,
        'debts'               => $debts,
        'total_debt_created'  => (float)$summary['total_debt'],
        'total_paid'          => (float)$summary['total_paid'],
        'outstanding_balance' => (float)$summary['outstanding'],
        'debt_count'          => (int)$summary['debt_count'],
    ]);
}

// GET /reports/debts/weekly?week_start=YYYY-MM-DD
if ($method === 'GET' && $sub === 'debts' && ($segments[2] ?? '') === 'weekly') {
    [$ws, $we] = week_bounds($_GET['week_start'] ?? null);
    $debts = fetch_debts_between($db, $ws, $we);
    $summary = debt_summary($db, 'date BETWEEN ? AND ?', [$ws, $we]);
    json_success([
        'week_start'          => $ws,
        'week_end'            => $we,
        'debts'               => $debts,
        'total_debt_created'  => (float)$summary['total_debt'],
        'total_paid'          => (float)$summary['total_paid'],
        'outstanding_balance' => (float)$summary['outstanding'],
        'debt_count'          => (int)$summary['debt_count'],
    ]);
}

// GET /reports/debts/monthly?month=3&year=2026
if ($method === 'GET' && $sub === 'debts' && ($segments[2] ?? '') === 'monthly') {
    $month = (int)($_GET['month'] ?? date('n'));
    $year  = (int)($_GET['year']  ?? date('Y'));
    $sd    = "$year-" . str_pad($month, 2, '0', STR_PAD_LEFT) . '-01';
    $ed    = date('Y-m-t', mktime(0, 0, 0, $month, 1, $year));
    $debts = fetch_debts_between($db, $sd, $ed);
    $summary = debt_summary($db, 'MONTH(date)=? AND YEAR(date)=?', [$month, $year]);
    json_success([
        'month'               => $month,
        'year'                => $year,
        'debts'               => $debts,
        'total_debt_created'  => (float)$summary['total_debt'],
        'total_paid'          => (float)$summary['total_paid'],
        'outstanding_balance' => (float)$summary['outstanding'],
        'debt_count'          => (int)$summary['debt_count'],
    ]);
}

json_error('Not found', 404);
