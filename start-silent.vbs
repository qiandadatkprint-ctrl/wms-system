Set WshShell = CreateObject("WScript.Shell")
Set objEnv = WshShell.Environment("PROCESS")
objEnv("PATH") = "C:\Program Files\nodejs;" & objEnv("PATH")

' 启动后端
WshShell.Run "cmd /c cd /d D:\网页开发\wms-system\wms-server && node node_modules\ts-node-dev\lib\bin.js --transpile-only src\index.ts > D:\网页开发\wms-system\backend.log 2>&1", 0, False

' 等待 3 秒
WScript.Sleep 3000

' 启动前端
WshShell.Run "cmd /c cd /d D:\网页开发\wms-system\wms-client && node node_modules\vite\bin\vite.js --host > D:\网页开发\wms-system\frontend.log 2>&1", 0, False
