var http = require('http');
var fs = require('fs');
var result = '';

var req = http.get('http://localhost:3000/api/health', function(res) {
  var body = '';
  res.on('data', function(chunk) { body += chunk; });
  res.on('end', function() {
    result = 'Backend: OK - ' + body;
    fs.writeFileSync('D:/网页开发/wms-system/status.txt', result);
  });
});

req.on('error', function(err) {
  result = 'Backend: DOWN - ' + err.message;
  fs.writeFileSync('D:/网页开发/wms-system/status.txt', result);
});

req.setTimeout(8000, function() {
  if (!result) {
    fs.writeFileSync('D:/网页开发/wms-system/status.txt', 'Backend: TIMEOUT');
  }
  req.destroy();
});
