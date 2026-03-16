<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/auth.php';

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
// Strip /api prefix if present
$uri = preg_replace('#^/api#', '', $uri);
$uri = rtrim($uri, '/') ?: '/';

$method = $_SERVER['REQUEST_METHOD'];
$segments = explode('/', trim($uri, '/'));
$resource = $segments[0] ?? '';

switch ($resource) {
    case 'auth':     require __DIR__ . '/routes/auth.php';      break;
    case 'products': require __DIR__ . '/routes/products.php';  break;
    case 'sales':    require __DIR__ . '/routes/sales.php';     break;
    case 'stock':    require __DIR__ . '/routes/stock.php';     break;
    case 'dashboard':require __DIR__ . '/routes/dashboard.php'; break;
    case 'users':    require __DIR__ . '/routes/users.php';     break;
    case 'reports':  require __DIR__ . '/routes/reports.php';   break;
    case 'debts':       require __DIR__ . '/routes/debts.php';        break;
    case 'daily-sales': require __DIR__ . '/routes/daily_sales.php'; break;
    default:
        http_response_code(404);
        echo json_encode(['error' => 'Not found']);
}
