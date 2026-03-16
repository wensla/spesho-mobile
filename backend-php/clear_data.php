<?php
/**
 * Clear all transactional data from spesho_db.
 * Keeps: users, products
 * Clears: debt_payments, debts, stock_movements, sale_items, sales
 */
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/db.php';

$db = get_db();

$db->exec('SET FOREIGN_KEY_CHECKS = 0');

$tables = ['debt_payments', 'debts', 'sales', 'stock_movements'];
foreach ($tables as $t) {
    $db->exec("TRUNCATE TABLE `$t`");
    echo "Cleared: $t\n";
}

$db->exec('SET FOREIGN_KEY_CHECKS = 1');

echo "\nAll transactional data cleared. Users and products kept.\n";
