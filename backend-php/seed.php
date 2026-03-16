<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/db.php';

$db   = get_db();
$hash = password_hash('admin123', PASSWORD_BCRYPT);

$existing = $db->prepare('SELECT id FROM users WHERE username = ?');
$existing->execute(['admin']);

if ($existing->fetch()) {
    echo "Admin user already exists.\n";
} else {
    $db->prepare(
        'INSERT INTO users (username, password_hash, role, full_name) VALUES (?, ?, "manager", "Administrator")'
    )->execute(['admin', $hash]);
    echo "Admin user created: admin / admin123\n";
}
