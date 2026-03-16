CREATE DATABASE IF NOT EXISTS spesho_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE spesho_db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(80) UNIQUE NOT NULL,
    password_hash VARCHAR(256) NOT NULL,
    role ENUM('manager', 'salesperson') NOT NULL DEFAULT 'salesperson',
    full_name VARCHAR(120),
    is_active TINYINT(1) DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) UNIQUE NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    unit VARCHAR(20) NOT NULL DEFAULT 'kg',
    is_active TINYINT(1) DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stock_movements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    quantity_in DECIMAL(12,2) DEFAULT 0,
    quantity_out DECIMAL(12,2) DEFAULT 0,
    unit_price DECIMAL(12,2),
    note VARCHAR(255),
    movement_type ENUM('in','out') NOT NULL,
    created_by INT,
    date DATE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_product (product_id),
    INDEX idx_date (date),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS sales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    quantity DECIMAL(12,2) NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    discount DECIMAL(12,2) DEFAULT 0,
    total DECIMAL(14,2) NOT NULL,
    note VARCHAR(255),
    sold_by INT NOT NULL,
    date DATE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_product (product_id),
    INDEX idx_date (date),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (sold_by) REFERENCES users(id)
);

-- product_id is nullable for combined-cart debts created from a sale checkout
CREATE TABLE IF NOT EXISTS debts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(120) NOT NULL,
    customer_phone VARCHAR(30),
    product_id INT NULL,
    quantity DECIMAL(12,2) NULL,
    unit_price DECIMAL(12,2) NULL,
    total_amount DECIMAL(14,2) NOT NULL,
    amount_paid DECIMAL(14,2) DEFAULT 0,
    note VARCHAR(255),
    date DATE NOT NULL,
    status ENUM('pending','partial','paid') DEFAULT 'pending',
    created_by INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS debt_payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    debt_id INT NOT NULL,
    amount DECIMAL(14,2) NOT NULL,
    note VARCHAR(255),
    payment_date DATE NOT NULL,
    recorded_by INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (debt_id) REFERENCES debts(id),
    FOREIGN KEY (recorded_by) REFERENCES users(id)
);
