<?php
$current_user = require_manager();
$db = get_db();
$id = isset($segments[1]) && is_numeric($segments[1]) ? (int)$segments[1] : null;

function user_row(array $u): array {
    return [
        'id'         => (int)$u['id'],
        'username'   => $u['username'],
        'role'       => $u['role'],
        'full_name'  => $u['full_name'],
        'is_active'  => (bool)$u['is_active'],
        'created_at' => $u['created_at'],
    ];
}

// GET /users/
if ($method === 'GET' && $id === null) {
    $users = $db->query('SELECT * FROM users ORDER BY created_at DESC')->fetchAll();
    json_success(['users' => array_map('user_row', $users)]);
}

// POST /users/
if ($method === 'POST' && $id === null) {
    $data = get_json_body();
    foreach (['username', 'password', 'role'] as $f) {
        if (empty($data[$f])) json_error("$f is required", 400);
    }
    $username = trim($data['username']);
    if (strlen($username) < 3) json_error('username must be at least 3 characters', 400);
    if (strlen($data['password']) < 6) json_error('password must be at least 6 characters', 400);
    if (!in_array($data['role'], ['manager', 'salesperson'])) {
        json_error('Role must be manager or salesperson', 400);
    }
    $chk = $db->prepare('SELECT id FROM users WHERE username = ?');
    $chk->execute([$username]);
    if ($chk->fetch()) json_error('Username already exists', 409);

    $hash = password_hash($data['password'], PASSWORD_BCRYPT);
    $db->prepare(
        'INSERT INTO users (username, password_hash, role, full_name) VALUES (?, ?, ?, ?)'
    )->execute([$username, $hash, $data['role'], $data['full_name'] ?? '']);
    $new_id = (int)$db->lastInsertId();
    $stmt = $db->prepare('SELECT * FROM users WHERE id = ?');
    $stmt->execute([$new_id]);
    json_success(['user' => user_row($stmt->fetch())], 201);
}

// PUT /users/{id}
if ($method === 'PUT' && $id !== null) {
    $stmt = $db->prepare('SELECT * FROM users WHERE id = ?');
    $stmt->execute([$id]);
    $u = $stmt->fetch();
    if (!$u) json_error('User not found', 404);

    $data = get_json_body();
    $full_name = $data['full_name'] ?? $u['full_name'];
    $role      = isset($data['role']) && in_array($data['role'], ['manager','salesperson'])
                    ? $data['role'] : $u['role'];
    $is_active = isset($data['is_active']) ? (int)(bool)$data['is_active'] : $u['is_active'];

    $db->prepare('UPDATE users SET full_name=?, role=?, is_active=? WHERE id=?')
       ->execute([$full_name, $role, $is_active, $id]);

    if (!empty($data['password'])) {
        $hash = password_hash($data['password'], PASSWORD_BCRYPT);
        $db->prepare('UPDATE users SET password_hash=? WHERE id=?')->execute([$hash, $id]);
    }
    $stmt2 = $db->prepare('SELECT * FROM users WHERE id = ?');
    $stmt2->execute([$id]);
    json_success(['user' => user_row($stmt2->fetch())]);
}

// DELETE /users/{id}
if ($method === 'DELETE' && $id !== null) {
    if ($id === (int)$current_user['id']) json_error('Cannot delete yourself', 400);
    $db->prepare('UPDATE users SET is_active = 0 WHERE id = ?')->execute([$id]);
    json_success(['message' => 'User deactivated']);
}

json_error('Not found', 404);
