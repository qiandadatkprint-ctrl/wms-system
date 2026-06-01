var fs = require('fs');
var net = require('net');
var mysql = require('mysql2/promise');
var out = [];

function log(msg) { out.push(msg); console.log(msg); }

function save() {
  fs.writeFileSync('D:/网页开发/wms-system/diagnose_result.txt', out.join('\n'), 'utf8');
}

async function main() {
  log('=== WMS 启动诊断 ===');
  log('Node: ' + process.version);
  log('时间: ' + new Date().toLocaleString());
  log('');

  // 1. MySQL 连接测试
  log('[1] MySQL 连接测试...');
  try {
    var conn = await mysql.createConnection({
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: 'wms_root_2024',
      connectTimeout: 5000
    });
    log('  OK - MySQL 连接成功');

    var dbs = await conn.query('SHOW DATABASES');
    var dbNames = dbs[0].map(function(r) { return r.Database; });
    log('  数据库: ' + dbNames.join(', '));

    if (dbNames.indexOf('wms_db') >= 0) {
      var tables = await conn.query('USE wms_db; SHOW TABLES');
      var tableNames = tables[0].map(function(r) { return Object.values(r)[0]; });
      log('  wms_db 共 ' + tableNames.length + ' 张表: ' + tableNames.join(', '));
    } else {
      log('  [WARN] wms_db 不存在!');
    }
    await conn.end();
  } catch (e) {
    log('  [FAIL] MySQL 连接失败: ' + e.message);
  }

  // 2. 端口检查
  log('');
  log('[2] 端口状态...');
  function checkPort(p) {
    return new Promise(function(resolve) {
      var server = net.createServer();
      server.on('error', function() { resolve(false); });
      server.listen(p, 'localhost', function() {
        server.close();
        resolve(true);
      });
    });
  }
  var p3000 = await checkPort(3000);
  var p5173 = await checkPort(5173);
  log('  3000: ' + (p3000 ? '空闲' : '已占用'));
  log('  5173: ' + (p5173 ? '空闲' : '已占用'));

  // 3. 进程检查
  log('');
  log('[3] Node 进程...');
  try {
    var exec = require('child_process').execSync;
    var tasklist = exec('tasklist /FI "IMAGENAME eq node.exe" /FO CSV', {encoding:'utf8', timeout:5000});
    log(tasklist);
  } catch(e) {
    log('  无法获取进程列表');
  }

  log('');
  log('=== 诊断完成 ===');
  save();
}

main().catch(function(e) {
  log('诊断脚本自身错误: ' + e.message + '\n' + e.stack);
  save();
});
