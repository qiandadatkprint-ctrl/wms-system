## 方案一：Docker Desktop（推荐，一劳永逸）

Docker Desktop 自带了 MySQL 容器，还能为以后部署做准备。

### 步骤

1. **下载 Docker Desktop**
   - 地址: https://www.docker.com/products/docker-desktop/
   - Windows 11 Home 需要 WSL2，安装过程会引导你配置

2. **安装后验证**
   ```bash
   docker --version          # 应该显示 Docker version 2x.x.x
   docker-compose --version   # 应该显示 Docker Compose version v2.x.x
   ```

3. **启动 MySQL**
   ```bash
   cd D:\网页开发\wms-system
   docker-compose up -d mysql
   ```
   这会自动：
   - 拉取 MySQL 8.0 镜像
   - 启动 MySQL 容器（端口 3307）
   - 执行 init.sql 创建所有表
   - 导入默认帐号数据

4. **验证**
   ```bash
   docker exec wms-mysql mysql -u root -pwms_root_2024 -e "USE wms_db; SHOW TABLES;"
   ```
   应该看到 users, products, warehouses 等 13 张表。


## 方案二：直接安装 MySQL 8.0

如果 Docker 不方便，直接装 MySQL。

### 步骤

1. **下载 MySQL Installer**
   - 地址: https://dev.mysql.com/downloads/installer/
   - 选择 `mysql-installer-community-8.0.x.msi`（约 400MB）
   - 不需要注册 Oracle 账号，点击 "No thanks, just start my download"

2. **安装过程**
   - 选择 "Server only" 安装类型
   - 一路 Next
   - **关键步骤**：设置 root 密码为 `wms_root_2024`（与项目配置一致）
   - 端口保持默认 3306

3. **初始化 WMS 数据库**
   ```bash
   mysql -u root -p < D:\网页开发\wms-system\init.sql
   # 输入密码 wms_root_2024
   ```

4. **修改后端连接配置**
   编辑 `wms-server\.env`（如果没有则创建）：
   ```
   DB_HOST=localhost
   DB_PORT=3306
   DB_USER=root
   DB_PASSWORD=wms_root_2024
   DB_NAME=wms_db
   JWT_SECRET=wms_jwt_secret_key_2024
   ```


## 方案三：XAMPP（最轻量）

如果不想装 Docker 也不想装完整 MySQL：

1. 下载 XAMPP: https://www.apachefriends.org/
2. 安装后启动 MySQL 模块
3. 用 phpMyAdmin（http://localhost/phpmyadmin）导入 `init.sql`
4. 修改后端 `.env` 中 DB_PORT 为 3306
