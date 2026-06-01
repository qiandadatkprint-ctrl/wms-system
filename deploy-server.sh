#!/bin/bash
# ============================================
# WMS 仓储管理系统 - 服务器部署脚本
# 适用：CentOS 7+ / Ubuntu 18+ / Debian 10+
# ============================================

set -e

echo "========================================"
echo "  WMS 仓储管理系统 - 服务器部署"
echo "========================================"

# ----- 配置变量（按需修改）-----
SERVER_PORT=80          # 前端访问端口
API_PORT=3000           # 后端API端口（仅内部）
MYSQL_ROOT_PASSWORD="wms_root_$(date +%s | sha256sum | base64 | head -c 8)"  # 自动生成随机密码
JWT_SECRET="wms_jwt_$(date +%s | sha256sum | base64 | head -c 16)"

echo "[INFO] MySQL Root密码: $MYSQL_ROOT_PASSWORD"
echo "[INFO] 保存以上密码到安全位置！"
echo ""

# ----- 1. 安装 Docker（如未安装）-----
if ! command -v docker &>/dev/null; then
    echo "[1/5] 安装 Docker..."
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker
    systemctl start docker
else
    echo "[1/5] Docker 已安装，跳过"
fi

# 安装 Docker Compose（如未安装）
if ! command -v docker-compose &>/dev/null; then
    echo "[2/5] 安装 Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "[2/5] Docker Compose 已安装，跳过"
fi

# ----- 3. 构建并启动 -----
echo "[3/5] 构建并启动容器..."
docker-compose up -d --build

# ----- 4. 等待服务就绪 -----
echo "[4/5] 等待服务启动..."
sleep 10

# 检查 MySQL
for i in {1..30}; do
    if docker exec wms-mysql mysqladmin ping -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" --silent 2>/dev/null; then
        echo "[OK] MySQL 已就绪"
        break
    fi
    echo "  等待 MySQL 启动... ($i/30)"
    sleep 3
done

# 初始化数据库表结构（如果 init.sql 未自动执行）
echo "[5/5] 确保数据库已初始化..."
docker exec -i wms-mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" wms_db < init.sql 2>/dev/null || echo "  (可能已自动初始化，跳过)"

echo ""
echo "========================================"
echo "  部署完成！"
echo "  访问地址：http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP'):${SERVER_PORT}"
echo "  默认账号：admin / admin123"
echo "  MySQL密码：${MYSQL_ROOT_PASSWORD}"
echo "========================================"
