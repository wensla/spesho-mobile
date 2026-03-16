<?php
// $segments[1] => sub-route
$sub = $segments[1] ?? '';

if ($method === 'POST' && $sub === 'login') {
    $data = get_json_body();
    if (empty($data['username']) || empty($data['password'])) {
        json_error('Username and password required', 400);
    }
    $db = get_db();
    $stmt = $db->prepare('SELECT * FROM users WHERE username = ? AND is_active = 1');
    $stmt->execute([trim($data['username'])]);
    $user = $stmt->fetch();
    if (!$user || !password_verify($data['password'], $user['password_hash'])) {
        json_error('Invalid credentials', 401);
    }
    $token = jwt_create((int)$user['id']);
    json_success([
        'access_token' => $token,
        'user' => [
            'id'        => (int)$user['id'],
            'username'  => $user['username'],
            'role'      => $user['role'],
            'full_name' => $user['full_name'],
            'is_active' => (bool)$user['is_active'],
        ],
    ]);
}

if ($method === 'GET' && $sub === 'me') {
    $user = require_auth();
    json_success(['user' => [
        'id'        => (int)$user['id'],
        'username'  => $user['username'],
        'role'      => $user['role'],
        'full_name' => $user['full_name'],
        'is_active' => (bool)$user['is_active'],
        'created_at'=> $user['created_at'],
    ]]);
}

json_error('Not found', 404);
