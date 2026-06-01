// 启动诊断脚本 - 检查各组件是否正常
import mysql from 'mysql2/promise';

async function diagnose() {
  console.log('=== WMS 启动诊断 ===');
  console.log('Node version:', process.version);

  // 1. 测试 MySQL 连接
  console.log('\n[1] 测试 MySQL 连接...');
  try {
    const conn = await mysql.createConnection({
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: 'wms_root_2024',
    });
    console.log('   MySQL 连接成功');

    const [dbs] = await conn.execute('SHOW DATABASES');
    const dbNames = (dbs as any[]).map((r: any) => r.Database);
    console.log('   已有数据库:', dbNames.join(', '));

    if (dbNames.includes('wms_db')) {
      const [tables] = await conn.execute('USE wms_db; SHOW TABLES');
      const tableNames = (tables as any[]).map((r: any) => Object.values(r)[0]);
      console.log('   wms_db 表:', tableNames.join(', '));
      console.log('   共 ' + tableNames.length + ' 张表');
    } else {
      console.log('   [WARN] wms_db 数据库不存在！请执行 init.sql');
    }

    await conn.end();
  } catch (err: any) {
    console.log('   [FAIL] MySQL 连接失败:', err.message);
    console.log('   请检查：');
    console.log('   1. MySQL 服务是否启动 (Win+R → services.msc → 找 MySQL80)');
    console.log('   2. root 密码是否为 wms_root_2024');
    console.log('   3. 端口 3306 是否被占用');
  }

  // 2. 测试端口
  console.log('\n[2] 端口可用性...');
  const net = require('net');
  function checkPort(port: number): Promise<boolean> {
    return new Promise(resolve => {
      const server = net.createServer();
      server.listen(port, 'localhost', () => {
        server.close();
        resolve(true);
      });
      server.on('error', () => resolve(false));
    });
  }
  const p3000 = await checkPort(3000);
  const p5173 = await checkPort(5173);
  console.log('   3000 端口:', p3000 ? '空闲' : '已占用');
  console.log('   5173 端口:', p5173 ? '空闲' : '已占用');

  console.log('\n=== 诊断完成 ===');
}

diagnose().catch(console.error);
