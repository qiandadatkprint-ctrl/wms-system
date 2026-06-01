@echo off
chcp 65001 >nul
title WMS 仓储管理系统 - 启动
cd /d "%~dp0"
set LOG_FILE=%~dp0startup.log
echo. > "%LOG_FILE%"

echo ================================================
echo   WMS 仓储管理系统 v1.0 - 启动诊断
echo   (日志将写入 startup.log)
echo ================================================
echo.

:: ===== 1. 检查 Node.js =====
echo [1/5] 检查 Node.js...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [FAIL] Node.js 未安装或不在PATH中！
    echo [FAIL] Node.js not found >> "%LOG_FILE%"
    echo 请从 https://nodejs.org/ 安装 Node.js
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('node --version') do echo   Node.js: %%i

:: ===== 2. 尝试启动 MySQL 服务 =====
echo [2/5] 检查 MySQL...
sc query MySQL80 >nul 2>&1
if %errorlevel% equ 0 (
    echo   检测到 MySQL80 服务
    sc query MySQL80 | findstr "RUNNING" >nul
    if %errorlevel% neq 0 (
        echo   正在启动 MySQL80 服务...
        net start MySQL80 >> "%LOG_FILE%" 2>&1
        if %errorlevel% equ 0 (
            echo   MySQL80 已启动
        ) else (
            echo   [WARN] MySQL80 启动失败，请手动启动
        )
    ) else (
        echo   MySQL80 已在运行
    )
) else (
    echo   [WARN] 未检测到 MySQL80 服务
    echo   如果 MySQL 是手动安装的，请确保已启动
)

:: 测试 MySQL 连接
mysql -u root -pwms_root_2024 -e "SELECT 1" >nul 2>&1
if %errorlevel% equ 0 (
    echo   MySQL 连接成功！
) else (
    echo   [WARN] MySQL 连接失败，后端将无法启动
    echo   [WARN] MySQL connect failed >> "%LOG_FILE%"
    echo   检查：1)MySQL服务是否启动 2)root密码是否为 wms_root_2024
)

:: ===== 3. 安装依赖 =====
echo [3/5] 检查依赖...
cd /d "%~dp0wms-server"
if not exist "node_modules\" (
    echo   正在安装后端依赖...
    call npm install --registry=https://registry.npmmirror.com >> "%LOG_FILE%" 2>&1
)
cd /d "%~dp0wms-client"
if not exist "node_modules\" (
    echo   正在安装前端依赖...
    call npm install --registry=https://registry.npmmirror.com >> "%LOG_FILE%" 2>&1
)
echo   依赖就绪

:: ===== 4. 启动后端 =====
echo [4/5] 启动后端 (3000端口)...
cd /d "%~dp0wms-server"
start "WMS-Backend-3000" cmd /k "cd /d %~dp0wms-server && echo 后端编译中... && npx ts-node-dev --respawn --transpile-only src/index.ts 2>&1 && pause"
echo   后端窗口已打开，等待编译...
timeout /t 5 /nobreak >nul

:: ===== 5. 启动前端 =====
echo [5/5] 启动前端 (5173端口)...
cd /d "%~dp0wms-client"
start "WMS-Frontend-5173" cmd /k "cd /d %~dp0wms-client && echo 前端编译中... && npx vite --host 2>&1 && pause"
echo   前端窗口已打开，等待编译...
timeout /t 3 /nobreak >nul

:: ===== 完成 =====
echo.
echo ================================================
echo   启动完成！请查看两个新打开的窗口
echo.
echo   如果窗口显示红色报错，把错误信息发给我
echo ================================================
echo.
echo   前端:    http://localhost:5173
echo   后端API: http://localhost:3000/api/health
echo   账号:    admin / admin123
echo.
echo   重要：
echo   - 后端编译需要 5-15 秒，请等窗口显示
echo     "[WMS Server] 仓储管理系统后端已启动"
echo   - 如果窗口闪退，是启动失败，按 Win+R 输入 cmd
echo     然后 cd /d D:\网页开发\wms-system\wms-server
echo     再执行 npx ts-node-dev --respawn src/index.ts
echo ================================================
pause
