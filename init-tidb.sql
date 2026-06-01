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

-- ==================== 初始数据 ====================

-- 用户账号（密码均为 admin123 的 bcrypt hash）
INSERT IGNORE INTO users (username, password_hash, real_name, role_type) VALUES
('admin', '$2a$10$Ygo9Stnc2JII8rB37wx5MOFYJm2UaRY8TxqhrX1Vk/seZY7uOcBEG', '系统管理员', 'admin'),
('zhangsan', '$2a$10$Ygo9Stnc2JII8rB37wx5MOFYJm2UaRY8TxqhrX1Vk/seZY7uOcBEG', '张三', 'manager'),
('lisi', '$2a$10$Ygo9Stnc2JII8rB37wx5MOFYJm2UaRY8TxqhrX1Vk/seZY7uOcBEG', '李四', 'operator'),
('wangwu', '$2a$10$Ygo9Stnc2JII8rB37wx5MOFYJm2UaRY8TxqhrX1Vk/seZY7uOcBEG', '王五', 'operator');

-- 仓库
INSERT IGNORE INTO warehouses (name, code, address) VALUES
('主仓库', 'WH-001', '厂区A栋1层'),
('原材料仓', 'WH-002', '厂区B栋');

-- 库区
INSERT IGNORE INTO areas (warehouse_id, name, type) VALUES
(1, 'A区-成品存储区', 'storage'), (1, 'B区-拣货作业区', 'picking'),
(1, 'C区-退货处理区', 'return'), (1, 'D区-待检暂存区', 'staging'),
(2, 'E区-原料存储区', 'storage'), (2, 'F区-辅料区', 'storage');

-- 库位
INSERT IGNORE INTO locations (area_id, code, capacity) VALUES
(1, 'A-01-01', 500), (1, 'A-01-02', 500), (1, 'A-01-03', 500), (1, 'A-02-01', 300), (1, 'A-02-02', 300),
(2, 'B-01-01', 300), (2, 'B-01-02', 300), (2, 'B-01-03', 300),
(3, 'C-01-01', 200), (3, 'C-01-02', 200),
(4, 'D-01-01', 100), (4, 'D-01-02', 100),
(5, 'E-01-01', 800), (5, 'E-01-02', 800), (5, 'E-02-01', 600),
(6, 'F-01-01', 400), (6, 'F-01-02', 400);

-- 示例物料（覆盖多个分类）
INSERT IGNORE INTO products (code, name, barcode, category, spec, unit, safety_stock, max_stock, retail_price) VALUES
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
INSERT IGNORE INTO suppliers (code, name, contact_name, phone, address) VALUES
('SUP-001', '宝钢商贸有限公司', '陈经理', '13800001001', '上海市宝山区铁力路88号'),
('SUP-002', '深圳精密轴承厂', '林主管', '13800001002', '深圳市龙华区大浪街道'),
('SUP-003', '科达机电设备公司', '周总', '13800001003', '东莞市长安镇振安路'),
('SUP-004', '鑫源包装材料厂', '郑经理', '13800001004', '广州市番禺区石基镇'),
('SUP-005', '力诚五金配件公司', '吴主管', '13800001005', '苏州市昆山市花桥镇');

-- 客户
INSERT IGNORE INTO customers (code, name, contact_name, phone, address) VALUES
('CUS-001', '华远重工集团有限公司', '刘总', '13900002001', '武汉市东湖高新区光谷大道'),
('CUS-002', '腾飞自动化设备公司', '黄经理', '13900002002', '杭州市余杭区未来科技城'),
('CUS-003', '鑫达物流设备公司', '孙主管', '13900002003', '成都市高新区天府软件园'),
('CUS-004', '北方机械制造厂', '赵厂长', '13900002004', '沈阳市铁西区北二路'),
('CUS-005', '亚东五金商贸', '钱经理', '13900002005', '南京市江宁区秣陵街道');
