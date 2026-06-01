const http = require('http');
const fs = require('fs');
const out = [];

function check(url, label) {
  return new Promise(resolve => {
    http.get(url, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        out.push(label + ': OK ' + d);
        resolve();
      });
    }).on('error', e => {
      out.push(label + ': DOWN (' + e.message + ')');
      resolve();
    });
  });
}

(async () => {
  await check('http://localhost:3000/api/health', 'Backend');
  await check('http://localhost:5173', 'Frontend');
  fs.writeFileSync('D:/网页开发/wms-system/check_result.txt', out.join('\n'));
})();
