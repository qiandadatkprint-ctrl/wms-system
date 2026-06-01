@echo off
chcp 65001 >nul
title MySQL 8.0 安装脚本
cd /d "%~dp0"

echo ================================================
echo   WMS - MySQL 8.0 安装脚本
echo ================================================
echo.

:: ===== 检查是否已有 MySQL =====
echo [1/4] 检查 MySQL...
mysql --version >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] MySQL 已安装:
    mysql --version
    echo.
    echo   现在初始化 WMS 数据库？
    echo   执行: mysql -u root -p ^< "%~dp0init.sql"
    goto :check_docker
)

sc query MySQL80 >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] MySQL80 服务已存在
    goto :check_docker
)

:: ===== 方式1: 用 Chocolatey 安装 =====
echo.
echo [2/4] 尝试安装 MySQL...
where choco >nul 2>&1
if %errorlevel% equ 0 (
    echo   检测到 Chocolatey，通过 choco 安装...
    choco install mysql -y
    goto :init_db
)

:: ===== 方式2: 用 Winget 安装 =====
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo   通过 winget 安装 MySQL 8.0...
    winget install Oracle.MySQL --accept-source-agreements --accept-package-agreements
    goto :init_db
)

:: ===== 方式3: 下载安装 =====
echo.
echo   [提示] 未检测到包管理器
echo.
echo   请手动下载 MySQL 8.0 安装程序:
echo   https://dev.mysql.com/downloads/installer/
echo.
echo   推荐下载: mysql-installer-community-8.0.x.msi （约 400MB）
echo   安装时记住 root 密码，安装完成后重新运行本脚本
echo.
pause
exit /b 0

:init_db
echo.
echo [3/4] 初始化数据库...
echo   请确保 MySQL 服务已启动
echo   请输入 MySQL root 密码（安装时设置的）:
set /p MYSQL_PWD="  密码: "

mysql -u root -p%MYSQL_PWD% < "%~dp0init.sql" 2>&1
if %errorlevel% equ 0 (
    echo   [OK] WMS 数据库初始化成功！
) else (
    echo   [FAIL] 数据库初始化失败，请检查密码
    pause
    exit /b 1
)

:check_docker
echo.
echo [4/4] 检查 Docker（可选）...
docker --version >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Docker 已安装
) else (
    echo   [提示] Docker 未安装，MySQL 需单独管理
    echo   如需安装 Docker Desktop，请访问:
    echo   https://www.docker.com/products/docker-desktop/
)

echo.
echo ================================================
echo   完成！MySQL 已就绪
echo   前端: http://localhost:5173
echo   后端: http://localhost:3000
echo   账号: admin / admin123
echo ================================================
pause
