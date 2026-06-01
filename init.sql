-- ============================================
-- WMS 仓储管理系统 - 数据库初始化脚本
-- 适用：中小型企业单仓管理
-- 数据库：MySQL 8.0+
-- ============================================

CREATE DATABASE IF NOT EXISTS wms_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE wms_db;
SET NAMES utf8mb4;
SET sql_mode = 'NO_ENGINE_SUBSTITUTION';

-- ==================== 基础资料模块 ====================

-- 用户表
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '登录名',
    password_hash VARCHAR(255) NOT NULL COMMENT 'bcrypt密码',
    real_name VARCHAR(50) NOT NULL COMMENT '真实姓名',
    role_type ENUM('admin','manager','operator') NOT NULL DEFAULT 'operator' COMMENT '角色',
    phone VARCHAR(20) DEFAULT '' COMMENT '手机号',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1启用 0禁用',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT '用户表';

-- 仓库表
CREATE TABLE warehouses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '仓库名称',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT '仓库编码',
    address VARCHAR(255) DEFAULT '' COMMENT '地址',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1启用 0禁用',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT '仓库表';

-- 库区表
CREATE TABLE areas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_id INT NOT NULL COMMENT '所属仓库',
    name VARCHAR(50) NOT NULL COMMENT '库区名称',
    type ENUM('storage','picking','return','staging') NOT NULL DEFAULT 'storage' COMMENT '库区类型',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
) COMMENT '库区表';

-- 库位/货架表
CREATE TABLE locations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    area_id INT NOT NULL COMMENT '所属库区',
    code VARCHAR(30) NOT NULL UNIQUE COMMENT '库位编号',
    capacity INT DEFAULT 0 COMMENT '容量上限(0=不限)',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1启用 0禁用',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (area_id) REFERENCES areas(id)
) COMMENT '库位表';

-- 物料/SKU表
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE COMMENT 'SKU编码',
    name VARCHAR(200) NOT NULL COMMENT '品名',
    barcode VARCHAR(100) DEFAULT '' UNIQUE COMMENT '条码',
    category VARCHAR(50) DEFAULT '' COMMENT '分类',
    spec VARCHAR(100) DEFAULT '' COMMENT '规格型号',
    unit VARCHAR(20) NOT NULL DEFAULT '个' COMMENT '单位',
    safety_stock INT DEFAULT 0 COMMENT '安全库存阈值',
    max_stock INT DEFAULT 0 COMMENT '最大库存阈值',
    retail_price DECIMAL(10,2) DEFAULT 0.00 COMMENT '参考单价',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1启用 0禁用',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '物料/SKU表';

-- 供应商表
CREATE TABLE suppliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE COMMENT '供应商编码',
    name VARCHAR(200) NOT NULL COMMENT '供应商名称',
    contact_name VARCHAR(50) DEFAULT '' COMMENT '联系人',
    phone VARCHAR(30) DEFAULT '' COMMENT '联系电话',
    address VARCHAR(255) DEFAULT '' COMMENT '地址',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1启用 0禁用',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT '供应商表';

-- 客户表
CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE COMMENT '客户编码',
    name VARCHAR(200) NOT NULL COMMENT '客户名称',
    contact_name VARCHAR(50) DEFAULT '' COMMENT '联系人',
    phone VARCHAR(30) DEFAULT '' COMMENT '联系电话',
    address VARCHAR(255) DEFAULT '' COMMENT '地址',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1启用 0禁用',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT '客户表';

-- ==================== 核心业务模块 ====================

-- 入库单主表
CREATE TABLE inbound_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(30) NOT NULL UNIQUE COMMENT '入库单号',
    type ENUM('purchase','return','other') NOT NULL DEFAULT 'purchase' COMMENT '入库类型',
    supplier_id INT DEFAULT NULL COMMENT '供应商',
    warehouse_id INT NOT NULL COMMENT '仓库',
    status ENUM('draft','receiving','completed','cancelled') NOT NULL DEFAULT 'draft' COMMENT '状态',
    expected_at DATE DEFAULT NULL COMMENT '预期到达日期',
    operator_id INT DEFAULT NULL COMMENT '操作员',
    remark VARCHAR(500) DEFAULT '' COMMENT '备注',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    FOREIGN KEY (operator_id) REFERENCES users(id)
) COMMENT '入库单主表';

-- 入库单明细表
CREATE TABLE inbound_order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    inbound_order_id INT NOT NULL COMMENT '入库单ID',
    product_id INT NOT NULL COMMENT '物料',
    location_id INT DEFAULT NULL COMMENT '上架库位',
    expected_qty INT NOT NULL DEFAULT 0 COMMENT '预期数量',
    actual_qty INT DEFAULT 0 COMMENT '实收数量',
    batch_no VARCHAR(50) DEFAULT '' COMMENT '批次号',
    production_date DATE DEFAULT NULL COMMENT '生产日期',
    expiry_date DATE DEFAULT NULL COMMENT '效期',
    FOREIGN KEY (inbound_order_id) REFERENCES inbound_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (location_id) REFERENCES locations(id)
) COMMENT '入库单明细表';

-- 出库单主表
CREATE TABLE outbound_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(30) NOT NULL UNIQUE COMMENT '出库单号',
    type ENUM('sale','picking','other') NOT NULL DEFAULT 'sale' COMMENT '出库类型',
    customer_id INT DEFAULT NULL COMMENT '客户',
    warehouse_id INT NOT NULL COMMENT '仓库',
    status ENUM('draft','picking','completed','cancelled') NOT NULL DEFAULT 'draft' COMMENT '状态',
    expected_at DATE DEFAULT NULL COMMENT '预期出库日期',
    operator_id INT DEFAULT NULL COMMENT '操作员',
    remark VARCHAR(500) DEFAULT '' COMMENT '备注',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    FOREIGN KEY (operator_id) REFERENCES users(id)
) COMMENT '出库单主表';

-- 出库单明细表
CREATE TABLE outbound_order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    outbound_order_id INT NOT NULL COMMENT '出库单ID',
    product_id INT NOT NULL COMMENT '物料',
    ordered_qty INT NOT NULL DEFAULT 0 COMMENT '订单数量',
    actual_qty INT DEFAULT 0 COMMENT '实发数量',
    picked_location_id INT DEFAULT NULL COMMENT '拣货库位',
    batch_no VARCHAR(50) DEFAULT '' COMMENT '批次号',
    FOREIGN KEY (outbound_order_id) REFERENCES outbound_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (picked_location_id) REFERENCES locations(id)
) COMMENT '出库单明细表';

-- ==================== 库存核心 ====================

-- 库存快照表（按物料+库位+批次粒度）
CREATE TABLE inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL COMMENT '物料',
    warehouse_id INT NOT NULL COMMENT '仓库',
    location_id INT NOT NULL COMMENT '库位',
    qty INT NOT NULL DEFAULT 0 COMMENT '当前数量',
    batch_no VARCHAR(50) DEFAULT '' COMMENT '批次号',
    production_date DATE DEFAULT NULL COMMENT '生产日期(FIFO排序依据)',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    FOREIGN KEY (location_id) REFERENCES locations(id),
    UNIQUE KEY uk_inventory (product_id, warehouse_id, location_id, batch_no)
) COMMENT '库存快照表';

-- 库存流水表（只增不改不删）
CREATE TABLE inventory_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL COMMENT '物料',
    location_id INT NOT NULL COMMENT '库位',
    type ENUM('in','out','transfer_out','transfer_in','gain','loss') NOT NULL COMMENT '变动类型',
    qty_change INT NOT NULL COMMENT '变动量(入+出-)',
    balance_qty INT NOT NULL COMMENT '变动后结存',
    batch_no VARCHAR(50) DEFAULT '' COMMENT '批次号',
    reference_type VARCHAR(30) DEFAULT '' COMMENT '关联单据类型',
    reference_id INT DEFAULT 0 COMMENT '关联单据ID',
    operator_id INT DEFAULT NULL COMMENT '操作员',
    remark VARCHAR(255) DEFAULT '' COMMENT '备注',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (location_id) REFERENCES locations(id),
    INDEX idx_product (product_id),
    INDEX idx_created (created_at),
    INDEX idx_reference (reference_type, reference_id)
) COMMENT '库存流水表';

-- 移库单
CREATE TABLE transfers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transfer_no VARCHAR(30) NOT NULL UNIQUE COMMENT '移库单号',
    product_id INT NOT NULL COMMENT '物料',
    from_location_id INT NOT NULL COMMENT '源库位',
    to_location_id INT NOT NULL COMMENT '目标库位',
    qty INT NOT NULL COMMENT '数量',
    batch_no VARCHAR(50) DEFAULT '' COMMENT '批次号',
    status ENUM('draft','completed') NOT NULL DEFAULT 'draft' COMMENT '状态',
    operator_id INT DEFAULT NULL COMMENT '操作员',
    remark VARCHAR(255) DEFAULT '' COMMENT '备注',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (from_location_id) REFERENCES locations(id),
    FOREIGN KEY (to_location_id) REFERENCES locations(id)
) COMMENT '移库单';

-- 盘点任务
CREATE TABLE stocktaking_tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_no VARCHAR(30) NOT NULL UNIQUE COMMENT '盘点单号',
    warehouse_id INT NOT NULL COMMENT '仓库',
    type ENUM('full','partial','dynamic') NOT NULL DEFAULT 'partial' COMMENT '盘点类型',
    status ENUM('created','counting','reviewing','completed') NOT NULL DEFAULT 'created',
    operator_id INT DEFAULT NULL COMMENT '盘点员',
    remark VARCHAR(255) DEFAULT '' COMMENT '备注',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
) COMMENT '盘点任务表';

-- 盘点明细
CREATE TABLE stocktaking_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL COMMENT '盘点任务ID',
    product_id INT NOT NULL COMMENT '物料',
    location_id INT NOT NULL COMMENT '库位',
    batch_no VARCHAR(50) DEFAULT '' COMMENT '批次号',
    system_qty INT NOT NULL DEFAULT 0 COMMENT '系统库存',
    actual_qty INT DEFAULT NULL COMMENT '初次盘点数',
    review_qty INT DEFAULT NULL COMMENT '复核数',
    final_qty INT DEFAULT NULL COMMENT '最终确认数',
    diff_qty INT GENERATED ALWAYS AS (COALESCE(final_qty, actual_qty, 0) - system_qty) STORED COMMENT '差异数',
    status ENUM('pending','first_done','reviewed','adjusted') NOT NULL DEFAULT 'pending',
    FOREIGN KEY (task_id) REFERENCES stocktaking_tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (location_id) REFERENCES locations(id)
) COMMENT '盘点明细表';

-- ==================== 系统日志 ====================

-- 操作日志表
CREATE TABLE operation_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT DEFAULT NULL COMMENT '操作人',
    username VARCHAR(50) DEFAULT '' COMMENT '操作人用户名',
    action VARCHAR(50) NOT NULL COMMENT '操作类型',
    target_type VARCHAR(30) DEFAULT '' COMMENT '操作对象类型',
    target_id INT DEFAULT 0 COMMENT '操作对象ID',
    detail TEXT COMMENT '操作详情(JSON)',
    ip VARCHAR(50) DEFAULT '' COMMENT '操作IP',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_action (action),
    INDEX idx_created (created_at)
) COMMENT '操作日志表';

-- ==================== 初始数据 ====================

-- 默认管理员账号: admin / admin123 (bcrypt hash)
INSERT INTO users (username, password_hash, real_name, role_type) VALUES
('admin', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '系统管理员', 'admin'),
('zhangsan', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '张三', 'manager'),
('lisi', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '李四', 'operator');

-- 默认仓库
INSERT INTO warehouses (name, code, address) VALUES
('主仓库', 'WH-001', '厂区1号');

-- 默认库区
INSERT INTO areas (warehouse_id, name, type) VALUES
(1, 'A区-存储区', 'storage'),
(1, 'B区-拣货区', 'picking'),
(1, 'C区-退货区', 'return'),
(1, 'D区-待检区', 'staging');

-- 默认库位（每个库区生成3个库位）
INSERT INTO locations (area_id, code, capacity) VALUES
(1, 'A-01-01', 500), (1, 'A-01-02', 500), (1, 'A-01-03', 500),
(2, 'B-01-01', 300), (2, 'B-01-02', 300), (2, 'B-01-03', 300),
(3, 'C-01-01', 200), (3, 'C-01-02', 200), (3, 'C-01-03', 200),
(4, 'D-01-01', 100), (4, 'D-01-02', 100), (4, 'D-01-03', 100);
