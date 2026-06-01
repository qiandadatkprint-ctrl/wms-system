@echo off
start "Backend" /min cmd /k "cd /d D:\wms-system\wms-server && npx ts-node-dev --transpile-only src/index.ts"
timeout /t 5 /nobreak >nul
start "Frontend" /min cmd /k "cd /d D:\wms-system\wms-client && npx vite --host"
echo http://localhost:5173
echo admin / admin123
pause
