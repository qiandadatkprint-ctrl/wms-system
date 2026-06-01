USE test;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    real_name VARCHAR(50) NOT NULL,
    role_type VARCHAR(20) NOT NULL DEFAULT 'operator',
    phone VARCHAR(20) DEFAULT '',
    status TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 仓库表
CREATE TABLE IF NOT EXISTS warehouses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    address VARCHAR(255) DEFAULT '',
    status TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 库区表
CREATE TABLE IF NOT EXISTS areas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_id INT NOT NULL,
    name VARCHAR(50) NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'storage',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 库位表
CREATE TABLE IF NOT EXISTS locations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    area_id INT NOT NULL,
    code VARCHAR(30) NOT NULL UNIQUE,
    capacity INT DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 物料/SKU表
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    barcode VARCHAR(100) DEFAULT '' UNIQUE,
    category VARCHAR(50) DEFAULT '',
    spec VARCHAR(100) DEFAULT '',
    unit VARCHAR(20) NOT NULL DEFAULT 'pc',
    safety_stock INT DEFAULT 0,
    max_stock INT DEFAULT 0,
    retail_price DECIMAL(10,2) DEFAULT 0.00,
    status TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 供应商表
CREATE TABLE IF NOT EXISTS suppliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    contact_name VARCHAR(50) DEFAULT '',
    phone VARCHAR(30) DEFAULT '',
    address VARCHAR(255) DEFAULT '',
    status TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 客户表
CREATE TABLE IF NOT EXISTS customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    contact_name VARCHAR(50) DEFAULT '',
    phone VARCHAR(30) DEFAULT '',
    address VARCHAR(255) DEFAULT '',
    status TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 入库单
CREATE TABLE IF NOT EXISTS inbound_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(30) NOT NULL UNIQUE,
    type VARCHAR(20) NOT NULL DEFAULT 'purchase',
    supplier_id INT DEFAULT NULL,
    warehouse_id INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    expected_at DATE DEFAULT NULL,
    operator_id INT DEFAULT NULL,
    remark VARCHAR(500) DEFAULT '',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 入库明细
CREATE TABLE IF NOT EXISTS inbound_order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    inbound_order_id INT NOT NULL,
    product_id INT NOT NULL,
    location_id INT DEFAULT NULL,
    expected_qty INT NOT NULL DEFAULT 0,
    actual_qty INT DEFAULT 0,
    batch_no VARCHAR(50) DEFAULT '',
    production_date DATE DEFAULT NULL,
    expiry_date DATE DEFAULT NULL
);

-- 出库单
CREATE TABLE IF NOT EXISTS outbound_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(30) NOT NULL UNIQUE,
    type VARCHAR(20) NOT NULL DEFAULT 'sale',
    customer_id INT DEFAULT NULL,
    warehouse_id INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    expected_at DATE DEFAULT NULL,
    operator_id INT DEFAULT NULL,
    remark VARCHAR(500) DEFAULT '',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 出库明细
CREATE TABLE IF NOT EXISTS outbound_order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    outbound_order_id INT NOT NULL,
    product_id INT NOT NULL,
    ordered_qty INT NOT NULL DEFAULT 0,
    actual_qty INT DEFAULT 0,
    picked_location_id INT DEFAULT NULL,
    batch_no VARCHAR(50) DEFAULT ''
);

-- 库存快照
CREATE TABLE IF NOT EXISTS inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    location_id INT NOT NULL,
    qty INT NOT NULL DEFAULT 0,
    batch_no VARCHAR(50) DEFAULT '',
    production_date DATE DEFAULT NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_inventory (product_id, warehouse_id, location_id, batch_no(50))
);

-- 库存流水
CREATE TABLE IF NOT EXISTS inventory_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    location_id INT NOT NULL,
    type VARCHAR(20) NOT NULL,
    qty_change INT NOT NULL,
    balance_qty INT NOT NULL,
    batch_no VARCHAR(50) DEFAULT '',
    reference_type VARCHAR(30) DEFAULT '',
    reference_id INT DEFAULT 0,
    operator_id INT DEFAULT NULL,
    remark VARCHAR(255) DEFAULT '',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 移库单
CREATE TABLE IF NOT EXISTS transfers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transfer_no VARCHAR(30) NOT NULL UNIQUE,
    product_id INT NOT NULL,
    from_location_id INT NOT NULL,
    to_location_id INT NOT NULL,
    qty INT NOT NULL,
    batch_no VARCHAR(50) DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    operator_id INT DEFAULT NULL,
    remark VARCHAR(255) DEFAULT '',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 盘点任务
CREATE TABLE IF NOT EXISTS stocktaking_tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_no VARCHAR(30) NOT NULL UNIQUE,
    warehouse_id INT NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'partial',
    status VARCHAR(20) NOT NULL DEFAULT 'created',
    operator_id INT DEFAULT NULL,
    remark VARCHAR(255) DEFAULT '',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 盘点明细
CREATE TABLE IF NOT EXISTS stocktaking_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    product_id INT NOT NULL,
    location_id INT NOT NULL,
    batch_no VARCHAR(50) DEFAULT '',
    system_qty INT NOT NULL DEFAULT 0,
    actual_qty INT DEFAULT NULL,
    review_qty INT DEFAULT NULL,
    final_qty INT DEFAULT NULL,
    diff_qty INT DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
);

-- 操作日志
CREATE TABLE IF NOT EXISTS operation_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT DEFAULT NULL,
    username VARCHAR(50) DEFAULT '',
    action VARCHAR(50) NOT NULL,
    target_type VARCHAR(30) DEFAULT '',
    target_id INT DEFAULT 0,
    detail TEXT,
    ip VARCHAR(50) DEFAULT '',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 初始数据
INSERT IGNORE INTO users (username, password_hash, real_name, role_type) VALUES
('admin', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Admin', 'admin'),
('zhangsan', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Zhang San', 'manager'),
('lisi', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Li Si', 'operator');

INSERT IGNORE INTO warehouses (name, code, address) VALUES ('Main', 'WH-001', 'Factory Area 1');

INSERT IGNORE INTO areas (warehouse_id, name, type) VALUES
(1, 'A-Storage', 'storage'), (1, 'B-Picking', 'picking'),
(1, 'C-Return', 'return'), (1, 'D-Staging', 'staging');

INSERT IGNORE INTO locations (area_id, code, capacity) VALUES
(1, 'A-01-01', 500), (1, 'A-01-02', 500), (1, 'A-01-03', 500),
(2, 'B-01-01', 300), (2, 'B-01-02', 300), (2, 'B-01-03', 300),
(3, 'C-01-01', 200), (3, 'C-01-02', 200), (3, 'C-01-03', 200),
(4, 'D-01-01', 100), (4, 'D-01-02', 100), (4, 'D-01-03', 100);
