var http = require('http');
var fs = require('fs');

var results = [];
var done = 0;

function check(url, name) {
  var req = http.get(url, function(res) {
    var body = '';
    res.on('data', function(c) { body += c; });
    res.on('end', function() {
      results.push(name + ': OK - Status ' + res.statusCode);
      if (res.statusCode === 200 && body.length < 200) {
        results.push('  Body: ' + body);
      }
      done++;
      if (done === 2) finish();
    });
  });
  req.on('error', function(e) {
    results.push(name + ': DOWN - ' + e.message);
    done++;
    if (done === 2) finish();
  });
  req.setTimeout(8000, function() {
    results.push(name + ': TIMEOUT');
    req.destroy();
    done++;
    if (done === 2) finish();
  });
}

function finish() {
  fs.writeFileSync('D:/网页开发/wms-system/health_result.txt', results.join('\n'));
  process.exit(0);
}

check('http://localhost:3000/api/health', 'Backend');
check('http://localhost:5173', 'Frontend');
