# Mac Pal

Control your Mac from your iPhone over local WiFi. Launch apps, lock/unlock the screen, and connect via Remote Desktop — all from a native iOS app.

---

## How it works

```
iPhone App  ──── HTTP (local WiFi) ────▶  Mac Server (Node.js)  ──▶  macOS
```

The project has two parts:

| Part | Location | Tech |
|---|---|---|
| Mac Server | `mac-launcher-server/` | Node.js + Express |
| iPhone App | `mac_launcher_app/` | Flutter + Riverpod |

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

---

## Requirements

- Mac running macOS 13 or later
- iPhone running iOS 16 or later
- Both devices on the **same WiFi network**
- Node.js 18+ installed on the Mac
- Flutter 3.x installed (for building the app)

---

## Setup

### 1. Start the Mac server

```bash
cd mac-launcher-server
npm install
node index.js
```

You should see:

```
✅ Mac Launcher Server is running
   Port    : 3000
   Network : listening on all interfaces (0.0.0.0)
```

Find your Mac's local IP:

```bash
ipconfig getifaddr en0
# e.g. 192.168.1.42
```

### 2. (Optional) Enable unlock from iPhone

Run this **once** on your Mac to store your login password locally:

```bash
echo 'mac_password=YOUR_PASSWORD' > ~/.mac-launcher.conf
chmod 600 ~/.mac-launcher.conf
```

> The password never leaves your Mac. The iPhone just sends a "please unlock" signal; the Mac reads the password file itself.

### 3. Run the iPhone app

```bash
cd mac_launcher_app
flutter pub get
flutter run
```

On first launch, enter your Mac's IP address and port (`3000`) in the Settings screen, then tap **Test Connection & Continue**.

---

## Server API

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/ping` | Health check — returns `{ status: "ok", machine: "..." }` |
| `GET` | `/apps` | List all installed apps with name and path |
| `POST` | `/open` | Open an app — body: `{ "appName": "Safari" }` |
| `GET` | `/icon?path=...` | Returns a 128×128 PNG icon for a `.app` bundle |
| `POST` | `/lock` | Lock the Mac screen (sends ⌃⌘Q) |
| `POST` | `/unlock` | Unlock using the stored password |
| `GET` | `/lock-status` | Returns `{ "locked": true/false }` |

Test from Terminal:

```bash
curl http://localhost:3000/ping
curl http://localhost:3000/apps
curl -X POST http://localhost:3000/lock
curl "http://localhost:3000/icon?path=/Applications/Safari.app" > safari.png
```

---

## Project structure

```
mac-pal/
├── mac-launcher-server/
│   ├── index.js          # Express server with all endpoints
│   └── package.json
│
└── mac_launcher_app/
    ├── lib/
    │   ├── main.dart
    │   ├── core/
    │   │   ├── dio_client.dart       # Dio HTTP client wired to saved IP/port
    │   │   └── exceptions.dart       # Typed exceptions (MacOffline, AppOpen, UnlockNotConfigured)
    │   └── features/
    │       ├── apps/
    │       │   ├── app_model.dart        # Data class: { name, path }
    │       │   ├── app_tile.dart         # iOS-style icon tile with press animation
    │       │   ├── apps_provider.dart    # Riverpod AsyncNotifier for app list
    │       │   ├── apps_repository.dart  # All HTTP calls to the server
    │       │   └── apps_screen.dart      # Main screen: grid + control bar
    │       └── settings/
    │           ├── settings_provider.dart  # Persists IP/port via SharedPreferences
    │           └── settings_screen.dart    # IP/port input + connection test
    └── pubspec.yaml
```

---

## Remote Desktop

The **Remote Desktop** button in the app opens a sheet with four options:

| Option | Requires |
|---|---|
| Chrome Remote Desktop | Chrome RD set up at [remotedesktop.google.com](https://remotedesktop.google.com/access) |
| Microsoft Remote Desktop | [App Store](https://apps.apple.com/app/microsoft-remote-desktop/id714464092) |
| Jump Desktop | [App Store](https://apps.apple.com/app/jump-desktop-rdp-vnc-fluid/id364876095) |
| VNC Viewer | Screen Sharing enabled on Mac (System Settings → General → Sharing) |

---

## Troubleshooting

**App says "Cannot reach Mac"**
- Make sure `node index.js` is running on the Mac
- Confirm both devices are on the same WiFi
- Double-check the IP in Settings (run `ipconfig getifaddr en0` on Mac)

**Lock button does nothing**
- macOS may require Accessibility permission for `osascript`
- Go to System Settings → Privacy & Security → Accessibility → allow Terminal (or your shell)

**Unlock shows "One-time setup needed"**
- Follow the setup step above to create `~/.mac-launcher.conf`

**Icons not loading**
- Icons are extracted on first request and cached — slow on first load is normal
- Some sandboxed apps may not expose a standard `.icns` file; those show a placeholder

---

## License

MIT
