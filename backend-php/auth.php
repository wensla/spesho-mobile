<?php
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

function jwt_create(int $user_id): string {
    $payload = [
        'sub' => (string)$user_id,
        'iat' => time(),
        'exp' => time() + JWT_EXPIRY,
    ];
    return JWT::encode($payload, JWT_SECRET, 'HS256');
}

function jwt_decode_token(string $token): ?array {
    try {
        $decoded = JWT::decode($token, new Key(JWT_SECRET, 'HS256'));
        return (array)$decoded;
    } catch (\Exception $e) {
        return null;
    }
}

function get_bearer_token(): ?string {
    $headers = apache_request_headers();
    $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    if (preg_match('/Bearer\s+(.+)/i', $auth, $m)) {
        return $m[1];
    }
    return null;
}

function require_auth(): array {
    $token = get_bearer_token();
    if (!$token) {
        json_error('Missing token', 401);
    }
    $data = jwt_decode_token($token);
    if (!$data) {
        json_error('Invalid or expired token', 401);
    }
    $db = get_db();
    $stmt = $db->prepare('SELECT * FROM users WHERE id = ? AND is_active = 1');
    $stmt->execute([$data['sub']]);
    $user = $stmt->fetch();
    if (!$user) {
        json_error('User not found', 401);
    }
    return $user;
}

function require_manager(): array {
    $user = require_auth();
    if ($user['role'] !== 'manager') {
        json_error('Manager access required', 403);
    }
    return $user;
}
