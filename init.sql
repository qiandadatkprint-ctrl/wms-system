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

-- 用户账号（密码均为 admin123 的 bcrypt hash）
INSERT INTO users (username, password_hash, real_name, role_type) VALUES
('admin', '$2a$10$Ygo9Stnc2JII8rB37wx5MOFYJm2UaRY8TxqhrX1Vk/seZY7uOcBEG', '系统管理员', 'admin'),
('zhangsan', '$2a$10$Ygo9Stnc2JII8rB37wx5MOFYJm2UaRY8TxqhrX1Vk/seZY7uOcBEG', '张三', 'manager'),
('lisi', '$2a$10$Ygo9Stnc2JII8rB37wx5MOFYJm2UaRY8TxqhrX1Vk/seZY7uOcBEG', '李四', 'operator'),
('wangwu', '$2a$10$Ygo9Stnc2JII8rB37wx5MOFYJm2UaRY8TxqhrX1Vk/seZY7uOcBEG', '王五', 'operator');

-- 仓库
INSERT INTO warehouses (name, code, address) VALUES
('主仓库', 'WH-001', '厂区A栋1层'),
('原材料仓', 'WH-002', '厂区B栋');

-- 库区
INSERT INTO areas (warehouse_id, name, type) VALUES
(1, 'A区-成品存储区', 'storage'), (1, 'B区-拣货作业区', 'picking'),
(1, 'C区-退货处理区', 'return'), (1, 'D区-待检暂存区', 'staging'),
(2, 'E区-原料存储区', 'storage'), (2, 'F区-辅料区', 'storage');

-- 库位
INSERT INTO locations (area_id, code, capacity) VALUES
(1, 'A-01-01', 500), (1, 'A-01-02', 500), (1, 'A-01-03', 500), (1, 'A-02-01', 300), (1, 'A-02-02', 300),
(2, 'B-01-01', 300), (2, 'B-01-02', 300), (2, 'B-01-03', 300),
(3, 'C-01-01', 200), (3, 'C-01-02', 200),
(4, 'D-01-01', 100), (4, 'D-01-02', 100),
(5, 'E-01-01', 800), (5, 'E-01-02', 800), (5, 'E-02-01', 600),
(6, 'F-01-01', 400), (6, 'F-01-02', 400);

-- 示例物料（覆盖多个分类）
INSERT INTO products (code, name, barcode, category, spec, unit, safety_stock, max_stock, retail_price) VALUES
('RM-001', '高强度钢板', '6901234560001', '原材料', '3.0mm×1500mm×6000mm', '吨', 5, 50, 4200.00),
('RM-002', '不锈钢管304', '6901234560002', '原材料', 'Φ50×3mm×6m', '根', 100, 2000, 85.00),
('RM-003', '工业轴承6205', '6901234560003', '原材料', '6205-2RS', '个', 200, 5000, 12.50),
('RM-004', '密封圈O型', '6901234560004', '原材料', 'Φ30×3.5mm 丁腈', '个', 500, 10000, 0.80),
('SF-001', '电机定子组件', '6901234560005', '半成品', 'Y2-132M-4 7.5kW', '台', 20, 200, 380.00),
('SF-002', 'PCB控制板V2', '6901234560006', '半成品', 'STM32主控 4层板', '块', 50, 500, 65.00),
('FP-001', '工业减速电机', '6901234560007', '成品', 'RV40 速比1:30 0.75kW', '台', 10, 100, 1850.00),
('FP-002', '液压油缸总成', '6901234560008', '成品', 'HSG-80/45×300', '套', 5, 60, 3200.00),
('FP-003', '传送带滚筒', '6901234560009', '成品', 'Φ89×500mm 镀锌', '个', 30, 300, 220.00),
('PK-001', '出口瓦楞纸箱', '6901234560010', '包装材料', '600×400×350mm 五层', '个', 200, 5000, 3.50),
('PK-002', 'EPE珍珠棉', '6901234560011', '包装材料', '2mm×1.2m×50m', '卷', 10, 100, 180.00),
('PK-003', '木托盘', '6901234560012', '包装材料', '1200×1000mm 田字', '个', 50, 500, 85.00),
('OF-001', '办公用A4纸', '6901234560013', '办公用品', '70g 500张/包', '包', 100, 500, 22.00),
('OF-002', '安全手套', '6901234560014', '办公用品', '防割等级5 M码', '双', 50, 500, 15.00),
('RM-005', '铝合金型材', '6901234560015', '原材料', '6063-T5 40×40×2mm', '米', 200, 5000, 28.00);

-- 供应商
INSERT INTO suppliers (code, name, contact_name, phone, address) VALUES
('SUP-001', '宝钢商贸有限公司', '陈经理', '13800001001', '上海市宝山区铁力路88号'),
('SUP-002', '深圳精密轴承厂', '林主管', '13800001002', '深圳市龙华区大浪街道'),
('SUP-003', '科达机电设备公司', '周总', '13800001003', '东莞市长安镇振安路'),
('SUP-004', '鑫源包装材料厂', '郑经理', '13800001004', '广州市番禺区石基镇'),
('SUP-005', '力诚五金配件公司', '吴主管', '13800001005', '苏州市昆山市花桥镇');

-- 客户
INSERT INTO customers (code, name, contact_name, phone, address) VALUES
('CUS-001', '华远重工集团有限公司', '刘总', '13900002001', '武汉市东湖高新区光谷大道'),
('CUS-002', '腾飞自动化设备公司', '黄经理', '13900002002', '杭州市余杭区未来科技城'),
('CUS-003', '鑫达物流设备公司', '孙主管', '13900002003', '成都市高新区天府软件园'),
('CUS-004', '北方机械制造厂', '赵厂长', '13900002004', '沈阳市铁西区北二路'),
('CUS-005', '亚东五金商贸', '钱经理', '13900002005', '南京市江宁区秣陵街道');
