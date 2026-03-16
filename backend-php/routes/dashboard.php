<?php
require_manager();
$db    = get_db();
$today = date('Y-m-d');
$month = date('n');
$year  = date('Y');

// Today's sales
$s1 = $db->prepare('SELECT COALESCE(SUM(total),0) FROM sales WHERE date = ?');
$s1->execute([$today]);
$today_sales = (float)$s1->fetchColumn();

// This week's sales (Mon–Sun)
$s_week = $db->prepare(
    'SELECT COALESCE(SUM(total),0) FROM sales
     WHERE YEARWEEK(date, 1) = YEARWEEK(CURDATE(), 1)'
);
$s_week->execute();
$week_sales = (float)$s_week->fetchColumn();

// This month's sales
$s2 = $db->prepare('SELECT COALESCE(SUM(total),0) FROM sales WHERE MONTH(date)=? AND YEAR(date)=?');
$s2->execute([$month, $year]);
$month_sales = (float)$s2->fetchColumn();

// This year's sales
$s_year = $db->prepare('SELECT COALESCE(SUM(total),0) FROM sales WHERE YEAR(date)=?');
$s_year->execute([$year]);
$year_sales = (float)$s_year->fetchColumn();

// This month's discounts
$s3 = $db->prepare('SELECT COALESCE(SUM(discount),0) FROM sales WHERE MONTH(date)=? AND YEAR(date)=?');
$s3->execute([$month, $year]);
$month_discounts = (float)$s3->fetchColumn();

// Debt summary
$d1 = $db->query("SELECT COUNT(*) FROM debts WHERE status IN ('pending','partial')");
$total_debtors = (int)$d1->fetchColumn();

$d2 = $db->query('SELECT COALESCE(SUM(total_amount - amount_paid),0) FROM debts');
$total_outstanding = (float)$d2->fetchColumn();

$d3 = $db->query('SELECT COALESCE(SUM(amount_paid),0) FROM debts');
$total_debt_collected = (float)$d3->fetchColumn();

// Stock value + total kg
$products = $db->query('SELECT id, unit_price, package_size FROM products WHERE is_active = 1')->fetchAll();
$total_stock_value = 0;
$total_stock_kg    = 0;
$stock_levels = [];
foreach ($products as $p) {
    $name_q = $db->prepare('SELECT name FROM products WHERE id=?');
    $name_q->execute([$p['id']]);
    $pname = $name_q->fetchColumn();
    $stock = current_stock((int)$p['id']);
    $pkg_size = max(1, (int)($p['package_size'] ?? 5));
    $total_stock_value += $stock * (float)$p['unit_price'] / $pkg_size;
    $total_stock_kg    += $stock;
    $stock_levels[] = [
        'product' => $pname,
        'stock'   => $stock,
        'value'   => $stock * (float)$p['unit_price'] / $pkg_size,
    ];
}

// Daily graph for this month
$s4 = $db->prepare(
    'SELECT date, SUM(total) AS total, COUNT(*) AS count
     FROM sales WHERE MONTH(date)=? AND YEAR(date)=?
     GROUP BY date ORDER BY date'
);
$s4->execute([$month, $year]);
$graph_data = array_map(fn($r) => [
    'date'  => $r['date'],
    'total' => (float)$r['total'],
    'count' => (int)$r['count'],
], $s4->fetchAll());

json_success([
    'total_sales_today'     => $today_sales,
    'total_sales_week'      => $week_sales,
    'total_sales_month'     => $month_sales,
    'total_sales_year'      => $year_sales,
    'total_discounts_month' => $month_discounts,
    'total_debtors'         => $total_debtors,
    'total_outstanding'     => $total_outstanding,
    'total_debt_collected'  => $total_debt_collected,
    'total_stock_kg'        => $total_stock_kg,
    'total_stock_value'     => $total_stock_value,
    'sales_graph'           => $graph_data,
    'stock_levels'          => $stock_levels,
]);
