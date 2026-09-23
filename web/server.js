const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const PORT = Number(process.env.PORT || 8787);
const HOST = process.env.HOST || '0.0.0.0';
const PUBLIC_DIR = path.join(__dirname, 'public');
const STALE_MS = Number(process.env.WARZONE_STALE_MS || 15000);
const clients = new Set();

function candidateStateFiles() {
  const files = [];
  if (process.env.WARZONE_STATE_FILE) files.push(process.env.WARZONE_STATE_FILE);
  if (process.platform === 'win32' && process.env.USERPROFILE) {
    const saved = path.join(process.env.USERPROFILE, 'Saved Games');
    for (const dcsDir of ['DCS.openbeta_server', 'DCS.server', 'DCS.openbeta', 'DCS']) {
      files.push(path.join(saved, dcsDir, 'WarZoneWeb', 'WarZoneWebState.json'));
    }
  }
  files.push(path.join(__dirname, 'data', 'state.json'));
  return files;
}

function resolveStateFile() {
  const candidates = candidateStateFiles();
  return candidates.find(f => fs.existsSync(f)) || candidates[0];
}

let STATE_FILE = resolveStateFile();

function readState() {
  try {
    if (!fs.existsSync(STATE_FILE)) STATE_FILE = resolveStateFile();
    const stat = fs.statSync(STATE_FILE);
    const state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    state.telemetryAgeMs = Math.max(0, Date.now() - stat.mtimeMs);
    const isDemo = path.resolve(STATE_FILE) === path.resolve(path.join(__dirname, 'data', 'state.json'));
    if (state.telemetryAgeMs > STALE_MS && !isDemo) {
      state.status = 'OFFLINE';
      state.telemetryStale = true;
    }
    return state;
  } catch (error) {
    return {
      campaign: 'WarZone Caucasus', version: '4.47', status: 'OFFLINE',
      updatedAt: new Date().toISOString(), playersOnline: 0, maxPlayers: 32,
      activeSector: null, sectors: [], connections: [], operations: [], events: [],
      error: `State unavailable: ${error.message}`
    };
  }
}

function sendJson(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
    'Cache-Control': 'no-store'
  });
  res.end(body);
}

function contentType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  return ({
    '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8', '.json': 'application/json; charset=utf-8',
    '.svg': 'image/svg+xml', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg'
  })[ext] || 'application/octet-stream';
}

function serveStatic(res, pathname) {
  const requested = pathname === '/' ? '/index.html' : pathname;
  const safePath = path.normalize(requested).replace(/^([.][.][/\\])+/, '');
  const filePath = path.join(PUBLIC_DIR, safePath);
  if (!filePath.startsWith(PUBLIC_DIR)) { res.writeHead(403); return res.end('Forbidden'); }
  fs.readFile(filePath, (err, data) => {
    if (err) { res.writeHead(404); return res.end('Not found'); }
    res.writeHead(200, { 'Content-Type': contentType(filePath), 'Cache-Control': 'no-cache' });
    res.end(data);
  });
}

function broadcast(state) {
  const frame = `data: ${JSON.stringify(state)}\n\n`;
  for (const res of clients) res.write(frame);
}

let lastMtime = 0;
setInterval(() => {
  if (!fs.existsSync(STATE_FILE)) STATE_FILE = resolveStateFile();
  fs.stat(STATE_FILE, (err, stat) => {
    if (err || stat.mtimeMs === lastMtime) return;
    lastMtime = stat.mtimeMs;
    broadcast(readState());
  });
}, 500);

setInterval(() => {
  for (const res of clients) res.write(': heartbeat\n\n');
}, 10000);

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  if (url.pathname === '/api/state') return sendJson(res, 200, readState());
  if (url.pathname === '/api/health') return sendJson(res, 200, {
    ok: true, service: 'warzone-command-center', stateFile: STATE_FILE,
    time: new Date().toISOString()
  });
  if (url.pathname === '/events') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache',
      'Connection': 'keep-alive', 'Access-Control-Allow-Origin': '*'
    });
    res.write(`data: ${JSON.stringify(readState())}\n\n`);
    clients.add(res);
    req.on('close', () => clients.delete(res));
    return;
  }
  serveStatic(res, url.pathname);
});

server.listen(PORT, HOST, () => {
  console.log(`WarZone Command Center listening on http://${HOST}:${PORT}`);
  console.log(`Reading state from ${STATE_FILE}`);
});
