const http = require('http');
const fs = require('fs');
const path = require('path');

const port = Number(process.env.PORT || 8080);
const root = path.join(__dirname, 'build', 'web');

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
};

http
  .createServer((req, res) => {
    const urlPath = decodeURIComponent(req.url.split('?')[0]);
    const requested = path.normalize(path.join(root, urlPath));
    const filePath = requested.startsWith(root) ? requested : root;
    const target = fs.existsSync(filePath) && fs.statSync(filePath).isFile()
      ? filePath
      : path.join(root, 'index.html');

    fs.readFile(target, (error, data) => {
      if (error) {
        res.writeHead(500);
        res.end('Unable to load app.');
        return;
      }

      res.writeHead(200, {
        'Content-Type': types[path.extname(target)] || 'application/octet-stream',
      });
      res.end(data);
    });
  })
  .listen(port, '127.0.0.1', () => {
    console.log(`Goodwill Circle running at http://localhost:${port}`);
  });
