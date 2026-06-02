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

// --- IMPORTS ---
// express  : web server framework — handles HTTP routes easily
// cors     : allows your iPhone (a different origin) to call this server
// fs       : built-in Node module — reads files and folders
// exec     : built-in — runs shell commands (we use "open -a AppName")
// os       : built-in — gives us the Mac's hostname for the ping response

const express = require('express');
const cors    = require('cors');
const fs      = require('fs');
const { exec } = require('child_process');
const os      = require('os');

// --- APP SETUP ---
const app  = express();
const PORT = 3000;

// cors()           → allows requests from any origin (your iPhone on same WiFi)
// express.json()   → lets Express read JSON bodies (needed for POST /open)
app.use(cors());
app.use(express.json());


// ============================================================
// ENDPOINT 1: GET /ping
// ============================================================
// Purpose:
//   Health check. The Flutter app calls this first to confirm
//   it can reach your Mac before trying to load the app list.
//
// Response:
//   { "status": "ok", "machine": "Your-MacBook-Name" }
//
// Test it:
//   curl http://localhost:3000/ping
// ============================================================
app.get('/ping', (req, res) => {
  res.json({
    status: 'ok',
    machine: os.hostname(), // returns your Mac's name e.g. "Somesh-MacBook-Pro"
  });
});


// ============================================================
// ENDPOINT 2: GET /apps
// ============================================================
// Purpose:
//   Reads your Mac's /Applications folder and returns every
//   .app file as a JSON array. Flutter displays this list.
//
// How it works:
//   1. Read all entries in /Applications
//   2. Keep only items ending in ".app"
//   3. Strip the ".app" suffix for a clean display name
//   4. Sort alphabetically
//   5. Send as JSON
//
// Response:
//   {
//     "apps": [
//       { "name": "Safari",  "path": "/Applications/Safari.app" },
//       { "name": "Xcode",   "path": "/Applications/Xcode.app" },
//       ...
//     ]
//   }
//
// Test it:
//   curl http://localhost:3000/apps
// ============================================================
app.get('/apps', (req, res) => {
  try {
    // Read everything inside /Applications (returns an array of file/folder names)
    const entries = fs.readdirSync('/Applications');

    const apps = entries
      .filter(name => name.endsWith('.app'))              // keep only .app bundles
      .map(name => ({
        name: name.replace('.app', ''),                   // "Safari.app" → "Safari"
        path: '/Applications/' + name,                    // full path for reference
      }))
      .sort((a, b) => a.name.localeCompare(b.name));      // A → Z sort

    res.json({ apps });

  } catch (err) {
    // If /Applications can't be read for some reason, return a 500 error
    res.status(500).json({ error: err.message });
  }
});


// ============================================================
// ENDPOINT 3: POST /open
// ============================================================
// Purpose:
//   Opens any app on your Mac. Flutter sends the app name,
//   this server runs "open -a AppName" in the Mac shell.
//
// Request body (JSON):
//   { "appName": "Xcode" }
//
// How it works:
//   The "open -a" command is a built-in macOS CLI tool.
//   It opens any app exactly like double-clicking in Finder.
//   Example: open -a "Final Cut Pro"
//
// Response (success):
//   { "status": "opened", "app": "Xcode" }
//
// Response (failure):
//   { "error": "Could not open Xcode" }
//
// Test it:
//   curl -X POST http://localhost:3000/open \
//        -H "Content-Type: application/json" \
//        -d '{"appName": "Safari"}'
//
// PASS: Safari opens on your Mac after running the above command.
// ============================================================
app.post('/open', (req, res) => {
  const { appName } = req.body;

  // Guard: appName must be present in the request body
  if (!appName) {
    return res.status(400).json({ error: 'appName is required' });
  }

  // Build and run the shell command
  // The quotes around ${appName} handle apps with spaces (e.g. "Final Cut Pro")
  exec(`open -a "${appName}"`, (err) => {
    if (err) {
      // App not found, blocked by permissions, or other OS error
      return res.status(500).json({ error: 'Could not open ' + appName });
    }
    res.json({ status: 'opened', app: appName });
  });
});


// ============================================================
// START THE SERVER
// ============================================================
// WHY '0.0.0.0' and NOT 'localhost'?
//
//   'localhost' = only your Mac itself can connect (127.0.0.1)
//   '0.0.0.0'  = accepts connections from ANY device on the network
//
//   Your iPhone is a different device. If you use localhost,
//   the iPhone cannot reach this server even on the same WiFi.
//   Always use 0.0.0.0 for local network servers.
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
  console.log('');
  console.log('⚠️  Find your Mac IP → run: ipconfig getifaddr en0');
  console.log('   Then test from iPhone Safari: http://YOUR_MAC_IP:' + PORT + '/ping');
  console.log('');
});


/Users/Personal/mac-pal/mac-launcher-server/index.js