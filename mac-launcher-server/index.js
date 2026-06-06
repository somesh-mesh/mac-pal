// ============================================================
// MAC LAUNCHER SERVER
// ============================================================
// What this file does:
//   This is a tiny HTTP server that runs on your Mac.
//   Your iPhone Flutter app sends requests to this server.
//   The server reads your /Applications folder and can open
//   any app on your Mac using the built-in "open -a" command.
//
// How it works:
//   iPhone  ──HTTP──▶  This Server (port 3000)  ──▶  Mac opens app
//
// Run it:
//   node index.js
// ============================================================

const express            = require('express');
const cors               = require('cors');
const fs                 = require('fs');
const path               = require('path');
const { exec, execSync, execFile } = require('child_process');
const os                 = require('os');

const app  = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());


// ============================================================
// ENDPOINT 1: GET /ping
// ============================================================
app.get('/ping', (req, res) => {
  res.json({ status: 'ok', machine: os.hostname() });
});


// ============================================================
// ENDPOINT 2: GET /apps
// ============================================================
// Scans /Applications, /Applications/Utilities, and ~/Applications
// so apps in subfolders are included too.
//
// Response:
//   { "apps": [{ "name": "Safari", "path": "/Applications/Safari.app" }, ...] }
// ============================================================
app.get('/apps', (req, res) => {
  const searchDirs = [
    '/Applications',
    '/Applications/Utilities',
    '/System/Applications',
    '/System/Applications/Utilities',
    `${os.homedir()}/Applications`,
  ];

  const apps = [];
  const seen = new Set();

  for (const dir of searchDirs) {
    try {
      for (const name of fs.readdirSync(dir)) {
        if (!name.endsWith('.app') || seen.has(name)) continue;
        seen.add(name);
        apps.push({ name: name.replace('.app', ''), path: `${dir}/${name}` });
      }
    } catch (_) {}
  }

  apps.sort((a, b) => a.name.localeCompare(b.name));
  res.json({ apps });
});


// ============================================================
// ENDPOINT 3: POST /open
// ============================================================
app.post('/open', (req, res) => {
  const { appName } = req.body;
  if (!appName) return res.status(400).json({ error: 'appName is required' });

  exec(`open -a "${appName}"`, (err) => {
    if (err) return res.status(500).json({ error: 'Could not open ' + appName });
    res.json({ status: 'opened', app: appName });
  });
});


// ============================================================
// ENDPOINT 4: GET /icon?path=/Applications/Safari.app
// ============================================================
// Returns a 128×128 PNG icon for the given .app bundle.
// Extracted from the bundle's .icns file using sips (built into macOS).
// Results are cached in memory after the first extraction.
//
// Test it:
//   curl "http://localhost:3000/icon?path=/Applications/Safari.app" > icon.png
// ============================================================
const iconCache = new Map(); // appPath → Buffer

function findIconFile(appPath) {
  // Try the icon declared in Info.plist first
  const plistPath = path.join(appPath, 'Contents', 'Info.plist');
  try {
    const raw = execSync(
      `/usr/libexec/PlistBuddy -c "Print CFBundleIconFile" "${plistPath}"`,
      { stdio: ['pipe', 'pipe', 'pipe'] }
    ).toString().trim();
    const iconFile = raw.endsWith('.icns') ? raw : `${raw}.icns`;
    const full = path.join(appPath, 'Contents', 'Resources', iconFile);
    if (fs.existsSync(full)) return full;
  } catch (_) {}

  // Fallback: first .icns file found in Resources/
  try {
    const resourcesDir = path.join(appPath, 'Contents', 'Resources');
    const icns = fs.readdirSync(resourcesDir).find(f => f.endsWith('.icns'));
    if (icns) return path.join(resourcesDir, icns);
  } catch (_) {}

  return null;
}

app.get('/icon', (req, res) => {
  const { path: appPath } = req.query;
  if (!appPath) return res.status(400).json({ error: 'path query param required' });

  if (iconCache.has(appPath)) {
    res.set('Content-Type', 'image/png');
    res.set('Cache-Control', 'public, max-age=3600');
    return res.send(iconCache.get(appPath));
  }

  const iconSrc = findIconFile(appPath);
  if (!iconSrc) return res.status(404).json({ error: 'icon not found' });

  const tmpFile = `/tmp/ml_icon_${Date.now()}.png`;
  try {
    execSync(`sips -s format png "${iconSrc}" --out "${tmpFile}"`, { stdio: 'pipe' });
    execSync(`sips --resampleHeightWidth 128 128 "${tmpFile}"`, { stdio: 'pipe' });
    const buf = fs.readFileSync(tmpFile);
    try { fs.unlinkSync(tmpFile); } catch (_) {}
    iconCache.set(appPath, buf);
    res.set('Content-Type', 'image/png');
    res.set('Cache-Control', 'public, max-age=3600');
    res.send(buf);
  } catch (e) {
    try { fs.unlinkSync(tmpFile); } catch (_) {}
    res.status(500).json({ error: 'icon conversion failed' });
  }
});


// ============================================================
// LOCK / UNLOCK
// ============================================================
// Password setup (run once on your Mac):
//   echo 'mac_password=YOUR_PASSWORD' > ~/.mac-launcher.conf
//   chmod 600 ~/.mac-launcher.conf
//
// The password is NEVER sent over the network — it lives only
// on your Mac. The phone just sends "please unlock".
// ============================================================

const MAC_CONF = path.join(os.homedir(), '.mac-launcher.conf');

function readStoredPassword() {
  try {
    const text  = fs.readFileSync(MAC_CONF, 'utf8');
    const match = text.match(/^mac_password=(.+)$/m);
    return match ? match[1].trim() : null;
  } catch (_) {
    return null;
  }
}

// POST /lock — sends ⌃⌘Q (Lock Screen shortcut, works on all modern macOS)
app.post('/lock', (req, res) => {
  const script = 'tell application "System Events" to keystroke "q" using {control down, command down}';
  execFile('osascript', ['-e', script], (err) => {
    if (err) return res.status(500).json({ error: 'Lock failed: ' + err.message });
    res.json({ status: 'locked' });
  });
});

// POST /unlock — wakes the display and types the stored password
app.post('/unlock', (req, res) => {
  const password = readStoredPassword();
  if (!password) {
    return res.status(503).json({
      error: 'Password not configured',
      setup: `echo 'mac_password=YOUR_PASSWORD' > ${MAC_CONF} && chmod 600 ${MAC_CONF}`,
    });
  }

  // Escape chars that would break an AppleScript string literal
  const safe = password.replace(/\\/g, '\\\\').replace(/"/g, '\\"');

  const script = [
    'tell application "System Events"',
    '  key code 56',         // Left Shift — wakes display without typing anything
    '  delay 0.8',           // wait for lock screen to appear
    `  keystroke "${safe}"`, // type the password
    '  key code 36',         // press Return
    'end tell',
  ].join('\n');

  execFile('osascript', ['-e', script], (err) => {
    if (err) return res.status(500).json({ error: 'Unlock failed: ' + err.message });
    res.json({ status: 'unlocked' });
  });
});

// GET /lock-status — returns whether the screen is currently locked
app.get('/lock-status', (req, res) => {
  try {
    const out    = execSync('ioreg -n IOHIDSystem', { stdio: ['pipe', 'pipe', 'pipe'], timeout: 3000 }).toString();
    const locked = out.includes('CGSSessionScreenIsLocked = 1');
    res.json({ locked });
  } catch (_) {
    res.json({ locked: false });
  }
});


// ============================================================
// START THE SERVER
// ============================================================
app.listen(PORT, '0.0.0.0', () => {
  console.log('');
  console.log('✅ Mac Launcher Server is running');
  console.log('   Port    : ' + PORT);
  console.log('   Network : listening on all interfaces (0.0.0.0)');
  console.log('');
  console.log('📋 Test endpoints:');
  console.log('   curl http://localhost:' + PORT + '/ping');
  console.log('   curl http://localhost:' + PORT + '/apps');
  console.log('   curl "http://localhost:' + PORT + '/icon?path=/Applications/Safari.app" > icon.png');
  console.log('   curl -X POST http://localhost:' + PORT + '/lock');
  console.log('   curl -X POST http://localhost:' + PORT + '/unlock');
  console.log('');
  console.log('🔐 One-time unlock setup:');
  console.log(`   echo 'mac_password=YOUR_PASSWORD' > ${MAC_CONF} && chmod 600 ${MAC_CONF}`);
  const pwdOk = !!readStoredPassword();
  console.log('   Password file: ' + (pwdOk ? '✅ found' : '⚠️  not set up yet'));
  console.log('');
  console.log('⚠️  Find your Mac IP → run: ipconfig getifaddr en0');
  console.log('   Then test from iPhone Safari: http://YOUR_MAC_IP:' + PORT + '/ping');
  console.log('');
});