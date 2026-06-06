# Mac Pal

Control your Mac from your iPhone over local WiFi. Launch apps, lock/unlock the screen, and connect via Remote Desktop — all from a native iOS app.

---

## How it works

```
iPhone App  ──── HTTP (local WiFi) ────▶  Mac Desktop App  ──▶  macOS
                                          (embedded server)
```

The project has three parts:

| Part | Location | Tech | Purpose |
|---|---|---|---|
| Mac Desktop App | `mac_launcher_desktop/` | Flutter + Shelf | Runs the HTTP server on your Mac (replaces Node.js) |
| iPhone App | `mac_launcher_app/` | Flutter + Riverpod | iOS remote control interface |
| Legacy Node Server | `mac-launcher-server/` | Node.js + Express | Original server — still works if you prefer Node |

---

## Screenshots

> App grid with real Mac icons, Mac Control Bar with Lock/Unlock, and Remote Desktop sheet.

---

## Features

- **App launcher** — browse all installed Mac apps with their real icons, tap to open
- **Search** — filter apps instantly by name
- **Lock screen** — lock your Mac remotely with one tap
- **Unlock screen** — unlock using your stored password (never sent over the network)
- **Lock status** — live indicator showing whether your Mac is locked or unlocked
- **Remote Desktop shortcuts** — one-tap links to Chrome Remote Desktop, Microsoft RDP, Jump Desktop, and VNC Viewer
- **OTP pairing** — connect phone to Mac without typing an IP address; Mac generates a 6-digit code, phone scans local network and validates it
- **Auto-discovery** — phone scans the local subnet to find the running Mac server automatically

---

## Requirements

- Mac running macOS 13 or later
- iPhone running iOS 16 or later
- Both devices on the **same WiFi network**
- Flutter 3.x installed (for building both apps)

---

## Quick Start (Recommended — Flutter Desktop)

### 1. Build & run the Mac desktop app

```bash
cd mac_launcher_desktop
flutter pub get
flutter run -d macos
```

The desktop app opens a small window showing your Mac's local IP and the server status. The embedded HTTP server starts automatically on port `3000`.

### 2. Connect the iPhone app via OTP (easiest)

```bash
cd mac_launcher_app
flutter pub get
flutter run
```

On the Settings screen, tap **Connect via OTP**:
1. The phone scans your local network for a running Mac server
2. In the desktop app, tap **Generate OTP** — a 6-digit code appears
3. Enter the code in the phone app — you're connected

### 3. Or connect manually

On the Mac desktop app, note your IP (shown in the window). On the phone Settings screen, enter the IP and port `3000`, then tap **Test Connection & Continue**.

---

## Optional: Enable Unlock from iPhone

Run this **once** on your Mac to store your login password locally:

```bash
echo 'mac_password=YOUR_PASSWORD' > ~/.mac-launcher.conf
chmod 600 ~/.mac-launcher.conf
```

> The password never leaves your Mac. The iPhone just sends a "please unlock" signal; the Mac reads the password file itself.

---

## Alternative: Legacy Node.js Server

If you prefer running the server without the desktop app:

```bash
cd mac-launcher-server
npm install
node index.js
```

Find your Mac's IP and enter it manually in the iPhone app settings.

> The Node server and the Flutter desktop server expose **identical APIs** and are interchangeable.

---

## Server API

Both servers expose the same endpoints:

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/ping` | Health check — returns `{ status: "ok", machine: "..." }` |
| `GET` | `/apps` | List all installed apps with name and path |
| `POST` | `/open` | Open an app — body: `{ "appName": "Safari" }` |
| `GET` | `/icon?path=...` | Returns a 128×128 PNG icon for a `.app` bundle |
| `POST` | `/lock` | Lock the Mac screen (sends ⌃⌘Q) |
| `POST` | `/unlock` | Unlock using the stored password |
| `GET` | `/lock-status` | Returns `{ "locked": true/false }` |
| `POST` | `/validate-otp` | Validate a pairing OTP — body: `{ "otp": "123456" }` |

Test from Terminal:

```bash
curl http://localhost:3000/ping
curl http://localhost:3000/apps
curl -X POST http://localhost:3000/lock
curl "http://localhost:3000/icon?path=/Applications/Safari.app" > safari.png
```

---

## Project Structure

```
mac-pal/
├── README.md
│
├── mac_launcher_desktop/          # Flutter macOS desktop app (recommended server)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── constants.dart         # Port, timeouts
│   │   │   └── network_utils.dart     # Local IP discovery
│   │   ├── providers/
│   │   │   └── server_provider.dart   # Riverpod provider for server state
│   │   ├── screens/
│   │   │   └── home_screen.dart       # Desktop UI: status, IP, OTP button
│   │   └── server/
│   │       ├── embedded_server.dart   # Shelf HTTP server with all routes
│   │       ├── mac_service.dart       # macOS system calls (sips, osascript, ioreg)
│   │       ├── otp_service.dart       # OTP generation and validation
│   │       └── discovery_service.dart # UDP broadcast for auto-discovery
│   ├── macos/Runner/
│   │   ├── DebugProfile.entitlements  # Sandbox disabled (required for sips/osascript)
│   │   └── Release.entitlements
│   └── pubspec.yaml
│
├── mac_launcher_app/              # Flutter iOS app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── dio_client.dart        # Dio HTTP client wired to saved IP/port
│   │   │   └── exceptions.dart        # Typed exceptions (MacOffline, AppOpen, UnlockNotConfigured)
│   │   └── features/
│   │       ├── apps/
│   │       │   ├── app_model.dart         # Data class: { name, path }
│   │       │   ├── app_tile.dart          # iOS-style icon tile with press animation
│   │       │   ├── apps_provider.dart     # Riverpod AsyncNotifier for app list
│   │       │   ├── apps_repository.dart   # All HTTP calls to the server
│   │       │   └── apps_screen.dart       # Main screen: grid + control bar
│   │       └── settings/
│   │           ├── otp_discovery_service.dart  # Scans subnet for Mac server + OTP validation
│   │           ├── settings_provider.dart      # Persists IP/port via SharedPreferences
│   │           └── settings_screen.dart        # OTP connect sheet + manual IP entry
│   └── pubspec.yaml
│
└── mac-launcher-server/           # Legacy Node.js server (optional)
    ├── index.js                   # Express server with all endpoints
    └── package.json
```

---

## Remote Desktop

The **Remote Desktop** button opens a sheet with four options:

| Option | Requires |
|---|---|
| Chrome Remote Desktop | Chrome RD set up at [remotedesktop.google.com](https://remotedesktop.google.com/access) |
| Microsoft Remote Desktop | [App Store](https://apps.apple.com/app/microsoft-remote-desktop/id714464092) |
| Jump Desktop | [App Store](https://apps.apple.com/app/jump-desktop-rdp-vnc-fluid/id364876095) |
| VNC Viewer | Screen Sharing enabled on Mac (System Settings → General → Sharing) |

---

## Troubleshooting

**App says "Cannot reach Mac"**
- Make sure the Mac desktop app is running and shows a green status
- Confirm both devices are on the same WiFi
- Double-check the IP in Settings (run `ipconfig getifaddr en0` on Mac)

**OTP scan finds nothing**
- Ensure both devices are on the same WiFi network
- Make sure the Mac desktop app server is started (green dot)
- Try the manual IP entry as a fallback

**Icons not loading**
- Icons are extracted via `sips` on first request and cached — first load may be slow
- Some sandboxed apps may not expose a standard `.icns` file; those show a placeholder

**Lock/Unlock does nothing**
- macOS may require Accessibility permission for AppleScript
- Go to System Settings → Privacy & Security → Accessibility → allow the desktop app

**Unlock shows "One-time setup needed"**
- Follow the optional setup step above to create `~/.mac-launcher.conf`

---

## License

MIT
