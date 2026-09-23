const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { URL } = require('url');

const PORT = Number(process.env.PORT || 8787);
const HOST = process.env.HOST || '0.0.0.0';
const PUBLIC_DIR = path.join(__dirname, 'public');
const STALE_MS = Number(process.env.WARZONE_STALE_MS || 15000);
const INGEST_TOKEN = process.env.WARZONE_INGEST_TOKEN || '';
const MAX_INGEST_BYTES = Number(process.env.WARZONE_MAX_INGEST_BYTES || 2 * 1024 * 1024);
const clients = new Set();

function candidateStateFiles() {
  const files = [];
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
  if (process.env.WARZONE_STATE_FILE) return process.env.WARZONE_STATE_FILE;
  const candidates = candidateStateFiles();
  return candidates.find(f => fs.existsSync(f)) || candidates[0];
}

let STATE_FILE = resolveStateFile();

function offlineState(message) {
  return {
    campaign: 'WarZone Caucasus', version: '4.47', status: 'OFFLINE',
    updatedAt: new Date().toISOString(), playersOnline: 0, maxPlayers: 32,
    activeSector: null, sectors: [], connections: [], operations: [], events: [],
    error: message
  };
}

function readState() {
  try {
    if (!process.env.WARZONE_STATE_FILE && !fs.existsSync(STATE_FILE)) STATE_FILE = resolveStateFile();
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
    return offlineState(`State unavailable: ${error.message}`);
  }
}

function commonHeaders() {
  return {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'no-referrer',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=()'
  };
}

function sendJson(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    ...commonHeaders(),
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
  if (!filePath.startsWith(PUBLIC_DIR)) { res.writeHead(403, commonHeaders()); return res.end('Forbidden'); }
  fs.readFile(filePath, (err, data) => {
    if (err) { res.writeHead(404, commonHeaders()); return res.end('Not found'); }
    res.writeHead(200, { ...commonHeaders(), 'Content-Type': contentType(filePath), 'Cache-Control': 'no-cache' });
    res.end(data);
  });
}

function broadcast(state) {
  const frame = `data: ${JSON.stringify(state)}\n\n`;
  for (const res of clients) res.write(frame);
}

function tokenMatches(req) {
  if (!INGEST_TOKEN) return false;
  const auth = req.headers.authorization || '';
  if (!auth.startsWith('Bearer ')) return false;
  const supplied = Buffer.from(auth.slice(7));
  const expected = Buffer.from(INGEST_TOKEN);
  return supplied.length === expected.length && crypto.timingSafeEqual(supplied, expected);
}

function validateTelemetry(payload) {
  return payload && typeof payload === 'object' && !Array.isArray(payload) &&
    typeof payload.campaign === 'string' && Array.isArray(payload.sectors);
}

function writeTelemetry(payload) {
  fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
  const tempFile = `${STATE_FILE}.${process.pid}.tmp`;
  fs.writeFileSync(tempFile, JSON.stringify(payload), 'utf8');
  fs.renameSync(tempFile, STATE_FILE);
}

function receiveTelemetry(req, res) {
  if (!INGEST_TOKEN) return sendJson(res, 404, { error: 'Not found' });
  if (!tokenMatches(req)) return sendJson(res, 401, { error: 'Unauthorized' });

  let size = 0;
  const chunks = [];
  req.on('data', chunk => {
    size += chunk.length;
    if (size > MAX_INGEST_BYTES) {
      res.writeHead(413, commonHeaders());
      res.end('Payload too large');
      req.destroy();
      return;
    }
    chunks.push(chunk);
  });
  req.on('end', () => {
    if (res.writableEnded) return;
    try {
      const payload = JSON.parse(Buffer.concat(chunks).toString('utf8'));
      if (!validateTelemetry(payload)) return sendJson(res, 400, { error: 'Invalid telemetry payload' });
      writeTelemetry(payload);
      const state = readState();
      broadcast(state);
      return sendJson(res, 202, { ok: true, receivedAt: new Date().toISOString() });
    } catch (error) {
      return sendJson(res, 400, { error: `Invalid telemetry: ${error.message}` });
    }
  });
}

let lastMtime = 0;
setInterval(() => {
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
  if (url.pathname === '/api/telemetry' && req.method === 'POST') return receiveTelemetry(req, res);
  if (url.pathname === '/api/state' && req.method === 'GET') return sendJson(res, 200, readState());
  if (url.pathname === '/api/health' && req.method === 'GET') {
    const state = readState();
    const health = {
      ok: true,
      service: 'warzone-command-center',
      telemetry: state.status || 'UNKNOWN',
      telemetryAgeMs: Number.isFinite(state.telemetryAgeMs) ? state.telemetryAgeMs : null,
      ingestEnabled: Boolean(INGEST_TOKEN),
      time: new Date().toISOString()
    };
    if (process.env.WARZONE_HEALTH_DETAILS === '1') health.stateFile = STATE_FILE;
    return sendJson(res, 200, health);
  }
  if (url.pathname === '/events' && req.method === 'GET') {
    res.writeHead(200, {
      ...commonHeaders(),
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    });
    res.write(`data: ${JSON.stringify(readState())}\n\n`);
    clients.add(res);
    req.on('close', () => clients.delete(res));
    return;
  }
  if (req.method !== 'GET' && req.method !== 'HEAD') return sendJson(res, 405, { error: 'Method not allowed' });
  serveStatic(res, url.pathname);
});

server.listen(PORT, HOST, () => {
  console.log(`WarZone Command Center listening on http://${HOST}:${PORT}`);
  console.log(`Reading state from ${STATE_FILE}`);
  console.log(`Remote telemetry ingest ${INGEST_TOKEN ? 'enabled' : 'disabled'}`);
});
