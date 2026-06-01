import app from './app';
import dotenv from 'dotenv';
dotenv.config();

const PORT = process.env.PORT || 3000;

app.listen(Number(PORT), '0.0.0.0', () => {
  console.log(`[WMS Server] 仓储管理系统后端已启动 → http://localhost:${PORT}`);
  console.log(`[WMS Server] 健康检查 → http://localhost:${PORT}/api/health`);
});
